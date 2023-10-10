#
# Placeholder policy for MinIO.
#

package minio.service

import input.attributes.request.http as http_request


default allow := false

allow = true {
    regex.match("^/minio/.*", http_request.path)
}
