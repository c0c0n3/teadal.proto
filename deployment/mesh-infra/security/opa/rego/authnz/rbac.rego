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
user_roles(rbac_db, user) := [] if {
    not rbac_db.user_to_roles[user]
}
user_roles(rbac_db, user) := roles if {
    roles := rbac_db.user_to_roles[user]
}

# Find all the permissions associated with the given role.
role_perms(rbac_db, role) := perms if {
    perms := rbac_db.role_to_perms[role]
}

# Find all the permissions associated with the given user. This is,
# the set of all permissions associated with the user, via roles, in
# the RBAC DB.
#
# In detail, we can think of the `role_to_perms` map in the RBAC DB as
# a function sending a role `r` to a set of permissions `P(r)`, so
# `role_to_perms(r) = P(r)`. Likewise, there's a function `R` sending
# each user `u` to the roles they belong to. Then the set of all perms
# associated with a given user `u` is `U P(r)` with `r ∈ R(u)`. For
# instance, say user `u1` belongs to roles `r1` and `r2`, so
# `R(u1) = { r1, r2 }`, and each role has the following permissions:
# `P(r1) = { p1, p2 }, P(r2) = { p2, p3, p4 }`. Among other users,
# roles and perms, there's also user `u2` with roles `R(u2) = { r2, r3 }`
# and `r3`'s perms are `R(r3) = { p5 }`. Picture the situation as a
# directed graph:
#
#                      u1     u2     ...
#      R ↓            ↙  ↘   ↙  ↘           __.
#                   r1    r2     r3  ...      |
#      P ↓         ↙ ↘  ↙ ↙ ↘    ↓            |___ role_to_perms
#                 p1  p2 p3  p4  p5  ...      |
#                                           __|
#
# Then the set of permissions associated with `u1` is the set of perm
# nodes you can reach from `u1`, that is `{ p1, p2, p3, p4 }`, whereas
# `u2`'s perms are: `{ p2, p3, p4, p5 }`.
#
# Notice we consider a user the same as a singleton role. That is, we
# identify each user `u` with a role named `u` and having just `u` as
# a member. In other words, for each user `u`, `u ∈ R(u)`. This way you
# can assign permissions directly to a user `u` in the `role_to_perms`
# map without having to also explicitly list `u` as a role for user `u`
# in the `user_to_roles` map. For example, while you can write
#
#   role_to_perms := {
#     "joe@some.edu": [
#       { "methods": ["GET"], "url_regex": "^/stuff/.*" }
#     ]
#   }
#   user_to_roles := {
#     "joe@some.edu": [ "joe@some.edu" ]
#   }
#
# you can also omit the `user_to_roles` map in this case since user
# "joe@some.edu" gets automatically associated to role "joe@some.edu"
# anyway.
#
# Params
# - rbad_db. The RBAC database.
# - user. The user making the HTTP request to check.
# - external_roles. Must be an array (never undefined!) holding the
#   names of any roles the user may have been assigned in an external
#   system and that are referenced in the RBAC DB permission definitions.
#   If the array isn't empty, then the contained labels will be added to
#   the roles found in the RBAC DB for the given user.
#
user_perms(rbac_db, user, external_roles) := perms if {
    all_roles := array.concat(user_roles(rbac_db, user), external_roles)
    all_roles_with_user := array.concat(all_roles, [user])
    perms := { ps |
        role := all_roles_with_user[_]
        role_perms := rbac_db.role_to_perms[role]
        ps := role_perms[_]
    }
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
check(rbac_db, user, external_roles, request) if {
    perm := user_perms(rbac_db, user, external_roles)[_]
    perm.methods[_] == request.method
    regex.match(perm.url_regex, request.path)
}
