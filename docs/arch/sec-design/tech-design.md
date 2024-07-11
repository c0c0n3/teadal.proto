Security Design
---------------
> getting down to the nitty-gritty.

The [Security Conceptual Model][concept] outlines the Teadal security
architecture from a non-technical standpoint. In a nutshell, communication
between consumers and data product services is mediated by interception
proxies that interpose access control. Proxies delegate access control
decisions and enforcement to a policy decision point and policy enforcement
point, respectively. Product owners specify access control policies
to govern how their data products ought to be consumed. A policy
store makes these policies available to the policy decision point
for evaluation against consumer requests to perform operations on
data products.

This section delves into the technical design and technology stack
adopted to realise the aforementioned conceptual architecture. Note
that the Teadal security implementation embraces Open Source: all
the technology stack components, both third-party and Teadal's own,
are open-source.


### Message interception and access control delegation

[Istio][istio-arch] provides the message interception facility. Indeed,
Istio provides the infrastructure on which the control and data plane
of the Teadal data mesh are built. In particular, the data plane contains
a network of proxies through which data product inbound and outbound
HTTP traffic flow. A data product service (FDP, sFDP) exposes a REST
API. Consumers access the data product by making HTTP requests to this
data product API. The Istio data plane proxies intercept each consumer
request and data product service response.

In the Teadal implementation, the control plane configures and deploys
data product proxies. These proxies are Istio extensions of the [Envoy
proxy][envoy] tailored to work seamlessly with the Istio mesh. The Istio
control plane pairs a proxy with each data product service upon service
deployment to the mesh. As part of the deployment procedure, the control
plane configures `iptables` rules to make the proxy receive any IP
packet destined for or originating from the data product service.
Thus, the service is isolated from the network, in the sense that
it cannot communicate directly with other mesh services or external
clients as all IP traffic is forced through the proxy.

Envoy implements a pipes and filters design to process HTTP traffic.
Each filter is a module handling a specific aspect of a request/reply
exchange and filters are combined together in a request processing
pipeline so that the output of a filter becomes the input of the next
filter in the pipeline. The Teadal implementation configures the Istio
Envoy with an [External Authorization Filter][ext-authz] so that, on
receiving a data product service request, Envoy triggers the filter
execution before forwarding the request to the data product service.

The Authorization Filter acts as a policy enforcement point. It connects
to an external policy decision point to determine whether to allow
or deny data product service requests. The decision point can be any
[gRPC][grpc] service implementing the External Authorization interface
defined by the following [Protocol Buffers][protobuf] specification

```protobuf
service Authorization {
  rpc Check(CheckRequest) returns (CheckResponse) {}
}
```

The filter invokes the `Check` procedure with a structure (`CheckRequest`)
holding HTTP request data and additional Envoy parameters. The policy
decision point responds either with an "allow" or "deny" decision,
encoded in the `CheckResponse` structure. In the case of an "allow"
decision, the filter lets Envoy forward the consumer's request to
the data product service. On the other hand, in the case of a "deny"
decision, the filter stops the request pipeline execution and instructs
Envoy to return an HTTP Forbidden (403) response to the consumer
instead of forwarding the request to the data product service.


### Policy decision point and store

The [Open Policy Agent][opa] (OPA) is a key technology of the Teadal
access control implementation. OPA's Datalog-inspired Rego programming
language affords policy writers the means to express access control
rules as high-level, declarative logic queries on data product service
requests. OPA's versatile runtime caters for evaluating queries against
arbitrary JSON inputs both interactively and in server mode as well
as testing Rego code and assembling it into binary, digitally signed
"bundles" which can be downloaded and evaluated by the OPA server.

The Teadal mesh employs the [OPA Envoy Plug-in][opa-envoy] as a policy
decision point. This plug-in embeds the OPA server runtime and implements
the External Authorization gRPC interface detailed earlier by evaluating
Rego policies against the HTTP request dispatched by the External
Authorization Filter. The Teadal implementation connects the Envoy
to the plug-in and configures the latter to fetch policy bundles from
a dedicated Nginx server which acts as the policy store. The plug-in
and Nginx are configured to use [HTTP long polling][long-poll] so
that the plug-in can efficiently update previously downloaded and
cached bundles. After downloading a bundle, the plug-in also verifies
its digital signature before evaluating the contained code to ensure
that only trusted policies are enforced.


### Interaction mechanics

