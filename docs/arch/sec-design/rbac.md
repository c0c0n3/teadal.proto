RBAC Framework
--------------
> R-BAK-ed with love for Teadal :-)

While the [machinery described so far][design] can be used to enforce
any kind of access control, Teadal also provides a built-in Role-Based
Access Control (RBAC) framework. This framework dramatically reduces
the effort needed to implement access control for RESTful services,
while still leaving policy writers the freedom to extend the base
framework with service-specific functionality.


### Introduction

Data lake users are managed through a federated, [OIDC][oidc]-compliant
identity management (IdM) service. Consumer services act on behalf
of users who have proved their identity through IdM-configured procedures
such as credential challenges, multi-factor authentication, etc. Upon
successful authentication, the IdM issues an identity token, more
specifically a [JSON Web Token][jwt] (JWT), which certifies the user's
identity. Consumer services attach the token to each data product
service request by means of the [Bearer][bearer] HTTP Authorization
header. Presently, Teadal deploys [Keycloak][keycloak] as an IdM service,
although any other OIDC-compliant software could be used too as the
RBAC framework only requires OIDC-compliance, making no assumption
about the actual IdM implementation.

RBAC roles, users and policy rules are written in plain Rego. Thus,
policy writers are empowered with a fully-fledged programming language
which they can exploit to customise, abstract and reuse their roles
and policies to an extent that is simply not possible with traditional,
configuration-based, cloud Identity and Access Management solutions.
Moreover, policy writers can implement automated Rego tests to verify
their policies have the desired effect when evaluated or even do that
interactively, for rapid prototyping, as the OPA runtime has both
test and read-eval-print loop (REPL) facilities. Extensive, automated
tests also prevent regression issues where modifying a rule may have
an unforeseen, unwanted side-effect, possibly leading to a security
incident. Again, this level of sophistication is extremely expensive,
in terms of required effort, to attain with traditional Identity and
Access Management solutions.

The Teadal `authnz` Rego library is a good case in point. Policy
writers import this library in their code to automatically handle
the evaluation of RBAC rules, user authentication, JWT validation,
OIDC discovery as well as cryptographic keys download, verification
and caching. The library allows policy writers to concentrate on
defining their own, service-specific access control rules using an
intuitive format.


### Usage example

By way of example, consider securing a simple FDP. The REST service
exposes patient records as Web resources. There are three paths:
`/patients` to list and add patients, `/patients/id/` to retrieve
and delete a particular patient, and `/patients/age` to retrieve
a list with the ID and age of each patient but nothing else. Also,
there is a `/status` path which returns the current service status.
We would like to define two roles. A product owner, which should
be able to perform a `GET`, `POST` and `DELETE` on any URL path
starting with `/patients`, and a product consumer, which should
only be allowed to `GET` patient ages and service status. Moreover,
we would like to assign both the product owner and consumer roles
to the user identified by the email of `jeejee@teadal.eu` whereas
just the product consumer role to the user identified by the email
of `sebs@teadal.eu`. In the Teadal RBAC framework, all of the above
can be accomplished with the following Rego code.

```rego
# Role defs.
product_owner := "product_owner"
product_consumer := "product_consumer"

# Map each role to a list of permission objects.
# Each permission object specifies a set of allowed HTTP methods for
# the Web resources identified by the URLs matching the given regex.
role_to_perms := {
    product_owner: [
        {
            "methods": [ "GET", "POST", "DELETE" ],
            "url_regex": "^/patients/.*"
        }
    ],
    product_consumer: [
        {
            "methods": [ "GET" ],
            "url_regex": "^/patients/age$"
        },
        {
            "methods": [ "GET" ],
            "url_regex": "^/status$"
        }
    ]
}

# Map each user to their roles.
user_to_roles := {
    "jeejee@teadal.eu": [ product_owner, product_consumer ],
    "sebs@teadal.eu": [ product_consumer ]
}
```

