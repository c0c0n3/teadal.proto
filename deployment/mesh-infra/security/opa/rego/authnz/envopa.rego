#
# TODO
#

package authnz.envopa

import input.attributes.request.http as http_request
import data.authnz.oidc as oidc
import data.authnz.rbac as rbac


# TODO move out of this package. Ideally authnz should be generic..
jwks_preferred_urls := {
    "http://localhost": "http://keycloak:8080/keycloak/realms/master/protocol/openid-connect/certs"
}

allow(rbac_db) := user {
    payload := oidc.claims(http_request, jwks_preferred_urls)
    user := payload.sub  # TODO make expected user field an input param
    rbac.check(rbac_db, user, http_request)
}
