#
# Test RBAC DB.
#

package authnz.rbacdb

import data.authnz.http as http


# Role defs.
product_owner := "product_owner"
product_consumer := "product_consumer"

# Map each role to a set of permission objects.
# Each permission object specifies a set of allowed HTTP methods for
# the Web resources identitified by the URLs matching the given regex.
role_to_perms := {
    product_owner: {
        {
            "methods": http.do_anything,
            "url_regex": "^/httpbin/anything/.*"
        }
    },
    product_consumer: {
        {
            "methods": http.read,
            "url_regex": "^/httpbin/anything/.*"
        },
        {
            "methods": http.read,
            "url_regex": "^/httpbin/get$"
        }
    }
}

# Map each user to their roles.
user_to_roles := {
    "jeejee": { product_owner, product_consumer },
    "sebs": { product_consumer }
}
