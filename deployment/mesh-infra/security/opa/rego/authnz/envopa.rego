#
# TODO docs
#

package authnz.envopa

import input.attributes.request.http as http_request
import data.authnz.oidc as oidc
import data.authnz.rbac as rbac


allow(rbac_db, jwt_user_field_name, jwks_preferred_urls) := user {
    payload := oidc.claims(http_request, jwks_preferred_urls)
    user := payload[jwt_user_field_name]
    rbac.check(rbac_db, user, http_request)
}
