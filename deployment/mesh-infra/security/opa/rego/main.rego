#
# Policy decision entry point.
# Delegate decisions to policies relevant for the request at hand.
#
# NOTE OPA hook. The OPA service is configured to evaluate the
# `allow` expression in this package---i.e. `data.teadal.allow`,
# see `opa-envoy-plugin.yaml`. If you rename this package or the
# allow rule below, you'll have to change the pod config in
# `opa-envoy-plugin.yaml` accordingly.
#
package teadal

import data.httpbin.service as httpbin
import data.minio.service as minio


default allow := false

allow {
    httpbin.allow
}

# or

allow {
    minio.allow
}

# NOTE. These two policies are mutually exclusive. In fact, the
# httpbin policy denies access if request path doesn't start with
# "/httpbin/". Likewise the minio policy denies access if the path
# doesn't start with "/minio/". As a result, the httpbin policy gets
# to decide how to protect resources under the "/httpbin/" path whereas
# the minio policy decides about resources under "/minio/".
