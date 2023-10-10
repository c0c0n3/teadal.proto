#
# TODO docs
#

package authnz.envopa

import input.attributes.request.http as http_request
import data.authnz.oidc as oidc
import data.authnz.rbac as rbac


allow(rbac_db, config) := user {
    payload := oidc.claims(http_request, config)
    user := payload[config.jwt_user_field_name]
    rbac.check(rbac_db, user, http_request)
}
