#
# Test RBAC DB.
#
# This test DB is for the scenario where users and roles are defined
# in an external IdM. Usually you'd define only users in the IdM and
# roles plus user-to-roles map in the RBAC DB. But you can also define
# roles in the IdM and map user to roles in the IdM too. In this case,
# the JWT contains both the user and their roles, so the RBAC DB only
# needs to associate permissions to those external roles defined in
# the IdM.
#

package authnz.rbacdb_ext

import data.authnz.http as http


# Map each external role to a set of permission objects.
# Each permission object specifies a set of allowed HTTP methods for
# the Web resources identified by the URLs matching the given regex.
role_to_perms := {
    "product_owner": [
        {
            "methods": http.do_anything,
            "url_regex": "^/httpbin/anything/.*"
        }
    ],
    "product_consumer": [
        {
            "methods": http.read,
            "url_regex": "^/httpbin/anything/.*"
        },
        {
            "methods": http.read,
            "url_regex": "^/httpbin/get$"
        }
    ],
    # We'd also like user "sebs" to be able to get the IP address.
    # So we use implicit roles to define an extra perm just for role
    # "sebs". (With implicit roles each user gets automatically
    # associated with a role having the same name as the user and
    # that contains only that user as its member.)
    "sebs": [
        {
            "methods": http.read,
            "url_regex": "^/httpbin/ip$"
        }
    ]
}
