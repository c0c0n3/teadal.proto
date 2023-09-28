#
# TODO docs
#

package authnz.oidc


# Verify the JWT token and extract its payload. Expect the token to be
# in the "Authorization" header as a "Bearer" token. Check all of the
# statements below are true:
#
# * the algo in the header is the same that was used to sign the token;
# * the token signature is valid;
# * there's an `exp` field in the payload holding a valid date `d`;
# * `d` is in the future.
#
# Plus, if there's an `nbf` field in the payload, check it has a valid
# date in the past.
#
# Automatically download issuer keys and cache them for a day.
# If `jwks_preferred_urls` has a key equal to the token issuer's base
# URL (scheme and authority, e.g. http://my.host), use the correspondig
# URL value to download the JWKS object. For instance, if
#   jwt.payload.iss = https://keycloak.external/realms/master
#   jwks_preferred_urls["https://keycloak.external"] =
#       http://kc.internal/realms/master/protocol/openid-connect/certs
# then use this ^ URL to download the JWKS.
# Otherwise, use the issuer's OIDC well-known config to find out where
# to download the JWKS from.
# Notice the `jwks_preferred_urls` can be useful if you want to test
# with `localhost` or if you want to call your own issuer using an
# internal cluster address.
#
# Params
# - request. An object containing the HTTP request headers in an object
#   map called `headers`. Typically, when using the OPA Envoy plugin, you'd
#   pass in `input.attributes.request.http` for the request param.
# - jwks_preferred_urls. An map (object) where each key is an issuer URL
#   and the key's corresponding value is the absolute URL where the issuer
#   makes the JWKS object available for download. The key URL must contain
#   only the scheme and authority---e.g. http://my.host, http://my.host:8080.
claims(request, jwks_preferred_urls) := payload {
    token := bearer_token(request)
    [_, p, _] := io.jwt.decode(token)
    jwks := token_jwks(p, jwks_preferred_urls)
    payload := token_payload(token, jwks)
}

# Verify the JWT token and extract its payload. Check all of the
# statements below are true:
#
# * the algo in the header is the same that was used to sign the token;
# * the token signature is valid;
# * there's an `exp` field in the payload holding a valid date `d`;
# * `d` is in the future.
#
# Plus, if there's an `nbf` field in the payload, check it has a valid
# date in the past.
#
# Params
# - token. The JWT token to verify and extract the payload from.
# - jwks. The key set containing the key the issuer makes available to
#   verify the token signature. This is a JWKS JSON object typically
#   retrieved from a URL discovered through the issuer's well-known
#   OIDC config endpoint.
token_payload(token, jwks) := payload {
    [h, _, _] := io.jwt.decode(token)
    [valid, header, payload] := io.jwt.decode_verify(token, {
        "alg": h.alg,
        "cert": jwks
    })

    # Assert `valid` is `true`.
    valid

    # Assert there's an `exp` field in the payload.
    # If true, then `decode_verify` must've checked `exp`'s value is a date
    # in the future. We need this since if `exp` isn't there, `decode_verify`
    # sets `valid` to `true`.
    payload.exp
}

# Extract the Bearer token from the HTTP request if present, otherwise
# set it to `undefined`.
# The request param must be an object containing the HTTP request headers
# in an object map called `headers`. Typically, when using the OPA Envoy
# plugin, you'd pass in `input.attributes.request.http` for the request
# param.
bearer_token(request) := token {
    auth := request.headers.authorization
    startswith(auth, "Bearer ")
    token := substring(auth, count("Bearer "), -1)
}

# Fetch the token issuer's keys used to sign JWTs.
# If there's a preferred URL configured for the token issuer, use that
# URL to download the JWKS object containing the keys.
# Expect the `token_payload` param to contain the standard `iss` claim
# with the token issuer's URL. If the `url_lookup` params has a key equal
# to that URL's base (scheme and authority, e.g. http://my.host:8080),
# use the correspondig URL value to download the JWKS object. For instance,
# if
#   token_payload.iss = https://keycloak.external/realms/master
#   url_lookup["https://keycloak.external"] =
#       http://kc.internal/realms/master/protocol/openid-connect/certs
# then use this ^ URL to download the JWKS.
token_jwks(token_payload, url_lookup) = jwks {
    url := preferred_token_jwks_url(token_payload, url_lookup)
    print("Downloading JWKS for: ", token_payload.iss,
          " from preferred JWKS URL: ", url)
    jwks := fetch_token_jwks(url)
}

# Fetch the token issuer's keys for JWT validation.
# If there's no preferred URL configured in `url_lookup`, then use the
# issuer's OIDC well-known config to find out where to download the JWKS
# from.
token_jwks(token_payload, url_lookup) = jwks {
    not preferred_token_jwks_url(token_payload, url_lookup)

    print("Fetching JWKS for: ", token_payload.iss,
          ", using JWKS URL from well-known OIDC config")
    well_known_oidc_url := token_issuer_config_url(token_payload)
    url := fetch_token_issuer_jwks_url(well_known_oidc_url)
    print("JWKS URL: ", url)

    jwks := fetch_token_jwks(url)
}

# Extract scheme and authority from `token_payload` and use it as a
# key to look up the preferred JWKS download URL in the `url_lookup`
# map.
preferred_token_jwks_url(token_payload, url_lookup) := url {
    base_url := regex.find_n("^[^:]+://[^/]+", token_payload.iss, 1)[_]
    url := url_lookup[base_url]
}

# Use `token_payload.iss` as a base URL to build the well-known OIDC
# config URL.
token_issuer_config_url(token_payload) := url {
    config_path := ".well-known/openid-configuration"
    url := concat("/", [token_payload.iss, config_path])
}

# Fetch the token issuer's absolute URL where the issuer makes token
# validation keys available.
# Retrieve the issuer's well-known OIDC config first, then return the
# `jwks_uri` field of that config object. Cache the config for a day.
# The `well_known_oidc_url` param is the absolute URL of the issuer's
# well-known OIDC config endpoint, e.g.
# https://my.keycloak/realms/master/.well-known/openid-configuration
fetch_token_issuer_jwks_url(well_known_oidc_url) := url {
    response := http.send(
        {
            "url": well_known_oidc_url,
            "method": "GET",
            "force_cache": true,
            "force_cache_duration_seconds": 86400
        }
    )
    url := response.body.jwks_uri
}

# Fetch the keys the token issuer makes available to verify tokens.
# Cache them for one day.
# The `url` param is the absolute URL of the issuer's JWKS endpoint, e.g.
# https://my.keycloak/realms/master/protocol/openid-connect/certs.
fetch_token_jwks(url) := jwks {
    response := http.send(
        {
            "url": url,
            "method": "GET",
            "force_cache": true,
            "force_cache_duration_seconds": 86400
        }
    )
    jwks := response.body
}
