package authnz.oidc


test_preferred_token_jwks_url_1 {
    want := "http://keycloak/realms/master/protocol/openid-connect/certs"
    token_payload := {"iss": "http://localhost/keycloak/realms/master"}
    url_lookup := {
        "http://localhost": want
    }
    got := preferred_token_jwks_url(token_payload, url_lookup)
    got == want
}

test_preferred_token_jwks_url_2 {
    want := "http://oi.dc/certs"
    token_payload := {"iss": "http://localhost:8080"}
    url_lookup := {
        "http://localhost:8080": want
    }
    got := preferred_token_jwks_url(token_payload, url_lookup)
    got == want
}

test_preferred_token_jwks_url_3 {
    want := "http://oi.dc/certs"
    token_payload := {"iss": "http://localhost:8080/"}
    url_lookup := {
        "http://localhost:8080": want
    }
    got := preferred_token_jwks_url(token_payload, url_lookup)
    got == want
}

test_preferred_token_jwks_url_4 {
    want := "http://oi.dc/certs"
    token_payload := {"iss": "http://localhost:8080/p/q?v=1"}
    url_lookup := {
        "http://localhost:8080": want
    }
    got := preferred_token_jwks_url(token_payload, url_lookup)
    got == want
}

test_token_issuer_config_url_1 {
    want := "https://key.cloak/realms/master/.well-known/openid-configuration"
    token_payload := {"iss": "https://key.cloak/realms/master"}
    got := token_issuer_config_url(token_payload)
    got == want
}

test_token_issuer_config_url_2 {
    want := "https://key.cloak/realms/master/.well-known/openid-configuration"
    token_payload := {"iss": "https://key.cloak/realms/master/"}
    got := token_issuer_config_url(token_payload)
    got == want
    # TODO fix double slash
    # got: https://key.cloak/realms/master//.well-known/openid-configuration
}

# NOTE. This test needs the Teadal VM running on localhost.
test_token_jwks_preferred_url {
    token_payload := {"iss": "http://localhost/keycloak/realms/master"}
    url_lookup := {
        "http://localhost": "http://localhost/keycloak/realms/master/protocol/openid-connect/certs"
    }
    jwks := token_jwks(token_payload, url_lookup)
    jwks.keys  # assert present
}

# NOTE. This test needs the Teadal VM running on localhost.
test_token_jwks_canonical_url {
    token_payload := {"iss": "http://localhost/keycloak/realms/master"}
    url_lookup := { }
    jwks := token_jwks(token_payload, url_lookup)
    jwks.keys  # assert present
}

# TODO test token_payload and claims functions