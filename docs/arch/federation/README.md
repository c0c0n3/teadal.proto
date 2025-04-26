Teadal Federation
-----------------
> Inter-node Interactions.

Teadal is a cloud computing platform for sharing data among organisations.
This sharing happens by federating clusters running Teadal software.
In this section we review the concept of a Teadal federation and look
at interaction patterns among federation sites.


### Federated data sharing

Teadal delivers contract-bound, trusted, verifiable, and efficient
data sharing among organisations. It achieves this by allowing organisations
to make their data available in a distributed and decentralised data-sharing
environment, where Teadal software enforces data governance policies.
This environment can be modelled as a graph, where each node represents
a federation site controlled by an organisation, and each edge represents
a communication link between two sites. Each federation site has its
own computing resources, such as a cluster or data centre, and data
products, typically assembled from a data lake. Additionally, each
federation site runs the Teadal cloud computing platform (i.e., the
runtime comprising Teadal's services and tools) which allows that
organisation's site to share resources and data in a controlled manner.
We refer to each federation site as a "Teadal node", given the fact
that we model federation through a graph and a node in the graph
represents a site equipped with the Teadal runtime. Thus, the term
"Teadal node" highlights the critical role of the Teadal runtime in
enabling data sharing within the federation.

![Teadal federation concept.][fed.dia]




[fed.dia]: ./federation.png
