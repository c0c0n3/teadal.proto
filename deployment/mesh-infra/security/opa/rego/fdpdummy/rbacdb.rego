#
# Example RBAC DB.
# Replace with yours or import is as an external data bundle---e.g.
# by making OPA download a tarball from a Web server or by linking
# it from a local disk.
#

package fdpdummy.rbacdb

import data.authnz.http as http


# Role defs.
product_owner := "product_owner"
product_consumer := "product_consumer"

# Map each role to a list of permission objects.
# Each permission object specifies a set of allowed HTTP methods for
# the Web resources identified by the URLs matching the given regex.
role_to_perms := {
    product_owner: [
        {
            "methods": http.do_anything,
            "url_regex": "^/fdp/.*"
        }
    ],
    product_consumer: [
        {
            "methods": http.read,
            "url_regex": "^/fdp/patients/age"
        }
    ]
}

# Map each user to their roles.
user_to_roles := {
    "jeejee@teadal.eu": [ product_owner, product_consumer ],
    "sebs@teadal.eu": [ product_consumer ]
}
