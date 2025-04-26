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


### Interaction patterns

The Teadal architecture supports several interaction patterns among
federation sites (Teadal nodes). This section provides an overview
of each pattern, focusing on interactions among Teadal nodes, and
excluding the more complex interactions within individual nodes.
Note that the following description outlines the types of inter-node
interactions which the Teadal architecture is designed to support.
Some of these patterns are already being tested in field trials,
while others are still potential possibilities. In other words,
this section describes the intended capabilities of the Teadal
design, rather than the specific features currently implemented
in the field trials.

- [Data product sharing][fdp]
- [Product discovery][catalogue]
- [Identity federation][idm]
- [Trust][trust]
- [Resource allocation][ra]




[catalogue]: ./product-discovery.md
[fdp]: ./data-sharing.md
[fed.dia]: ./federation.png
[idm]: ./identity-federation.md
[ra]: ./respource-allocation.md
[trust]: ./trust.md
