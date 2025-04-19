#
# authnz library entry point. authnz makes it easy to decide whether
# to allow an HTTP request or not, based on the credentials and some
# RBAC rules. On receiving HTTP request data from Envoy, authnz validates
# the JWT token in the request and then checks if the user named in
# the token is allowed to make that request. This check happens by
# looking up user permissions in an RBAC set of rules expressed in
# Rego.
#
# Here's where to find out more about how authnz works:
#
# - Typical usage example: `httpbin.service`.
# - Defining RBAC rules: `authnz.rbacdb`. Keep in mind you can define
#   roles directly in Rego or keep them in an external IdM where users
#   are defined. Or you could even mix the two approaches if you like.
#   See: `authnz.rbacdb` and `authnz.rbacdb_ext`.
# - JWT validation: `authnz.oidc`. authnz supports both static and
#   dynamic scenarios with automatic discovery, download and caching
#   of token issuer's JWKs. Plus, there's a bunch of options to make
#   it easy to test and debug in isolation (i.e., just Rego code, no
#   external IdM required) or with a local IdM, e.g., running in a
#   K8s cluster on your dev box. See: `authnz.config`.
# - Tweaking authnz behaviour: `authnz.config`.
#
# authnz expects the current HTTP request's data to be in an object
# with the following fields:
# - `headers.authorization`: Bearer token.
# - `method`: request's HTTP method.
# - `path`: path part of the request's URL.
#
# authnz expects to find this object at `input.attributes.request.http`.
# This is the case when using the OPA Envoy plugin with Envoy. But in
# principle different setups are possible too, even without Envoy. The
# only requirement is to put the above fields in `input.attributes.request.http`
# before calling authnz to evaluate the HTTP request.
#

package authnz.envopa

import input.attributes.request.http as http_request
import data.authnz.oidc as oidc
import data.authnz.rbac as rbac


# Allow or deny the current HTTP request.
# Return the user named in the JTW if the request is allowed.
#
# Params
# - rbac_db. The RBAC rules---see the RBAC DB tests for explanations.
# - config. An object containing authnz config---see the config test
#   for explanations.
allow(rbac_db, config) := user if {
    payload := oidc.claims(http_request, config)
    user := payload[config.jwt_user_field_name]
    external_roles := jwt_roles(payload, config)               # (1)
    rbac.check(rbac_db, user, external_roles, http_request)
}
# NOTE
# ----
# 1. Optional external roles. If the JWT holds no roles for the given user,
# we still want to go ahead and check the request using whatever roles may
# be in the RBAC DB. However, Rego conflates assignment with evaluation so
# we need an extra helper function, `jwt_roles`, to make sure the RHS expr
# never evaluates to undefined or produces a type error. For instance,
# `r := "okay" { x := {}["x"]; 1 == 1 }` actually evaluates to undefined.
#

default jwt_roles(_, _) := []
jwt_roles(payload, cfg) := roles if {
    roles := payload[cfg.jwt_roles_field_name]
}
