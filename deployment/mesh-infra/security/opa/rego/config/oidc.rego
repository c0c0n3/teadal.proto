package config.oidc

# TODO explain this!

internal_keycloak_jwks_url := "http://keycloak:8080/keycloak/realms/master/protocol/openid-connect/certs"

jwks_preferred_urls := {
    "http://localhost": internal_keycloak_jwks_url,
    "https://localhost": internal_keycloak_jwks_url
}

jwt_user_field_name := "email"
