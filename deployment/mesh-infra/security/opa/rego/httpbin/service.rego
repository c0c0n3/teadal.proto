#
# Placeholder policy for HttpBin.
#

package httpbin.service

import input.attributes.request.http as http_request
import data.authnz.envopa as envopa
import data.config.oidc as config
import data.httpbin.rbacdb as rbac_db


default allow := false

allow = true {
    user := envopa.allow(rbac_db,
                         config.jwt_user_field_name,
                         config.jwks_preferred_urls)

    # Put below this line any service-specific checks on e.g. http_request

}
