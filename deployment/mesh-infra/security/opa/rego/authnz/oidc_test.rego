package authnz.oidc


test_preferred_token_jwks_url_1 if {
    want := "http://keycloak/realms/master/protocol/openid-connect/certs"
    token_payload := {"iss": "http://localhost/keycloak/realms/master"}
    url_lookup := {
        "http://localhost": want
    }
    got := preferred_token_jwks_url(token_payload, url_lookup)
    got == want
}

test_preferred_token_jwks_url_2 if {
    want := "http://oi.dc/certs"
    token_payload := {"iss": "http://localhost:8080"}
    url_lookup := {
        "http://localhost:8080": want
    }
    got := preferred_token_jwks_url(token_payload, url_lookup)
    got == want
}

test_preferred_token_jwks_url_3 if {
    want := "http://oi.dc/certs"
    token_payload := {"iss": "http://localhost:8080/"}
    url_lookup := {
        "http://localhost:8080": want
    }
    got := preferred_token_jwks_url(token_payload, url_lookup)
    got == want
}

test_preferred_token_jwks_url_4 if {
    want := "http://oi.dc/certs"
    token_payload := {"iss": "http://localhost:8080/p/q?v=1"}
    url_lookup := {
        "http://localhost:8080": want
    }
    got := preferred_token_jwks_url(token_payload, url_lookup)
    got == want
}

test_token_issuer_config_url_1 if {
    want := "https://key.cloak/realms/master/.well-known/openid-configuration"
    token_payload := {"iss": "https://key.cloak/realms/master"}
    got := token_issuer_config_url(token_payload)
    got == want
}

test_token_issuer_config_url_2 if {
    want := "https://key.cloak/realms/master/.well-known/openid-configuration"
    token_payload := {"iss": "https://key.cloak/realms/master/"}
    got := token_issuer_config_url(token_payload)
    got == want
}

test_token_jwks_preferred_url if {
    token_payload := {"iss": "http://localhost/keycloak/realms/master"}
    url_lookup := {
        "http://localhost": "http://localhost/keycloak/realms/master/protocol/openid-connect/certs"
    }
    jwks := token_jwks(token_payload, url_lookup)
            with data.authnz.oidc.fetch_token_jwks as jwks_tasty_config
    jwks.keys  # assert present
}

test_token_jwks_canonical_url if {
    token_payload := {"iss": "http://localhost/keycloak/realms/master"}
    url_lookup := { }
    jwks := token_jwks(token_payload, url_lookup)
            with data.authnz.oidc.fetch_token_issuer_jwks_url as "mock"
            with data.authnz.oidc.fetch_token_jwks as jwks_tasty_config
    jwks.keys  # assert present
}

test_extract_bearer_token if {
    dummy_jwt := "header.payload.signature"
    request := {
        "headers": {
            "authorization": make_bearer_auth(dummy_jwt)
        }
    }
    bearer_token(request) == dummy_jwt
}

test_extract_token_payload_with_valid_jwt if {
    payload := {
        "sub": "vans",
        "nbf": 3600,        # 1hr since the epoc
        "exp": 10000000000  # 20 Nov 2286 @ 18:46:40 (CET)
    }
    token := generate_tasty_token(payload)
    payload == token_payload(token, jwks_tasty_config)
}

test_extract_token_payload_with_expired_jwt if {
    payload := {
        "sub": "vans",
        "nbf": 3600,        # 1hr since the epoc
        "exp": 3600         # 1hr since the epoc
    }
    token := generate_tasty_token(payload)
    not token_payload(token, jwks_tasty_config)
}

test_extract_token_payload_with_nbf_in_the_future if {
    payload := {
        "sub": "vans",
        "nbf": 10000000000, # 20 Nov 2286 @ 18:46:40 (CET)
        "exp": 10000000000  # 20 Nov 2286 @ 18:46:40 (CET)
    }
    token := generate_tasty_token(payload)
    not token_payload(token, jwks_tasty_config)
}

test_claims_with_static_jwks if {
    config := {
        "jwks": jwks_tasty_config
    }
    payload := {
        "iss": "me",
        "exp": 10000000000  # 20 Nov 2286 @ 18:46:40 (CET)
    }
    token := generate_tasty_token(payload)
    request := {
        "headers": {
            "authorization": make_bearer_auth(token)
        }
    }
    payload == claims(request, config)
}

test_claims_with_dynamic_jwks if {
    config := {
        "jwks_preferred_urls": {
            "http://mock": "http://mock/jwks"
        }
    }
    payload := {
        "iss": "http://mock",
        "exp": 10000000000  # 20 Nov 2286 @ 18:46:40 (CET)
    }
    token := generate_tasty_token(payload)
    request := {
        "headers": {
            "authorization": make_bearer_auth(token)
        }
    }
    extracted_payload := claims(request, config)
                         with data.authnz.oidc.fetch_token_jwks as jwks_tasty_config

    payload == extracted_payload
}
