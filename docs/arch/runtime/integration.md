Integration process
-------------------
> Going live in a Teadal cluster.

Developers follow a typical cloud-native workflow to integrate their
software into a Teadal cluster. As most Teadal functionality is delivered
through cloud (micro)services, developers typically carry out several
steps to make their software available in a Teadal cluster as a cloud
service. First, the software is packaged in container images and these
images published to an online registry. Then Kubernetes resources are
developed with Kustomize and added to the Git repository from which
the cluster is deployed. These Kubernetes resources specify how to
download and run the published images and typically configure service
storage, traffic routing, connections to other services, identity and
access management, GitOps deployment, and possibly other cluster
resources.

Although the actual details of the integration procedure may vary
considerably from service to service, the conceptual workflow is
mostly the same. Hence, to make the integration procedure somewhat
more concrete, we outline how a developer may integrate a fictitious
SFDP named `robertson-farm`. This is a Python REST API which offers
a subset of the vineyard IoT measurements available in the (also
fictitious) `vineyards` FDP.


### Publishing a container image

The `robertson-farm` source code is in a GitLab repository. The
`src` directory within the repository contains the actual Python
code whereas the root directory contains Poetry files declaring how
to assemble the application and specifying library dependencies.
Also in the root directory is the following Docker file.

```dockerfile
FROM python:3.12

RUN pip install poetry
RUN mkdir /src
WORKDIR /src

COPY poetry.lock pyproject.toml /src/
RUN poetry config virtualenvs.create false \
  && poetry install --no-dev --no-interaction --no-ansi

COPY src /src/

ENV PYTHONPATH=$PWD:$PYTHONPATH

EXPOSE 80
ENTRYPOINT ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
```

This Docker file specifies how to package the Python application
into a Docker image. It packages the Python code along with its
library dependencies and specifies how to run the REST API on port
`80`. The `robertson-farm` developer has set up a GitLab pipeline
to create and publish an actual Docker image using the Docker file.
The GitLab pipeline publishes the image to a container registry at
`registry.io/robertson-farm`.


### Creating a cloud service

After publishing an image, the developer goes on to writing Kubernetes
`Service` and `Deployment` resources to specify how to run the REST
API as a cloud service. The `Service` resource makes the REST API
available in the internal cluster network at `robertson-farm:8000`,
whereas the `Deployment` resource creates the actual processes that
run the Docker image after downloading it from `registry.io/robertson-farm`.
Both resources are declared in a YAML file named `base.yaml` whose
content is shown below.

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: robertson-farm
  name: robertson-farm
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: robertson-farm

---

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: robertson-farm
  name: robertson-farm
spec:
  replicas: 1
  selector:
    matchLabels:
      app: robertson-farm
  template:
    metadata:
      labels:
        app: robertson-farm
    spec:
      containers:
      - image: registry.io/robertson-farm
        name: robertson-farm
        ports:
        - containerPort: 80
```


### Including the service in the deployment pipeline

This Kubernetes deployment recipe needs to be included in the Teadal
Kustomize build pipeline. As mentioned earlier, each Teadal cluster
repository is a fork of `teadal.node` and contains a directory in
correspondence of each runtime architecture layer—*products*, *mesh
infrastructure*, etc. In turn, each layer directory contains a directory
for each component which is part of that layer. A component directory
must contain a Kustomize file to assemble all the various resources
which make up that component. Each layer directory has a root Kustomize
file to include all the Kustomize component files found in the layer
subdirectories.

Hence, the developer creates a `robertson-farm` directory in the
Teadal cluster repository under the *products* layer directory to
hold `base.yaml` and the Kustomize file, `kustomization.yaml`, which
includes `base.yaml` in the build pipeline as shown below. Likewise,
the developer lists the `robertson-farm` directory as a resource in
the root Kustomize file in the *products* layer directory.

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- base.yaml
```

The next step is to create an Argo CD application for the service.
This way, Argo CD can manage the service as a separate deployment
unit and monitor the service resources declared in the repository.
Although this step involves writing boilerplate code and it could be
automated, the developer has to do that manually at the moment. The
*mesh infrastructure* layer directory in the Teadal cluster repository
contains an `argocd` subdirectory which holds the Argo CD deployment
declarations. (Argo CD itself is also part of the GitOps deployment
pipeline, which means Argo CD actually deploys itself!) Inside the
`argocd` directory there is a `projects` directory where an Argo CD
project is defined in correspondence of each runtime architecture
layer—*products*, *mesh infrastructure*, etc. In turn, each project
contains an Argo CD application in correspondence of each service
contained in the runtime architecture layer that the Argo CD project
represents.

So the developer is supposed to declare an Argo CD application for
the `robertson-farm` service inside the *products* Argo CD project.
To do that, the developer creates a `robertson-farm` directory with
two YAML files in it: `app.yaml` and `kustomization.yaml`. These two
files instruct Kustomize to generate the Argo CD manifest required
for the `robertson-farm` application. The `app.yaml` specifies the
service name and the directory where its Kubernetes resources are
kept—see *Creating a cloud service*.

```yaml
- op: replace
  path: /metadata/name
  value: robertson-farm
- op: replace
  path: /spec/source/path
  value: deployment/products/robertson-farm
- op: replace
  path: /spec/project
  value: products
```

The `kustomization.yaml` file applies the transformation in `app.yaml`
to a baseline application manifest in order to produce the actual
`robertson-farm` application manifest.

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

patches:
- target:
    kind: Application
    name: app
  path: app.yaml
