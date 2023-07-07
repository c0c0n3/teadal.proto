Teadal cloud whirlwind tour
---------------------------
> Hang tight!

Let's check out the goodies we've installed. The IP address we use
in the URLs below is that of Andy's VM. Replace it with your own.


### Setting the stage

Same as in Teadal cloud bootstrap.


### Argo CD

First off, browse to the Argo CD web app for a bird's eye view of
what the GitOps pipeline has deployed. Istio routes HTTP traffic
to port 80 and path `/argocd` to the Argo CD server inside the mesh.
So the web app is available at

- http://20.4.3.245/argocd/

Log in with the username and password you entered in the Argo CD K8s
secret. K8s resources are grouped into apps and, in turn, apps into
three projects (mesh-infra, plat-infra-services, plat-app-services)
to reflect the layout of the `deployment` dir in the Git repo.


### Istio

Istio got configured with a few useful add-ons, HTTP and TCP routing,
plus some settings to make it easier to intercept and debug raw network
packets. Any service deployed to the default namespace automatically
gets an Istio side car.

```bash
$ kubectl get pod
```

You should see Keycloak, Postgres and HttpBin entries, all having a
pod count of 2: one pod is the service proper, the other's the Istio
sidecar.

To see some mesh action, use `istioctl` to connect Kiali (one of the
installed add-ons) to your browser

```bash
$ istioctl d kiali
```

navigate to the HttpBin workload and then generate some traffic by
hitting the HttpBin GET endpoint many times in a row until you see
the Kiali graph

- http://20.4.3.245/httpbin/get

(This works because the GitOps pipeline defined an HTTP route through
port `80` and path `/httpbin`.)
Have a look at the content of the other tabs in Kiali, especially
the traces to see Jaeger, another installed add-on, at work. Then
take a peek at the various performance dashboards

```bash
$ istioctl d grafana
```

Read more about the add-ons we bundled with Istio over here

- https://github.com/istio/istio/tree/1.18.0/samples/addons

Oh, truth be told, we also have SkyWalking. But that's not deployed
yet because we still have some bugs to squash.


### Storage

Three of the PVs should be bound. One for the Postgres DB, another
for Keycloak's DB and the last one for the Teadal MinIO tenant.

```bash
$ kubectl get pv
$ kubectl get pvc -A
```

Log into the MinIO console. Run

```bash
$ kubectl minio proxy
```

then browse to http://localhost:9090 and enter the JWT token printed
on the terminal. You should see the Teadal tenant the GitOps pipeline
created. Istio routes the tenant's S3 service through port `80` and
path `/minio`. So you should be able to hit the service from your box
like this

```bash
$ curl -v http://20.4.3.245/minio
```

You should get a fat `403` response. Access is denied without valid
creds. How rude.


### Security

Keycloak is at http://20.4.3.245/keycloak, courtesy of Istio routing.
Navigate to the admin console and log in with the username and password
you set in the Keycloak K8s secret.

Speaking of secrets, we've got Reloader to watch for secret changes
and bounce affected pods. So secrets always stay fresh. Have a look
at the K8s logs to see what's going on under the bonnet.


### DBs

At the moment we only have Postgres. Istio routes incoming TCP traffic
from port `5432` to the Postgres server. Here's an easy way to get
into the DB with `psql` from your local machine.

```
$ nix-shell -p postgresql_15
$ psql postgres://postgres:abc123@20.4.3.245
```

Replace `abc123` with the password you entered in the Postgres K8s
secret.
