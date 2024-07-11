Teadal runtime architecture
---------------------------
> It's showtime!


A Teadal cluster is the hardware and software deployed to run an
instance of a Teadal data lake. Notably, the software includes the
Teadal tools and services that allow multiple Teadal clusters to be
joined in a federation where producers and consumers can share data
in a trustworthy and secure way, according to agreed-upon governance,
privacy and energy-efficiency policies. [**TODO**: cite D2.2, D3.1,
D4.1 and D5.1] These tools and services are part of each Teadal cluster
whereas hardware, data products and corresponding data services (FDP,
SFDP) typically differ from cluster to cluster. A Teadal cluster is
instantiated and then subsequently updated through a GitOps approach
whereby the desired cluster runtime is declared in an online Git
repository and a dedicated GitOps cluster service reconciles the
desired runtime with the actual cluster state.


### Teadal cluster

Each Teadal cluster includes a backbone software stack on which
cluster-specific data services run. This stack implements the data
and service mesh architecture outlined in D2.2. [**TODO**: cite].
The backbone stack also includes the Teadal components (Catalogue,
Advocate, TEE, Pipelines, Policies, etc.) that allow producers and
consumers to share data in a trustworthy and secure way, according
to agreed-upon governance, privacy and energy-efficiency policies.
Above this backbone sit local, cluster-specific data products and
services—i.e., federated data products (FDPs), shared federated data
products (SFDP), etc.

From a conceptual standpoint, it is convenient to think of a Teadal
cluster as comprising several layers of processes and hardware. Layers
are arranged in a hierarchy so that higher layers use the functionality
provided by lower layers but lower layers do not depend in any way on
higher layers. We examine each layer in turn, from the bottom up.

The *hardware layer* is the lowest layer. This is the cluster hardware
(computers, network) on which all the Teadal cluster software runs.
In the case of a public cloud deployment, the hardware would typically
be virtualised whereas physical machines would be provisioned for an
on-premises scenario. In the simplest case, the whole cluster can run
on just one machine, whereas more computation-intensive scenarios
require several machines.

The *mesh infrastructure* layer interfaces with the hardware layer
to provide the service mesh functionality. Kubernetes sits at the
core of this layer, providing cluster orchestration through a set
of processes that manage computational resources (CPU, memory,
storage), allocate them to processes in the upper layers and orchestrate
the deployment and operation of services by means of containers.
Kubernetes interfaces with DirectPV to create a distributed storage
facility out of the disks attached to each node whereas Istio complements
Kubernetes with mesh control and data planes. The control plane manages
a network of proxies, the data plane, which capture and process service
traffic. This allows to augment service functionality at runtime without
requiring any modifications to the services themselves. The Teadal
cluster exploits this to transparently route and balance service
traffic, secure communication and access to service resources (through
Keycloak and OPA), and monitor service operation (through Kiali,
Prometheus and Grafana). Finally, the mesh infrastructure includes
Argo CD, a GitOps continuous delivery tool for Kubernetes, to monitor
the cluster Git repository in order to automatically reconcile the
desired deployment state declared in the repository with the actual
live state of the cluster.

The *core services* layer runs on the *mesh infrastructure* to provide
the Teadal core functionality which enables federated data products.
In this layer, Postgres and MinIO provide database and object storage
functionality, respectively. Workflow services are also included:
Kubeflow for managing machine learning operations and Airflow for
engineering data pipelines. Last but not least, the core services
layer hosts the Teadal tools and services that allow multiple Teadal
clusters to be joined in a federation where producers and consumers
can share data in a trustworthy and secure way, according to agreed-upon
governance, privacy and energy-efficiency policies. Catalogue, Advocate,
TEE, Pipelines, and Policies (security, gravity and friction) are all
examples of Teadal services and tools in the core services layer.

Finally, *products* is the top layer, hosting cluster-specific data
products and services—i.e., federated data products (FDPs), shared
federated data products (SFDP), etc. As detailed in D3.1 [**TODO**:
cite], a federated data product (FDP) extends the notion of data mesh
product to cater for sharing data in a data lake federation according
to the governance rules of that federation. A shared federated data
product (SFDP) encapsulates a consumer-producer agreement (contract)
about sharing a part of an FDP and provides the means for the consumer
to process the shared data only within the bounds of the agreed-upon
contract. The diagram below summarises the discussion so far by
presenting the cluster runtime arranged in the four layers just
defined.

