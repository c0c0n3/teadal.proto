package httpbin.service

import data.authnz.oidc as oidc


jeejees_token := token {
    payload := {
        "email": "jeejee@teadal.eu",
        "exp": 10000000000  # 20 Nov 2286 @ 18:46:40 (CET)
    }
    token := oidc.generate_tasty_token(payload)
}
jeejees_auth := oidc.make_bearer_auth(jeejees_token)

sebs_token := token {
    payload := {
        "email": "sebs@teadal.eu",
        "exp": 10000000000  # 20 Nov 2286 @ 18:46:40 (CET)
    }
    token := oidc.generate_tasty_token(payload)
}
sebs_auth := oidc.make_bearer_auth(sebs_token)

oidc_config := {
   "jwt_user_field_name": "email",
   "jwks": oidc.jwks_tasty_config
}

make_request(method, path, auth) := envoy_input {
    envoy_input := {
        "attributes": {
            "request": {
                "http": {
                    "headers": {
                        "authorization": auth
                    },
                    "method": method,
                    "path": path
                }
            }
        }
    }
}

assert_user_can_do_anything_on_path(path, user_auth) {
    allow with input as make_request("GET", path, user_auth)
          with data.config.oidc as oidc_config
    allow with input as make_request("HEAD", path, user_auth)
          with data.config.oidc as oidc_config
    allow with input as make_request("OPTIONS", path, user_auth)
          with data.config.oidc as oidc_config
    allow with input as make_request("PUT", path, user_auth)
          with data.config.oidc as oidc_config
    allow with input as make_request("POST", path, user_auth)
          with data.config.oidc as oidc_config
    allow with input as make_request("PATCH", path, user_auth)
          with data.config.oidc as oidc_config
    allow with input as make_request("DELETE", path, user_auth)
          with data.config.oidc as oidc_config
    allow with input as make_request("CONNECT", path, user_auth)
          with data.config.oidc as oidc_config
    allow with input as make_request("TRACE", path, user_auth)
          with data.config.oidc as oidc_config
}

assert_user_can_only_read_path(path, user_auth) {
    allow with input as make_request("GET", path, user_auth)
          with data.config.oidc as oidc_config
    allow with input as make_request("HEAD", path, user_auth)
          with data.config.oidc as oidc_config
    allow with input as make_request("OPTIONS", path, user_auth)
          with data.config.oidc as oidc_config
    not allow with input as make_request("PUT", path, user_auth)
              with data.config.oidc as oidc_config
    not allow with input as make_request("POST", path, user_auth)
              with data.config.oidc as oidc_config
    not allow with input as make_request("PATCH", path, user_auth)
              with data.config.oidc as oidc_config
    not allow with input as make_request("DELETE", path, user_auth)
              with data.config.oidc as oidc_config
    not allow with input as make_request("CONNECT", path, user_auth)
              with data.config.oidc as oidc_config
    not allow with input as make_request("TRACE", path, user_auth)
              with data.config.oidc as oidc_config
}

test_check_perms {
    assert_user_can_do_anything_on_path("/httpbin/anything/", jeejees_auth)
    assert_user_can_only_read_path("/httpbin/anything/", sebs_auth)
    assert_user_can_only_read_path("/httpbin/get", jeejees_auth)
    assert_user_can_only_read_path("/httpbin/get", sebs_auth)
}
