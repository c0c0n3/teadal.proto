Security Conceptual Model
-------------------------
> ...as seen from the moon.

This is a lunar-orbit, non-technical view of the security architecture.


### Service mesh

Augmenting system functionality through message interception is a
key tenet of a service-oriented mesh architecture. Both inbound and
outbound service communication transit through a network of proxies
which isolate services from each other and the rest of the network.
On intercepting a service request, a proxy can inspect it, decide
whether to route it to the target service and possibly alter it
before routing it. Likewise, proxies intercept service responses
and possibly process them before forwarding them to service clients.
The mesh can leverage this interception mechanism to enrich service
functionality without requiring any alteration to service code. One
particular application of this architecture pertains to security.


### Access control

Teadal employs a mesh infrastructure to provide data product access
control. Data product services (FDP, sFDP) do not need to implement
access control. The mesh provides it by intercepting requests to
data product services and delegating access control to the following
components, which are implemented and deployed independently of data
products:
- *Policy decision point*. Given a service request, it decides whether
  to allow it. The decision process entails evaluating access control
  policies applicable to the service request. Policies are written in
  a high-level, domain-specific language.
- *Policy store*. It allows product owners (or someone on their behalf)
  to store and manage the policies for their respective data products
  as well as making them available to the policy decision point for
  evaluation.
- *Policy enforcement point*. It interacts with the policy decision
  point to determine whether to allow or deny service requests and
  with the mesh proxy to enforce the access control decision.


### Interaction mechanics

The process of augmenting data product functionality with access
control is as follows. First off, the mesh proxy intercepts the
request which the data consumer makes to the data product API. The
proxy then asks the policy enforcement point to process the request.
In turn, the policy enforcement point asks the policy decision point
to check whether the request is allowed to proceed. The policy decision
point looks up the policies applicable to the given request in the
policy store and then evaluates them against the request. If the
evaluation outcome indicates that the request should be allowed,
the policy decision point informs the policy evaluation point accordingly.
On receiving an "allow" decision, the policy enforcement point instructs
the proxy to route the request to the data product service, collect
the response and forward it to the data product consumer. On the
other hand, in the case of a "deny" decision, the policy enforcement
point issues an unauthorised error response that the proxy forwards
immediately to the data product consumer without proceeding to invoke
the data product API. The diagram below illustrates the access control
process just outlined in the case of an "allow" decision.

![Security components and interaction overview.][security-overview.dia]

Note that both the data product and the consumer are unaware of the
interception proxy. From the consumer's perspective, the request is
a direct message to the data product API as if the consumer were
invoking the API without a proxy in between. Similarly, the data
product API processes the request as if it originated directly from
the consumer and produces the same response it would if the proxy
did not intercept the incoming request.




[security-overview.dia]: ./mesh-security-concept.svg
