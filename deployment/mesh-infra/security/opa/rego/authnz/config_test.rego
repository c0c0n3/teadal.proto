#
# Example config to tweak `authnz` behaviour.
#

package authnz.config

#
# The name of the JWT field containing the user handle. You set this value
# to tell `authnz` which token payload field contains the user handle. The
# user handle should uniquely identify the user with the token issuer.
#
# Typically with Keycloak, you'd use one of `sub`, `preferred_username`
# or `email`. For instance, here's a payload snippet from a token Keycloak
# issued to a user named `sebs` having an email of `sebs@teadal.eu`:
#
#    {
#        "iss": "http://localhost/keycloak/realms/master",
#        "sub": "152f391c-8d9c-4c7c-a67b-924956d8892c",
#        "preferred_username": "sebs",
#        "email": "sebs@teadal.eu",
#        ...
#    }
#
# Notice the `sub` and (hopefully) `email` fields are globally unique,
# whereas `preferred_username` is only unique within a Keycloak instance.
# So when doing identity federation, ideally you'd use either `sub` or
# `email`.
#
# Keep in mind the user handle is also the string you must use in your
# RBAC DB to refer to users. `authnz` looks up RBAC users by that handle,
# so it's important you use the same value known to Keycloak in your RBAC
# DB. For instance, if you set `jwt_user_field_name` to `email`, then
# you'd refer to `sebs` in your RBAC DB by his email:
#
#     user_to_roles := {
#         "sebs@teadal.eu": [ product_consumer ],
#         ...
#     }
#
jwt_user_field_name := "email"

#
# The name of the JWT field containing a list of role names. You set
# this value to tell `authnz` which token payload field contains the
# list of role names you'd like to use for authorisation checks. These
# are additional roles defined in the IdM that issues the JWT and which
# the IdM associates users with. Notice that `authnz` expects this field
# to be an array, so you've got to configure your IdM accordingly.
#
# Instead of defining roles and user-to-role mappings in your RBAC DB,
# you could define roles and user-to-role mappings in your IdM and then
# just reference those roles in the role-to-perms map in your RBAC DB.
# `authnz` collects these role labels from the JWT and associates them
# to the user specified in the JWT. This way you won't have to provide
# your own `user_to_roles` map in the RBAC DB. (Or better, you could,
# in which case `authnz` will merge all the roles found in `user_to_roles`
# for the given user with those listed in the JWT array having the name
# `jwt_roles_field_name`.)
#
# Notice you should set the `jwt_roles_field_name` variable to an empty
# string or zap it to make `authnz` only use the roles and user-to-role
# mappings defined in your RBAC DB.
#
# The easiest, but less flexible, way of using JWT roles with Keycloak
# is to define a group for each role you want to use and then add users
# to groups. There's a built-in mapper you can use to output an array
# containing the groups a user is a member of in a JWT field of your
# choice. For instance, here's a payload snippet from a token Keycloak
# issued to a user named `sebs` having an email of `sebs@teadal.eu` and
# who's a member of the `g1` and `g2` groups:
#
#    {
#        "iss": "http://localhost/keycloak/realms/master",
#        "sub": "152f391c-8d9c-4c7c-a67b-924956d8892c",
#        "preferred_username": "sebs",
#        "email": "sebs@teadal.eu",
#        "roles": ["g1", "g2"],
#        ...
#    }
#
# NOTE
# ----
# To reproduce the above config in Keycloak:
#
# $ docker run \
#     -p 8080:8080 \
#     -e KC_HTTP_ENABLED=true -e KC_HOSTNAME_STRICT=false \
#     -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=abc123 \
#     quay.io/keycloak/keycloak:21.1.2 \
#     start
#
# Then log in as `admin` to:
# 1. Create groups `g1` and `g2`.
# 2. Create user `sebs`, member of above groups and w/ (non-temp)
#    password `abc123`.
# 3. Edit built-in `profile` client scope to add a "Group Membership"
#    mapper whose "Token Claim Name" is `roles`, taking care to turn
#    on the "Add to access token" option.
#    See:
#    - https://stackoverflow.com/questions/76919561
#    - https://i.sstatic.net/8wjyX.png
#
# Finally get an access token for `sebs`
#
# $ curl -s \
#     http://localhost:8080/realms/master/protocol/openid-connect/token \
#     -d 'grant_type=password' -d 'client_id=admin-cli' \
#     -d 'username=sebs' -d 'password=abc123' | jq -r '.access_token'
#
jwt_roles_field_name := "roles"

