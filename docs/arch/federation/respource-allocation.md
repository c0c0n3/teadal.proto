Resource Allocation
-------------------

In a Teadal federation, efficient resource allocation is key to optimising
the performance and scalability of distributed workloads. Kubestellar
provides a powerful mechanism to allocate computational resources
across multiple Teadal nodes, enabling cross-cluster resource sharing.
Each Teadal node, running its own Kubernetes cluster, operates independently
by default. However, when multiple nodes are connected via Kubestellar,
they form a unified resource pool.

The key feature within Kubestellar that underpins this cross-cluster
resource allocation is the notion of "spaces". In Kubestellar, a "space"
 refers to a logical grouping of resources, which can span multiple
Teadal nodes. Spaces act as abstraction layers that represent the
available computational resources across the federated nodes. Each
space can include a variety of resources, such as CPU cores, GPUs,
memory, and storage, and can be defined based on specific requirements,
such as high-performance computing (HPC), data processing, or containerised
application environments. These spaces allow Kubernetes workloads to
seamlessly interact with resources from multiple Teadal nodes without
being constrained by the physical location of those resources.

For example, consider a scenario where we have two Teadal nodes—node
A and node B—each running its own Kubernetes cluster. Node A has
available computational resources: resource #1 (CPU) and resource
#2 (GPU). Node B has computational resources #3 (memory) and #4
(storage). With Kubestellar in place, node B can utilise resources
from node A, such as CPU (#1) or GPU (#2), despite the fact that
these resources reside in a different physical cluster. Kubestellar
abstracts the boundaries between clusters, allowing Kubernetes in
node B to schedule tasks onto resources that exist in node A as though
they were part of the same local resource pool.

This is particularly beneficial in environments where resource demands
fluctuate or where a single Teadal node might not have enough resources
to meet the needs of specific workloads. By utilising spaces, a Teadal
federation can improve resource utilisation and ensure that computational
resources are allocated where they are most needed, regardless of
the cluster or node they physically reside in. This enhances overall
efficiency and provides more flexibility in resource management, allowing
organisations to dynamically scale workloads in a distributed environment.

![Sharing computing resources between two Teadal nodes.][alloc.dia]




[alloc.dia]: ./resource-allocation.png
