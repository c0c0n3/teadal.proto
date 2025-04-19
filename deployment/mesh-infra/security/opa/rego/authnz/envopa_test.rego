package authnz.envopa

import data.authnz.oidc as oidc
import data.authnz.rbacdb_ext as rbac_db


oidc_config := {
    "jwt_user_field_name": "user",
    "jwt_roles_field_name": "roles",
    "jwks": oidc.jwks_tasty_config
}

make_request(path, method, user, roles) := envoy_input if {
    payload := {
        "iss": "me",
        "exp": 10000000000,  # 20 Nov 2286 @ 18:46:40 (CET)
        "user": user,
        "roles": roles
    }
    token := oidc.generate_tasty_token(payload)
    request := {
        "headers": {
            "authorization": oidc.make_bearer_auth(token)
        },
        "method": method,
        "path": path
    }
    envoy_input := {
        "attributes": {
            "request": {
                "http": request
            }
        }
    }
}

test_jwt_roles_no_roles_field_in_config if {
    payload := {
        "roles": ["r"]
    }
    oidc_cfg := {}
    roles := jwt_roles(payload, oidc_cfg)
    roles == []
}

test_jwt_roles_empty_roles_field_in_config if {
    payload := {
        "roles": ["r"]
    }
    oidc_cfg := {
        "jwt_roles_field_name": ""
    }
    roles := jwt_roles(payload, oidc_cfg)
    roles == []
}

test_jwt_roles_missing_roles_field_in_payload if {
    payload := { }
    oidc_cfg := {
        "jwt_roles_field_name": "roles"
    }
    roles := jwt_roles(payload, oidc_cfg)
    roles == []
}

test_jwt_roles_when_roles_field_in_payload if {
    payload := {
        "roles": ["r"]
    }
    oidc_cfg := {
        "jwt_roles_field_name": "roles"
    }
    roles := jwt_roles(payload, oidc_cfg)
    roles == ["r"]
}

test_product_owner_can_delete if {
    user := allow(rbac_db, oidc_config)
        with input as make_request(
            "/httpbin/anything/", "DELETE", "jeejee", ["product_owner"])
    user == "jeejee"
}

test_product_consumer_cant_delete if {
    not allow(rbac_db, oidc_config)
        with input as make_request(
            "/httpbin/anything/", "DELETE", "sebs", ["product_consumer"])
}

# NOTE
# ----
# 1. Enough tests. We need to check the `allow` function works. But this
# function delegates all the work to `claims`, `check` and `jwt_roles`.
# The `claims` and `check` functions are already tested thoroughly in
# their own packages. In particular, the tests for `check` verify it
# works in the case of roles only being defined in the RBAC DB, the
# case of roles being defined only in the IdM and the case where some
# roles are defined in the RBAC DB whereas some others in the IdM.
# Plus, the `httpbin` tests verify the `allow` function works in all
# cases (all URLs, users and perms) when using the RBAC DB without
# external roles.
# So what we really need to check here is all the `jwt_roles` branches
# and `allow` gets to call `check`.
