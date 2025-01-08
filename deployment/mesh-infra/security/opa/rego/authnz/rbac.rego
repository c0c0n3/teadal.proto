#
# Functions to query and evaluate RBAC REST policies.
#
# All the functions below take a RBAC DB and a user as input. The RBAC DB
# must be in the format specified in RBAC DB test. The user is a username
# string which may or may not be one of the usernames defined in the RBAC
# DB.
#

package authnz.rbac


# Find all the roles associated with the given user in the RBAC DB.
# Return an empty list if there's no `user_to_roles` map or the map
# has no entry for the given user.
user_roles(rbac_db, user) := [] {
    not rbac_db.user_to_roles[user]
}
user_roles(rbac_db, user) := roles {
    rbac_db.user_to_roles
    roles := rbac_db.user_to_roles[user]
}

# Find all the permissions associated with the given role.
role_perms(rbac_db, role) := perms {
    perms := rbac_db.role_to_perms[role]
}

# Find all the permissions associated with the given user.
user_perms(rbac_db, user) := perms {
    roles := user_roles(rbac_db, user)
    perm_sets := { rbac_db.role_to_perms[k] | roles[k] }
    perms := union(perm_sets)
}

# Check the given user is allowed to carry out the requested operation
# (HTTP method) on the target resource.
#
# The request param must be an object containing `method` and `path`
# fields. `method` is the HTTP request method whereas `path` is the
# HTTP request path. Typically, when using the OPA Envoy plugin, you'd
# pass in `input.attributes.request.http` for the request param.
#
# The external roles param must be an array (never undefined!) holding
# the names of any roles the user may have been assigned in an external
# system and that are referenced in the RBAC DB permission definitions.
# If the array isn't empty, then the contained labels will be added to
# the roles found in the RBAC DB for the given user.
#
check(rbac_db, user, external_roles, request) {
    all_roles := array.concat(user_roles(rbac_db, user), external_roles)
    role := all_roles[_]
    perm := rbac_db.role_to_perms[role][_]
    perm.methods[_] == request.method
    regex.match(perm.url_regex, request.path)
}
