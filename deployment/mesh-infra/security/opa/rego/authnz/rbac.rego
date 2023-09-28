#
# Functions to query and evaluate RBAC REST policies.
#
# All the functions below take a RBAC DB and a user as input. The RBAC DB
# must be in the format specified in RBAC DB test. The user is a username
# string which may or may not be one of the usernames defined in the RBAC
# DB.
#

package authnz.rbac


# Find all the roles associated to the given user.
user_roles(rbac_db, user) := roles {
    roles := rbac_db.user_to_roles[user]
}

# Find all the permissions associated the the given role.
role_perms(rbac_db, role) := perms {
    perms := rbac_db.role_to_perms[role]
}

# Find all the permissions associated the the given user.
# TODO. broken at the mo. See test_user_perms:
#   eval_conflict_error:
#     functions must not produce multiple outputs for same inputs
user_perms(rbac_db, user) := perms {
    role := user_roles(rbac_db, user)[_]
    perms := role_perms(rbac_db, role)[_]
}

# Check the given user is allowed to carry out the requested operation
# (HTTP method) on the target resource.
#
# The request param must be an object containing `method` and `path`
# fields. `method` is the HTTP request method whereas `path` is the
# HTTP request path. Typically, when using the OPA Envoy plugin, you'd
# pass in `input.attributes.request.http` for the request param.
check(rbac_db, user, request) {
    role := rbac_db.user_to_roles[user][_]
    perm := rbac_db.role_to_perms[role][_]
    perm.methods[_] == request.method
    regex.match(perm.url_regex, request.path)
}