To evaluate our RBAC rules against the request received from Envoy,
we would simply import the Teadal `authnz` library and call its
`allow` function as exemplified by the Rego code snippet below,
where we tacitly assume the RBAC rules defined earlier are in
a package imported as `rbac_db`.

```rego
default allow := false

allow = true {
    # Use the `allow` function from `authnz.envopa` to check our RBAC
    # rules against the HTTP request received from Envoy. The function
    # returns the user extracted from the JWT if the check is successful.
    user := envopa.allow(rbac_db)

    # Put below this line any service-specific checks on e.g. the
    # HTTP request received from Envoy.
}
```

As already mentioned, `authnz` automatically handles the evaluation
of RBAC rules, user authentication, JWT validation, OIDC discovery
as well as cryptographic keys download, verification and caching.
Also of note, `authnz` provides built-in functions to evaluate
user-defined RBAC rules interactively in the Rego REPL. This is
useful for dry-run scenarios where a policy writer may want to see
what is the effect of their RBAC rules before deploying them to the
data lake.


### Mapping users to roles

In the previous example, roles were defined in Rego along with the
mapping of users to roles. It is also possible to define roles in
the IdM where users are kept and use the IdM's tools to associate
users to roles. In this case, the Rego policy would only contain the
`role_to_perms` map associating each role defined in the IdM to a
list of permission objects as shown in the example below.

```rego
role_to_perms := {
    "product_owner": [
        {
            "methods": [ "GET", "POST", "DELETE" ],
            "url_regex": "^/patients/.*"
        }
    ],
    "product_consumer": [
        {
            "methods": [ "GET" ],
            "url_regex": "^/patients/age$"
        },
        {
            "methods": [ "GET" ],
            "url_regex": "^/status$"
        }
    ]
}
```

This Rego code defines a policy that has the same effect as that
presented earlier where users were explicitly associated to roles
through the `user_to_roles` map.

A mixed scenario is also possible, where some roles are defined in
the IdM and others in Rego policies—the [Whirlwind Tour][wt] section
provides an example of this. Regardless of the approach, if some (or
all) roles are managed in the IdM, then:
- the IdM must generate access tokens that include not only the
  authenticated user's ID, but also a list of roles the user
  belongs to; and
- `authnz` must be configured to read both the user ID and the
  roles from the access token.

In this setup, `authnz` merges any roles extracted from the token
with the roles defined for that user in Rego.

For added convenience, `authnz` treats each user as a singleton role.
More precisely, `authnz` identifies every user `u` with a role named
`u`, which contains only `u` as its member. For example, the user
`sebs@teadal.eu` from the previous example implicitly has a corresponding
role also named `sebs@teadal.eu`, with the user as its sole member.
These implicit singleton roles allow policy writers to assign permissions
directly to a user in the `role_to_perms` map, without needing to
explicitly list the user as an additional role in the `user_to_roles`
entry for that user.

For example, suppose the policy writer wants to extend the previous
policy with a rule specific to the user `sebs@teadal.eu`. As a product
consumer, `sebs@teadal.eu` does not have access to service metrics.
Without implicit singleton roles, the policy writer would need to
manually add an entry to `user_to_roles` to associate `sebs@teadal.eu`
with a role of the same name, in order to then add a corresponding
entry for role `sebs@teadal.eu` to the `role_to_perms` map, as shown
below.

```rego
role_to_perms := {
    # ... same entries as earlier, plus
    "sebs@teadal.eu": [
        { "methods": ["GET"], "url_regex": "^/metrics/.*" }
    ]
}
user_to_roles := {
    # make `sebs@teadal.eu` a member of `sebs@teadal.eu` so the
    # above `role_to_perms` works.
    "sebs@teadal.eu": [ "sebs@teadal.eu" ]
}
```

While this works, it is cumbersome and places an additional burden
on the policy writer—especially when roles are managed externally
in an IdM system. Ideally, in such cases, the policy writer should
only need to specify the `role_to_perms` map, without also maintaining
the `user_to_roles` map. With implicit singleton roles, there is no
need to explicitly map users to roles of the same name. The policy
writer can simply rewrite the code as follows:

