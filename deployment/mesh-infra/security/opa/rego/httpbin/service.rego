#
# Placeholder policy for HttpBin.
#

package httpbin.service

import input.attributes.request.http as http_request


default allow := false

allow = true {
    regex.match("^/httpbin/.*", http_request.path)
}
