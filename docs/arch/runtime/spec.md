Runtime spec
------------
> What the TEADAL cluster runtime should look like.

This section presents a conceptual view of the Teadal cluster runtime.
It is an abstract description of the services that typically run in
a Teadal cluster instance in terms of the functionality they provide
without reference to actual software implementing that functionality.
D6.2 [**TODO**: cite] complements this abstract description with the
software products that have been selected to provide the functionality
detailed next.

The Teadal cluster runtime comprises four layers of processes and
hardware. This is a classic layered architecture where each layer
depends on and builds on the functionality provided by the layer
directly beneath whereas it has no knowledge of the layers above.
From bottom to top, the four layers are: *hardware*, *mesh infrastructure*,
*core services* and *products*. The diagram below depicts these
layers along with the services in each layer and should be kept at
hand as we describe each layer in detail.

![Cluster runtime layers.][dia.layers]


### Hardware layer

The *hardware* layer comprises the physical or virtual computing,
storage and network resources on which all the Teadal cluster software
runs. In the case of a public cloud deployment, typically a hypervisor
would provide the hardware layer as a set of virtual resources. On
the other hand, an on-premises deployment may entail provisioning
physical machines. The number of hardware resources in the cluster
depends on the processing power required for a given deployment but
notice that it is also possible to host the whole Teadal cluster runtime
on a single physical or virtual machine in cases where a simpler
deployment is desirable—e.g. for testing or evaluating Teadal.


### Mesh infrastructure layer

The *mesh infrastructure* layer interfaces with the *hardware* layer
to provide the service mesh functionality. A core service in this
layer provides cluster orchestration and scalability by managing
computational resources (CPU, memory, storage), allocating them to
processes in the upper layers and orchestrating the deployment and
operation of services by means of containers. A distributed storage
facility provides the orchestration service with uniform, high-level
access to the underlying disks attached to cluster nodes. Together,
orchestration and distributed storage unify the underlying hardware
resource in a high-level, aggregated computing facility.

A Teadal cluster is instantiated and then subsequently updated through
a GitOps approach. An automated deployment and GitOps service in the
*mesh infrastructure* layer monitors the desired cluster runtime
specification as declared in an online Git repository associated
with the cluster. On detecting a new revision in the Git repository,
the service automatically reconciles the desired new runtime specification
with the actual live state of the cluster.

Service mesh software extends cluster orchestration with control and
data planes. The control plane manages a network of proxies, the data
plane, which capture and process cluster inbound and outbound traffic
as well as internal service traffic. This allows to augment service
functionality at runtime without requiring any modifications to the
services themselves. The Teadal cluster exploits this to transparently
route and balance service traffic, secure communication and access to
service resources, and monitor service operation. In fact, a set of
security services plug into the control plane to provide identity
and access management, security policies, and tracing. Likewise,
a set of observability services complement the control plane's core
functionality with service metrics, performance dashboards and a
mesh control panel.


### Core services layer

The *core services* layer runs on the *mesh infrastructure* to provide
the Teadal core functionality which enables federated data products.
A set of Teadal tools and services allow multiple Teadal clusters to
be joined in a federation where producers and consumers can share data
in a trustworthy and secure way, according to agreed-upon governance,
privacy and energy-efficiency policies. Catalogue, Advocate, FDP
Pipelines, Trusted Execution Environment as well gravity and friction
policies are part of the Teadal tools.

General-purpose persistence and workflow services are also part of
the *core services* layer. Persistence services include a relational
database and an object store, whereas workflow services support dataflow
programming for engineering data pipelines and MLOps for managing
machine learning operations.


### Products layer

The *products* layer hosts data products and services—i.e., federated
data products (FDPs), shared federated data products (SFDP), etc.
As detailed in D3.1 [**TODO**: cite], a federated data product (FDP)
extends the notion of data mesh product to cater for sharing data in
a data lake federation according to the governance rules of that
federation. A shared federated data product (SFDP) encapsulates a
consumer-producer agreement (contract) about sharing a part of an
FDP and provides the means for the consumer to process the shared
data only within the bounds of the agreed-upon contract.

Notice a consumer accesses an SFDP through a REST API. Whereas it
is convenient, from a conceptual standpoint, to think of the consumer
directly connecting to the SFDP through HTTP, actual network traffic
goes through the data plane ingress so that Teadal can process HTTP
requests before they reach the SFDP and responses before they reach
the consumer. This way, the service mesh and the Teadal tools can
ensure data are consumed according to the consumer-producer agreed
workflow and contract as well as federation governance rules.




[dia.layers]: ./conceptual-layers.png