![Cluster runtime stack.][dia.tech-stack]


### Deployment

A Teadal cluster is instantiated and then subsequently updated through
a GitOps approach whereby the desired cluster runtime is declared in
an online Git repository and a dedicated GitOps cluster service reconciles
the desired runtime with the actual cluster state. Thus, there is a
Git repository associated with every Teadal cluster and, as briefly
mentioned earlier, there is an Argo CD service in that cluster which
monitors the Git repository in order to automatically reconcile the
desired deployment state with the actual live state of the cluster.

The deployment state in the Git repository is declared through a
set of YAML files which Kustomize can process. Each of these files
declares a desired instantiation and runtime configuration for some
of the components in the Teadal cluster. Collectively, the files at
a given Git revision describe the deployment state of the entire
Teadal cluster at a point in time. Changes to the live system are
triggered through an automated workflow which the cluster administrator
initiates by creating a new revision of some YAML files in the Git
repository. On detecting a new revision, Argo CD transitions the
cluster to the new desired state. The diagram below exemplifies the
GitOps workflow.

![GitOps workflow.][dia.gitops]

Indeed the diagram depicts a typical scenario where the cluster administrator
carries out a change to a data service. As can be seen, the Git repository
contains descriptors for an FDP named `my-fdp` as well as other descriptors,
not explicitly shown, for the service and data mesh components in
the various cluster runtime layers mentioned earlier. The latest
Git revision is `v5` where the FDP service port is `6776`. The administrator
changes the port to `5445`, making a new Git revision `v6`. Argo CD
periodically polls the Git repository to detect any new revisions.
Thus, shortly after the administrator pushed revision `v6` to the
Git repository, Argo CD realises that the current cluster runtime
state refers to a stale revision, `v5`, whereas `v6` is the latest.
Hence, Argo CD proceeds to interpret the stanzas in the YAML file
as a command line that the Kubernetes client can understand. After
assembling the required command, Argo CD invokes the Kubernetes client
with it. In turn, the Kubernetes client calls the Kubernetes API which
finally triggers the desired deployment actions on the live cluster,
resulting in the deployment state to reflect the YAML configuration
at revision `v6`—i.e., `my-fdp`'s port is now `5445`.


### Teadal baseline repository

As explained earlier, a Teadal cluster is instantiated and then subsequently
updated through a GitOps approach whereby the desired cluster runtime
is declared in an online Git repository and a dedicated GitOps cluster
service, Argo CD, reconciles the desired runtime with the actual cluster
state. Thus, for each Teadal cluster `C[k]` deployed as part of a Teadal
pilot rollout there is a corresponding Git repository `R[k]` and Argo CD
service `A[k]` running in `C[k]` that reconciles `R[k]` with `C[k]`.
For example, the cluster for the viticulture pilot is deployed from
the *Smart Viticulture Teadal.Node* repository (https://gitlab.teadal.ubiwhere.com/teadal-pilots/viticulture-pilot/smart-viticulture-teadal-node)
and runs its own Argo CD service which monitors the *Smart Viticulture
Teadal.Node* repository and, upon detecting a change in the repository,
reconfigures the viticulture cluster to match the updated deployment
declarations in the repository.

Now, any two repositories `R[h]` and `R[k]` need to include the same
baseline software stack `S`—service and data mesh, Teadal tools, etc.
In other words, `S` comprises the components in the mesh infrastructure
and core services layers. Almost always, `S` will be exactly the same
for any two given pilot rollouts, hence the code in their respective
repositories `R[h]` and `R[k]` will also be the same.

For this reason, `S` is developed and managed in a master repository
(`teadal.node`) and each `R[k]` is a fork of the master which contains
data products and services specific to the pilot rollout. Forking
allows each `R[k]` to inherit the baseline components from `teadal.node`,
while also enabling customisation for specific deployments. This
arrangement avoids duplicating `S` in each `R[k]` and provides the
means to easily propagate any change to `S` from the master repository
to the forks `R[1]`, `R[2]`, etc., as illustrated in the diagram below.
Thus, when a new feature or update is added to the master repository,
it can be seamlessly integrated into all forks, ensuring consistency
and reducing maintenance overhead.

![Teadal master and pilot rollout repositories.][dia.cluster-repos]




[dia.cluster-repos]: ./cluster-repos.png
[dia.gitops]: ./gitops.png
[dia.tech-stack]: ./teadal.proto.png
