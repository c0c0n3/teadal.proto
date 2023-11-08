#
# Placeholder policy for HttpBin.
#

package httpbin.service

import input.attributes.request.http as http_request
import data.authnz.envopa as envopa
import data.config.oidc as oidc_config
import data.httpbin.rbacdb as rbac_db


default allow := false

allow = true {
    user := envopa.allow(rbac_db, oidc_config)

    # Put below this line any service-specific checks on e.g. http_request

}

allow = true {
    regex.match("^/httpbin/image.*", http_request.path)
}