```rego
role_to_perms := {
    # ... same entries as earlier, plus
    "sebs@teadal.eu": [
        { "methods": ["GET"], "url_regex": "^/metrics/.*" }
    ]
}
```


### Formal model

We present a simple mathematical model of the RBAC framework. This
model succinctly and accurately captures how `authnz` handles authentication
and authorisation using basic set theory and functions. More sophisticated
and elegant models—such as relation composition, the power-set monad
with Kleisli composition—could express the same ideas more concisely.
However, while arguably more powerful, such constructions are likely
less familiar to most software developers.

We model how `authnz` maps users to roles using a mathematical function.
Let `R : User ⟶ 𝒫(Role)` be the function that maps a user to a set
of roles, where both users and roles are uniquely identified by text
labels. For each user `u`, define `D(u)` as the set of roles assigned
to `u` in the `user_to_roles` mapping from the RBAC DB. If `user_to_roles`
is undefined, or contains no entry for `u`, then `D(u)` is the empty
set `∅`. Similarly, let `T(u)` be the set of roles found in the access
token issued to `u`. If no roles are present in the token, then `T(u) = ∅`.
The set of roles that `authnz` uses to evaluate the policy for user
`u` is the union of these sets and the user identifier as a singleton
role: `R(u) = D(u) ∪ T(u) ∪ {u}`. As noted earlier, `authnz` identifies
each user `u` with a role named `u`, consisting only of `u` as its member.
In other words, for each user `u`, `u ∈ R(u)`.

Similarly, we define a function to model how `authnz` determines the
permissions associated with a user. This corresponds to the set of
all permissions linked to the user, via roles, in the RBAC database.
Specifically, the `role_to_perms` mapping in the RBAC DB can be viewed
as a function that assigns each role `r` a set of permissions `P(r)`,
so that `role_to_perms(r) = P(r)`. The set of permissions associated
with a user `u` is then the union of all `P(r)` for `r ∈ R(u)`. Thus,
we define a function `K : User ⟶ 𝒫(Perm)` by: `K(u) = ⋃ P(r)` where
`r ∈ R(u)`.

To illustrate how `K` works, consider the following example. A user
`u1` belongs to roles `r1` and `r2`, so `R(u1) = { r1, r2 }`. Each
role has the following permissions: `P(r1) = { p1, p2 }` and
`P(r2) = { p2, p3, p4 }`. Another user, `u2`, belongs to roles `r2`
and `r3`, with `P(r3) = { p5 }`. The relationships can be visualized
as a directed graph, where arrows represent mappings from users to
roles (`R`) and from roles to permissions (`P`):

```
                       u1     u2
       R ↓            ↙  ↘   ↙  ↘       __.
                    r1    r2     r3       |
       P ↓         ↙ ↘  ↙ ↙ ↘    ↓        |___ role_to_perms
                  p1  p2 p3  p4  p5       |
                                        __|
```

The set of permissions associated with `u1` is the set of permission
nodes reachable via a directed path from `u1`, namely `{ p1, p2, p3, p4 }`.
Similarly, `u2` is associated with `{ p2, p3, p4, p5 }`.

With `K` defined, we can now describe how `authnz` makes policy decisions.
We model permissions as predicates over HTTP requests, that is, functions
of the form `p : Req ⟶ Bool`. Then, `authnz` authorises an incoming HTTP
request `req` if and only if the following two conditions are satisfied:
- `req` contains a valid JWT token for user `u`;
- there exists a permission `p ∈ K(u)` such that `p(req) = true`.




[bearer]: https://datatracker.ietf.org/doc/html/rfc6750
[design]: ./tech-design.md
[keycloak]: https://www.keycloak.org/
[jwt]: https://datatracker.ietf.org/doc/html/rfc7519
[oidc]: https://openid.net/developers/how-connect-works/
[wt]: ../../whirlwind-tour.md#security
