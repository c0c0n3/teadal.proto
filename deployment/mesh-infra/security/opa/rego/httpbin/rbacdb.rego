#
# Example RBAC DB.
# Replace with yours or import is as an external data bundle---e.g.
# by making OPA download a tarball from a Web server or by linking
# it from a local disk.
#

package httpbin.rbacdb

import data.authnz.http as http


# Role defs. There's also a `monitor` group we reference below which
# is defined in the IdM.
product_owner := "product_owner"
product_consumer := "product_consumer"

# Map each role to a list of permission objects.
# Each permission object specifies a set of allowed HTTP methods for
# the Web resources identified by the URLs matching the given regex.
role_to_perms := {
    product_owner: [
        {
            "methods": http.do_anything,
            "url_regex": "^/httpbin/anything/.*"
        }
    ],
    product_consumer: [
        {
            "methods": http.read,
            "url_regex": "^/httpbin/anything/.*"
        },
        {
            "methods": http.read,
            "url_regex": "^/httpbin/get$"
        }
    ],
    "monitor": [
        {
            "methods": http.read,
            "url_regex": "^/httpbin/ip$"
        }
    ]
}

# Map each user to their roles.
# We don't need to include user-role mappings already defined in the
# IdM. For example, jeejee is also a member of `monitor` in the IdM.
# IdM mappings get extracted from the access token and automatically
# merged in.
user_to_roles := {
    "jeejee@teadal.eu": [ product_owner, product_consumer ],
    "sebs@teadal.eu": [ product_consumer ]
}