#
# Preferred URLs to retrieve issuer JWKs. A map (object) where each key
# is an issuer URL and the key's corresponding value is the absolute URL
# where the issuer makes its JWKs available for download. The key's URL
# must contain only scheme and authority, not the path---e.g. http://my.host,
# http://my.host:8080.
#
# `authnz` can dynamically verify token signatures by automatically
# discovering, downloading and caching token issuer's JWKs. In fact,
# OIDC caters for that: if you append `/.well-known/openid-configuration`
# to the token issuer's URL (`iss` field), you get the URL where to
# download the issuer's OIDC config. In turn, that config contains a
# `jwks_uri` field with the URL where to download the keys the issuer
# makes available to verify token signatures.
#
# There are cases where you'd like to use a different URL to download
# the issuer's keys rather than the one `jwks_uri` specifies. Typically
# your IdM (e.g. Keycloak) and OPA both run inside your K8s cluster and
# external clients access your IdM using your cluster externally visible
# domain name through which you route external traffic to internal pods.
# Say your Keycloak is available to external clients at
# - https://idm.my.cloud/
# and to pods inside the cluster at
# - https://keycloak:8080/
# Now when Keycloak issues an external client with a JWT, the `iss`
# field will contain the externally visible domain name, e.g.
#
#     {
#         "iss": "https://idm.my.cloud/realms/master",
#         ...
#     }
#
# On seeing this token, `authnz`, as explained earlier, first downloads
# the OIDC config from
# - https://idm.my.cloud/realms/master/.well-known/openid-configuration
# and then follows the `jwks_uri` in it, which in our example would be
# - https://idm.my.cloud/realms/master/protocol/openid-connect/certs
# Notice how, given these URLs, OPA, which runs inside the cluster, has
# to make HTTP calls that get routed outside the cluster and then back
# in to reach the internal Keycloak pod at https://keycloak:8080/.
#
# Wouldn't it be more efficient to use the Keycloak internal URL to
# download the JWKs? The `jwks_preferred_urls` map lets you do that.
# If `jwks_preferred_urls` has a key equal to the token issuer's base
# URL (scheme and authority, e.g. http://my.host), `authnz` uses the
# corresponding URL value to download the JWKs. For instance, if
#
# jwks_preferred_urls := {
#     "https://idm.my.cloud":
#         "https://keycloak:8080/realms/master/protocol/openid-connect/certs",
#     ...
# }
#
# and a JWT comes in with an issuer of
# - https://idm.my.cloud/realms/master
# then `authnz` will download the JWKs from
# - https://keycloak:8080/realms/master/protocol/openid-connect/certs
# instead of
# - https://idm.my.cloud/realms/master/protocol/openid-connect/certs
#
# If there's no key in `jwks_preferred_urls` that matches the issuer's
# base URL, then `authnz` uses the issuer's OIDC well-known config to
# find out where to download the JWKs from.
#
jwks_preferred_urls := {
# Here's another example where `jwks_preferred_urls` comes in handy.
# Say you're testing your K8s cluster in a VM running on your box and
# the VM is connected to your loopback interface (localhost). You use
# path-based routing to access K8s services and your IdM is at
# - http://localhost/idm
# When you get a token from the above URL, the issuer field is
# - http://localhost/idm/issuer
# This will never work with our `authnz` lib, because `authnz` tries
# downloading the OIDC config from
# - http://localhost/idm/issuer/.well-known/openid-configuration
# but `localhost` resolves to OPA's pod!
# To fix this, we explicitly set a preferred JWKs URL pointing to
# the internal pod running our IdM
# - http://idm.prod.svc.cluster.local/jwks
#
    "http://localhost": "http://idm.prod.svc.cluster.local/jwks",
    "https://localhost": "http://idm.prod.svc.cluster.local/jwks"
}

#
# Static JWKs config. A Rego object representation of a JWKs.
#
# As mentioned earlier, by default `authnz` doesn't require any key
# sharing and/or config to verify token signatures as, for each token
# that comes in, it automatically discovers, downloads and caches token
# issuer's JWKs. But you can override this behaviour by providing a
# `jwks` config object with your own JWKs data.
#
# If the `jwks` is defined, `authnz` will use the given JWKs for
# **all** incoming tokens and never make HTTP calls to discover
# and fetch OIDC config.
#
jwks := {
    "keys": [
        {
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
    ]
}


#
# Same as above but defined as an object rather than a package.
#

example_config := {
    "jwks_preferred_urls": {
        "http://localhost": "http://authnz/openid-connect/certs",
        "https://localhost": "http://authnz/openid-connect/certs"
    },
    "jwt_user_field_name": "sub",
    "jwt_roles_field_name": "roles",
    "jwks": {
        "keys": [
            {
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
        ]
    }
}
