Data Product Sharing
--------------------

The FDP/SFDP concept is the cornerstone of data product sharing in
a Teadal federation. An FDP sources its data from an organization's
internal data product, making it available to consumers within a
Teadal federation. However, consumers, who typically belong to another
organisation, cannot access an FDP directly. Rather, they have to
agree with the producer on specific sharing terms regarding a subset
of the data which the FDP holds. The SFDP encapsulates these sharing
terms and makes a specific subset of data from the FDP that is agreed
upon for sharing available to the consumer.

FDPs and SFDPs are RESTful services, whereas consumers are RESTful
clients. Therefore a consumer is an HTTP client process making an
HTTP request to an SFDP server to query some data product. In turn,
an SFDP retrieves data from its associated FDP over HTTP.

Depending on gravity and friction rules, the SFDP may be deployed
either in the consumer's Teadal node or in another federation node,
typically the one hosting the FDP. Consequently, there are two interaction
scenarios between the Teadal nodes involved in a data product sharing
transaction:

- Decentralised SFDP. The FDP and SFDP are in separate Teadal nodes.
  In this case the consumer typically is in the same Teadal node as
  the SFDP. Thus, the interaction between the two nodes consists of
  HTTP traffic between the SFDP and the FDP.
- Centralised SFDP. Both the FDP and SFDP are in the same Teadal node.
  In this scenario, the consumer is deployed in a separate Teadal node
  than the FPD/SFDP pair and the interaction between the nodes consists
  of HTTP traffic between the consumer and the SFDP.

![Federated data product sharing between two Teadal nodes.][sharing.dia]




[sharing.dia]: ./2.data-sharing.png
