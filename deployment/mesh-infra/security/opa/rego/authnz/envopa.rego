#
# TODO docs
#

package authnz.envopa

import input.attributes.request.http as http_request
import data.authnz.oidc as oidc
import data.authnz.rbac as rbac


allow(rbac_db, config) := user {
    payload := oidc.claims(http_request, config)
    user := payload[config.jwt_user_field_name]
    external_roles := jwt_roles(payload, config.jwt_roles_field_name)  # (1)
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

jwt_roles(payload, roles_field) := [] {
    not payload[roles_field]
}
jtw_roles(payload, roles_field) := roles {
    roles := payload[roles_field]
}
