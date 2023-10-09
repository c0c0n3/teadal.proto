authnz
------
> Eensy-weensy lib for role-based access control of RESTful services.

This library lets you easily define role-based access control (RBAC)
rules to protect your RESTful services and then enforce those rules
on each HTTP request.

Features at a glance:
- Declare your RBAC roles, users and rules in plain Rego using an
  intuitive DB format.
- Easily query the RBAC DB with `authnz` built-in functions or roll
  out your own Rego queries.
- Choose any OIDC-compliant IdM (e.g. Keycloak) to manage your users
  and identify them through JSON Web tokens (JWT).
- Let `authnz` handle JWT validation for you---from OIDC discovery
  to JWKs download to signature verification, `authnz` does it all
  for your under the bonnet. You can also use a static JWKs though
  if you like.
- Seamlessly hook your RBAC into the Envoy OPA Plugin to enforce
  your rules.


### Usage
TODO


### Hacking
TODO