```

Finally, the developer updates the Kustomization file for the *products*
Argo CD project to list the `robertson-farm` directory among the resources
to assemble in the Kustomize build. As can be seen from the example
YAML files, it is possible to automate the process of creating an
Argo CD application without requiring the developer to actually
write any YAML files. Thus, most likely this process will be automated
in the future.

At this point the developer creates a pull request to merge all the
above files and directories into the Teadal cluster repository main
line. Shortly after the pull request is merged, Argo CD detects the
new deployment declaration and creates Kubernetes resources in the
cluster accordingly. Now the `robertson-farm` service is running
in the cluster but is not accessible to other services within the
cluster or to clients outside the cluster. The next two sections
explain how to grant access to the service as well as how to route
external traffic to the service.


### Securing the service

As explained in the [security architecture][sec], Teadal features
service security with OPA policies. SFDPs need not implement any
authentication and authorization code as Teadal carries out these
security workflows at runtime through message interception. Istio
captures any incoming HTTP request and delegates security decisions
to OPA. OPA runs Teadal security framework code which verifies that
the request originates from an authenticated user and grants access
to the target SFDP only if there exist a policy which allows that
user to perform the given request.

Thus, the `robertson-farm` developer's task is to write a policy.
Although Teadal does not mandate any specific authorisation scheme,
it does offer a built-in Role-Based Access Control (RBAC) framework
which is what the developer decides to leverage in order to simplify
policy writing and reduce implementation effort. The developer would
like to have two roles, product owner and consumer, and grant access
to two SFDP resources:
- `/config`: service configuration a product owner only should be
   able to create, read, update and delete.
- `/data`: service data both the product owner and consumer should
   be able to read.

Teadal users are managed through Keycloak. Two users registered in
Keycloak should get access to the `robertson-farm` SFDP:
`alice@robertson-farm.za` as a product owner and `bob@analytics.eu`
as a product consumer.

Policies are written in Rego. The Teadal RBAC frameworks makes it
easy to translate RBAC specifications into Rego code. In fact, all
the developer needs to do is declare the roles, map each role to
permissions, and finally map each user to their respective roles
as shown below.

```rego
# This code is in `robertson_farm/rbacdb.rego`.
# The Rego package declaration should mach the filesystem path.
package robertson_farm.rbacdb

# Role defs.
product_owner := "product_owner"
product_consumer := "product_consumer"

# Map each role to a list of permission objects.
# Each permission object specifies a set of allowed HTTP methods for
# the Web resources identified by the URLs matching the given regex.
role_to_perms := {
    product_owner: [
        {
            "methods": [ "GET", "PUT", "DELETE" ],
            "url_regex": "^/config$"
        }
    ],
    product_consumer: [
        {
            "methods": [ "GET" ],
            "url_regex": "^/data$"
        }
    ]
}

# Map each user to their roles.
user_to_roles := {
    "alice@robertson-farm.za": [ product_owner, product_consumer ],
    "bob@analytics.eu": [ product_consumer ]
}
```

At the moment all the Rego code is hosted in the Teadal cluster
repository itself inside the *mesh infrastructure* layer directory.
(This will change soon as the next Teadal development iteration should
implement OPA policy bundles.) Specifically, the path of the Rego
code base relative to the *mesh infrastructure* layer directory is
`security/opa/rego/`. Thus, the developer creates a directory to
hold their Rego code, `security/opa/rego/robertson_farm`, and puts
the above `rbacdb.rego` file in there as well as the `service.rego`
file shown below.

```rego
# This code is in `robertson_farm/service.rego`.
# The Rego package declaration should mach the filesystem path.
package robertson_farm.service

# Import the Teadal RBAC library to verify Keycloak credentials
# and enforce the RBAC rules defined in our RBAC DB.
import data.authnz.envopa as envopa
import data.config.oidc as oidc_config
# Import our RBAC DB.
import data.robertson_farm.rbacdb as rbac_db

# Let the library do the heavy lifting for us.
default allow := false
allow = true {
    user := envopa.allow(rbac_db, oidc_config)
}
```

For the policy to have effect, the developers needs to add the above
`allow` rule to the list of rules in the Rego entry module whose code
is in `security/opa/rego/main.rego`. The Rego snippet below shows how
to do that.

```rego
# Add this to the import section:
import data.robertson_farm.service as robertson_farm

# ...other imports and code...

# Add this to the end of the file:
allow {
    robertson_farm.allow
}
```

As mentioned earlier, for this code to be deployed to the Teadal
cluster, the developer has to open a pull request to merge it into
the Teadal cluster repository main line. Shortly after merging, OPA
will evaluate the policy during authorisation decisions.


### Routing external traffic to the service

Typically, SFDPs are consumed by clients external to the Teadal
cluster and this is the case for the `robertson-farm` SFDP too.
The developer decides to route requests by URL path instead of
domain name so to expose the SFDP endpoints at the URLs:
- `https://my-teadal.eu/robertson-farm/config`
- `https://my-teadal.eu/robertson-farm/data`

Teadal, through Istio, has built-in support for this scenario. In
fact, the *mesh infrastructure* layer directory contains an
`istio/routing/http.yaml` which defines an Istio virtual service
to route external HTTP traffic to internal cluster services. All
the developer needs to do is edit this YAML file to add a `match`
stanza for rewriting the above URL paths into `/config` and `/data`
as shown in the YAML snippet below.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: "http-virtual-service"
spec:
  # ...other spec stanzas...
  http:
  # Add this `match` stanza to route external traffic to the SFDP.
  - match:
    - uri:
        prefix: /robertson-farm/
    rewrite:
      uri: /
    route:
    - destination:
        host: robertson-farm.default.svc.cluster.local
        port:
          number: 80
  # ...other routes...
```

As mentioned earlier, for this route to be deployed to the Teadal
cluster, the developer has to open a pull request to merge the updated
YAML file into the Teadal cluster repository main line. Shortly after
merging, Istio will route external requests to the `robertson-farm`
SFDP.




[sec]: ../sec-design/README.md