The process of augmenting data product functionality with access
control is as follows. First off, the Istio Envoy proxy intercepts
the HTTP request which the data consumer makes to the data product
API. Envoy dispatches the request to the request processing pipeline,
which, as explained earlier, is configured with the Teadal External
Authorization Filter. The filter begins to process the request by
invoking the configured gRPC server implementation of the External
Authorization interface, that is, it calls the `Check` procedure
passing in request data and other Envoy-specific parameters. If the
`Check` procedure returns an "allow" decision, the filter makes Envoy
route the consumer's original HTTP request to the data product service,
collect the response and forward it to the consumer. On the other
hand, if the `Check` procedure returns a "deny" decision, the filter
causes the request pipeline to halt and makes Envoy return an HTTP
Forbidden (403) response to the consumer. In this case the consumer's
original request never reaches the data product service.

The OPA Envoy Plug-in is the configured service implementing the
External Authorization interface. When the filter calls the `Check`
procedure, the plug-in service retrieves the current Rego policies
from the configured Nginx Web server. The plug-in caches and updates
policies through HTTP long polling, as explained earlier. Having
the current policies, the plug-in proceeds to evaluate them against
the HTTP request data contained in the `CheckRequest` input to the
`Check` call. These policies actually determine whether the request
should be allowed or access to the data product service API should
be denied. The plug-in puts the policy evaluation outcome in the
`CheckResponse` structure and returns it to the filter.

The following diagram illustrates the process just described in the
case of an "allow" decision and summarises the access control implementation
discussion so far.

![Security components and interaction overview.][security-overview.dia]

Note that both the data product and the consumer are unaware of the
Istio Envoy proxy. From the consumer's perspective, the HTTP request
is a direct message to the data product API as if the consumer were
invoking the API without a proxy in between. Similarly, the data
product API processes the request as if it originated directly from
the consumer and produces the same response it would if the proxy
did not intercept the incoming request.


### RBAC framework

While the machinery described so far can be used to enforce any kind
of access control, Teadal also provides a built-in Role-Based Access
Control (RBAC) framework. This framework dramatically reduces the
effort needed to implement access control for RESTful services, while
still leaving policy writers the freedom to extend the base framework
with service-specific functionality.

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
RBAC framework only requires OIDC-compliancy, making no assumption
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


### Alternative policy decision points

The Envoy External Authorization Filter can be connected to any gRPC
service implementing the External Authorization interface. Thus, policy
decision points other than the OPA Envoy Plug-in may be wired into
the Teadal mesh too.

One alternative policy decision point is the Teadal Datalog interpreter.
This is a gRPC service that implements the `Check` procedure by spawning
a separate process to interpret Datalog policies. The process runs
the [Soufflé][souffle] binary to evaluate a Datalog script against
the HTTP request data extracted from the input `CheckRequest` structure.
The service then returns either an "allow" or "deny" response to the
Envoy External Authorization Filter depending on whether or not the
script allowed the request. Note how the Datalog interpreter's architecture
is very similar to that of the OPA Envoy Plug-in. Conceptually the
workflow is the same, although instead of evaluating Rego code, the
service evaluates Datalog scripts.

Another variation on the theme is [Anubis][anubis]. This is a [Web
Access Control][wac] (WAC) solution originally developed as part of
the [FIWARE platform][fiware], but currently being extended to work
in a Teadal mesh too. The basic idea here is that a product owner
uses the Anubis UI to specify access control rules in a WAC-compliant
fashion without needing to understand a programming language whereas
a programmer develops FDP-specific Rego scripts to evaluate WAC policies
against data product HTTP requests. The policy decision point in this
case is still the OPA Envoy Plug-in which is preconfigured with the
Rego scripts whereas the Anubis policy management service pushes WAC
policies to the plug-in at regular intervals.




[anubis]: https://github.com/orchestracities/anubis
[bearer]: https://datatracker.ietf.org/doc/html/rfc6750
[concept]: ./concept.md
[envoy]: https://www.envoyproxy.io/
[ext-authz]: https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter
[fiware]: https://www.fiware.org/
[grpc]: https://en.wikipedia.org/wiki/GRPC
[istio-arch]: https://istio.io/latest/docs/ops/deployment/architecture/
[keycloak]: https://www.keycloak.org/
[jwt]: https://datatracker.ietf.org/doc/html/rfc7519
[long-poll]: https://datatracker.ietf.org/doc/html/rfc6202
[oidc]: https://openid.net/developers/how-connect-works/
[opa]: https://www.openpolicyagent.org/
[opa-envoy]: https://github.com/open-policy-agent/opa-envoy-plugin
[protobuf]: https://en.wikipedia.org/wiki/Protocol_Buffers
[security-overview.dia]: ./istio-opa-security.svg
[souffle]: https://souffle-lang.github.io/
[wac]: https://solid.github.io/web-access-control-spec/
