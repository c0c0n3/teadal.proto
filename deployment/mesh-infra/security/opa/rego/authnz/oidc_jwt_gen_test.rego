#
# Test utils to generate JWTs.
#

package authnz.oidc


# RSA keys and JWKs generated on https://mkjwk.org/
# using the parameters below
#
#   Key Size         = 2048
#   Key Use          = Signature
#   Algorithm        = RS256: RSASSA-PKCS1-v1_5 using SHA-256
#   Key ID - Specify = k1
#   Show X.509       = Yes

rsa_pub_key_jwk := {
    "kty": "RSA",
    "e": "AQAB",
    "use": "sig",
    "kid": "k1",
    "alg": "RS256",
    "n": "rFdk9QnnPyQXhPgmHXtF7WupI3aCj-2YVprjEPkra-fPtxKRBjEC0AlDi7BhYilZzcpB2MGKAjzUvfKp7YFwAw7fp6M0fHKRyMtGDCzuu0bv6LX4uLFqLeft8UyjYX1Al3LVmX4VmRxVy88BxFh5H85WMtAOy3JPLYVpf6XZ7fOFEkNyzLY2hYklfsnbvG8ZJyNgAOTSx_33wOv8680NBme44lbCP3007sQGoFXpApsQZPbM1ug6AwDAQejGNVEq-EuGLmkjSEBlbKReUonoigqyRX-39qFIMrflkEYMahIewWQKUxwFFaR8BLPteRL072BZgqqIBgWG6XDyyONj9Q"
}

rsa_key_pair_jwk := {
    "p": "8ybS9TowEW0Y0xHpGBm7LGLoc5u8IF-EkuTFdFZ4DchkeFL1M0ditEJEUV7OlKWErxwRGWo6bA7rLmNA8URZZl_SlSYgWcDeKwHwGqrMXgTydzflYxRmS8azenSoXkiDxFE2Y5psq-6mXmlNYlimV0b7jIylgUUtRX1DAzI42fc",
    "kty": "RSA",
    "q": "tXKzhk6uYZoL8bkpVrp0xouyhWhgdAcXN5vDlx98aojbD4DkFj4Zd7_Utl9s5HWYEMJPvMTiYUDaJdkeSDBrmA4OH_4QS5R1DqVvBBMq3JJXvVzaZox7ysWXPeEnNXcYFK_qhtnFHN-ztTWk-WmcWaU-nfgg5WEwfrlRyLTD1nM",
    "d": "M01swzjoerZOvgl0pzAMF-oFloXvxdKPl7BRybqyv1NpVPEU9MfgM3eegNXHl4YBsq3zvgeXAqWDGuxCw23Vn0NtNqTxud4NIb3JI1S42Ez8m8SXvrsphXLWNQ-AT0QO10aa6S9MVKDHtXzw5LcFj39Hz6Z50Pw9L6rYReRkJF3sKJDv9mUjT9unobgHlnc99HQ-XB9r2md0WwdZI6COXAMT32Fgb9ZhBrq8VyhRiZLje7zmiPqYaB5XQKq6mJLhq26yvZ0leQw7DGVZ0Ot9FpdQky3_T80zhXxYi1-6-dttVhdlRGFsAjjXLPtbWhVTObDDKlcfzC7PWZkJhhO7_Q",
    "e": "AQAB",
    "use": "sig",
    "kid": "k1",
    "qi": "L2QvQX9uB1anD09Ai0ANKhAeWkRbFKRBBLSaCmV9ZteQeHuG_HUEdZp5NSzg0B4yySLsgT37-1Yc0PZNHWDWltIi7PlwpSiTuDpXRHHQlZOwfLKnu40JtJWgIw8e_yFga5SfcoUuv727GAiONQYXhIKDb1PkpXzEvwQQuoDidVc",
    "dp": "h7acunj-yUsuNujhRC1gdjbCbXx39U267k44E2YL3g2CXlJXP4bRhbES9qPHA9qagy5UMO5Eq3lsNNj7L26pw2UqYUsFdXMbzb9oJ0o7hSKXvoj5RGLncdX26RthujYZLaLyi4durkwmmb2GjqTSOxaIYntCCTP2P7nZhFgsuSM",
    "alg": "RS256",
    "dq": "pVCx3AZHvskZZMysq0YKKvMQXZfxeQUU1CdoloGrW20BGSj3poRBs-blKJvcnHG_cFV5TKWdE7qAhsdAXckv3kO__sn9kr7Zv9ReRzonbPswUWkN2yzXhLFt0IUYsg-lswNsDBzRCDOQieMsQclFGDAD0u1FG3fnNS4nI1P-sZ0",
    "n": "rFdk9QnnPyQXhPgmHXtF7WupI3aCj-2YVprjEPkra-fPtxKRBjEC0AlDi7BhYilZzcpB2MGKAjzUvfKp7YFwAw7fp6M0fHKRyMtGDCzuu0bv6LX4uLFqLeft8UyjYX1Al3LVmX4VmRxVy88BxFh5H85WMtAOy3JPLYVpf6XZ7fOFEkNyzLY2hYklfsnbvG8ZJyNgAOTSx_33wOv8680NBme44lbCP3007sQGoFXpApsQZPbM1ug6AwDAQejGNVEq-EuGLmkjSEBlbKReUonoigqyRX-39qFIMrflkEYMahIewWQKUxwFFaR8BLPteRL072BZgqqIBgWG6XDyyONj9Q"
}

jwks_tasty_config := {
    "keys": [
        rsa_pub_key_jwk
        # ^ notice Rego will blow up if you use rsa_key_pair_jwk instead.
        # See: https://github.com/open-policy-agent/opa/issues/6283
        # In practice this isn't an issue b/c the issuer will never include
        # the private key in its well-known JWKs. It's just annoying for
        # testing as we need to generate an extra object.
    ]
}


generate_tasty_token(payload) := jwt if {
    header := {
        "alg": "RS256",
        "kid": "k1",
        "typ": "JWT"
    }
    jwt := io.jwt.encode_sign(header, payload, rsa_key_pair_jwk)
}

make_bearer_auth(jwt) := auth if {
    auth := sprintf("Bearer %s", [jwt])
}
