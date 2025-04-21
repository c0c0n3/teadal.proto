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
    "monitor": [  # monitor role defined in the IdM
        {
            "methods": http.read,
            "url_regex": "^/httpbin/ip$"
        }
    ],
    # No one except for user "sebs@teadal.eu" should be able to GET
    # UUIDs. But there's no UUID reader role in the IdM and we don't
    # want to create one just for "sebs@teadal.eu". So we use RBAC
    # implicit roles to define this perm just for role "sebs@teadal.eu".
    # (With implicit roles each user gets automatically associated
    # with a role having the same name as the user and that contains
    # only that user as its member.)
    "sebs@teadal.eu": [
        {
            "methods": http.read,
            "url_regex": "^/httpbin/uuid$"
        }
    ]
    # Implicit roles also come in handy when you want to make an
    # exception to the rule (or role, rather :-) for a specific
    # user. For example, say we'd also like user "sebs@teadal.eu"
    # to be able to get the IP address. But "sebs@teadal.eu" isn't
    # a member of monitor and he shouldn't be since policies for
    # other services could use that role to grant an access level
    # "sebs@teadal.eu" shouldn't have. So we use implicit roles to
    # define an extra perm just for role "sebs@teadal.eu" as in the
    # example below.
    # "sebs@teadal.eu": [
    #     {
    #         "methods": http.read,
    #         "url_regex": "^/httpbin/ip$"
    #     }
    # ]
}

# Map each user to their roles.
# We don't need to include user-role mappings already defined in the
# IdM. For example, jeejee is also a member of `monitor` in the IdM.
# IdM mappings get extracted from the access token and automatically
# merged in.
# Also, there's no need to add a role "sebs@teadal.eu" for "sebs@teadal.eu",
# since, with implicit roles,
#   "sebs@teadal.eu": [ product_consumer ]
# is the same as
#   "sebs@teadal.eu": [ product_consumer, "sebs@teadal.eu" ]
user_to_roles := {
    "jeejee@teadal.eu": [ product_owner, product_consumer ],
    "sebs@teadal.eu": [ product_consumer ]
}
