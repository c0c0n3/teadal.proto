#
# Functionality to verify JWT tokens and extract their payload.
# Most likely the only function you'll ever need out of the ones
# below is `claims`.
#
# Verification doesn't require any key sharing and/or config as, for
# each token, we automatically discover, download and cache token
# issuer's JWKs. But you can override this behaviour by providing a
# config object with your own JWKs as explained in the config test.
#

package authnz.oidc


# Verify the JWT token and extract its payload. Expect the token to be
# in the "Authorization" header as a "Bearer" token. Depending on config,
# either automatically download issuer keys and cache them for a day or
# use statically configured JWKs. Then use them to verify the token as
# explained in `token_payload`.
#
# Params
# - request. An object containing the HTTP request headers in an object
#   map called `headers`. Typically, when using the OPA Envoy plugin, you'd
#   pass in `input.attributes.request.http` for the request param.
# - config. An object containing `authnz` config---see the config test
#   for explanations.
claims(request, config) := payload {
    config.jwks
    token := bearer_token(request)
    payload := token_payload(token, config.jwks)
}
claims(request, config) := payload {
    not config.jwks
    token := bearer_token(request)
    [_, p, _] := io.jwt.decode(token)
    jwks := token_jwks(p, config.jwks_preferred_urls)
    payload := token_payload(token, jwks)
}

# Verify a JWT token and extract its payload. (At the moment we can only
# verify RSA or ECDSA-signed tokens---algos: RS256, RS384, RS512, ES256,
# ES384, ES512, PS256, PS384 and PS512.)
# Check all of the statements below are true:
#
# * the header contains a public key ID `k` and `k` is also the ID of
#   one of the keys in the token issuer's JWKs;
# * `k`'s corresponding private key was used to sign the token and the
# * token signature is valid;
# * there's an `exp` field in the payload holding a valid date `d` and
#   `d` is in the future;
# * if there's an `nbf` field in the payload, it has a valid date in
#   the past.
#
# Notice the first three checks are critical to stop attacks exploiting
# algo header field vulnerabilities:
# - https://www.chosenplaintext.ca/2015/03/31/jwt-algorithm-confusion.html
#
# Params
# - token. The JWT token to verify and extract the payload from.
# - jwks. The key set containing the key the issuer makes available to
#   verify the token signature. Notice this is a Rego object holding the JWKs
#   JSON data, typically retrieved from a URL discovered through the issuer's
#   well-known OIDC config endpoint.
token_payload(token, jwks) := payload {
    # Call `decode_verify` to extract token data and verify its signature.
    # Convert the Rego `jwks` object back to a JSON string. (Weirdly enough,
    # `decode_verify` won't work with the Rego object.)
    # Notice `cert` supports RS256, RS384, RS512, ES256, ES384, ES512, PS256,
    # PS384 and PS512 but not HS256, HS384, and HS512 for which you'd have
    # to use the `secret` field instead.
    [valid, header, payload] := io.jwt.decode_verify(token, {
        "cert": json.marshal(jwks)
    })

    # Assert `valid` is `true`.
    valid

    # Make sure the header contains a key ID and there exist a key in
    # `jwks` with the same ID. If this is true, then we can be sure the
    # Rego implementation has picked that key for verification:
    # - https://github.com/open-policy-agent/opa/blob/v0.53.1/topdown/tokens.go#L348
    # - https://github.com/open-policy-agent/opa/blob/v0.53.1/topdown/tokens.go#L382
    jwks.keys[_].kid = header.kid

    # Assert there's an `exp` field in the payload.
    # If true, then `decode_verify` must've checked `exp`'s value is a date
    # in the future. We need this since if `exp` isn't there, `decode_verify`
    # sets `valid` to `true`.
    payload.exp

    # `decode_verify` checks `nbf` is in the past, if present.
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
token_issuer_config_url(token_payload) = url {
    not endswith(token_payload.iss, "/")
    config_path := ".well-known/openid-configuration"
    url := concat("/", [token_payload.iss, config_path])
}

# Use `token_payload.iss` as a base URL to build the well-known OIDC
# config URL.
token_issuer_config_url(token_payload) = url {
    endswith(token_payload.iss, "/")
    config_path := ".well-known/openid-configuration"
    url := concat("", [token_payload.iss, config_path])
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
