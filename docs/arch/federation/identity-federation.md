Identity Federation
-------------------

In a Teadal federation, each Teadal node operates independently,
with its own Identity Management (IdM) system and policy framework,
managing the authentication and authorisation of users. Each IdM
maintains a local user directory and supports identity-related services
for its node's users. However, when nodes need to collaborate, it's
possible for them to share user identities securely without replicating
user databases across nodes. This is accomplished through identity
federation, a concept that allows one Teadal node to import users
from another node's IdM system.

Teadal supports identity federation through the OpenID Connect (OIDC)
protocol, a widely adopted standard for authentication. Using OIDC,
one IdM (the federated IdM) can authenticate users from another IdM
(the imported IdM) by leveraging a secure identity token exchange.
When an identity federation is established between two Teadal nodes,
one IdM becomes the identity provider (IdP) and the other the service
provider (SP). The identity provider authenticates the user and provides
an OIDC-compliant identity token to the service provider, which is
then passed on to the policy framework. The policy framework validates
the token signature and decides whether to grant access to the data
and services available at that node, depending on the permissions
found in the token.

This method of federating user identities offers several benefits:

- *Seamless user access*. Users in one Teadal node can access resources
  in another Teadal node without needing separate credentials, simplifying
  user management across the federation.
- *Security and trust*. Since identity information is transmitted
  securely via the OIDC protocol, Teadal nodes can ensure that only
  authenticated users from trusted sources are granted access to
  resources. Specifically, as mentioned earlier, in a Teadal federation,
  a product consumer is typically located on a different node than
  the one where the data product is maintained. With identity federation,
  the policy framework can securely identify and grant access to
  consumers across the federation.
- *Decentralised control*. Each Teadal node retains control over its
  own user directory, while still being able to federate identities
  with other nodes as needed.

![Identity federation between two Teadal nodes.][idm.dia]




[idm.dia]: ./identity-federation.png
