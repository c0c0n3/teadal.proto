package authnz.rbac

import data.authnz.http as http
import data.authnz.rbacdb as rbac_db
import data.authnz.rbacdb_ext as ext_rbac_db


test_role_lookup if {
    user_roles(rbac_db, "jeejee") == [ "product_owner", "product_consumer" ]
    user_roles(rbac_db, "sebs") == [ "product_consumer" ]
}

test_role_lookup_when_no_user_to_roles_map if {
    user_roles({}, "jeejee") == []
}

test_role_lookup_when_user_not_in_user_to_roles_map if {
    user_roles(rbac_db, "im-not-there") == []
}

test_role_perms if {
    role_perms(rbac_db, "product_owner") == [
        {
            "methods": http.do_anything,
            "url_regex": "^/httpbin/anything/.*"
        }
    ]
    role_perms(rbac_db, "product_consumer") == [
        {
            "methods": http.read,
            "url_regex": "^/httpbin/anything/.*"
        },
        {
            "methods": http.read,
            "url_regex": "^/httpbin/get$"
        }
    ]
    role_perms(rbac_db, "external_role") == [
        {
            "methods": http.read,
            "url_regex": "^/httpbin/X"
        }
    ]
}

test_user_perms if {
    user_perms(rbac_db, "jeejee", []) == {
        {
            "methods": http.do_anything,
            "url_regex": "^/httpbin/anything/.*"
        },
        {
            "methods": http.read,
            "url_regex": "^/httpbin/anything/.*"
        },
        {
            "methods": http.read,
            "url_regex": "^/httpbin/get$"
        }
    }
    user_perms(rbac_db, "sebs", []) == {
        {
            "methods": http.read,
            "url_regex": "^/httpbin/anything/.*"
        },
        {
            "methods": http.read,
            "url_regex": "^/httpbin/get$"
        }
    }
    user_perms(rbac_db, "not-there", []) ==
        { 1 | 1 == 0 }
    #   ^ empty set; sadly, {} is an empty object to Rego!
}

test_user_perms_with_external_role if {
    user_perms(rbac_db, "sebs", ["external_role"]) == {
        {
            "methods": http.read,
            "url_regex": "^/httpbin/anything/.*"
        },
        {
            "methods": http.read,
            "url_regex": "^/httpbin/get$"
        },
        {
            "methods": http.read,
            "url_regex": "^/httpbin/X"
        }
    }
    user_perms(rbac_db, "not-there", ["external_role"]) == {
        {
            "methods": http.read,
            "url_regex": "^/httpbin/X"
        }
    }
}

test_user_perms_with_ext_role_defs if {
    # NOTE user = "". The user is irrelevant in this scenario since
    # we've got no user-to-roles map, the JWT holds the roles for the
    # user at hand.
    user_perms(ext_rbac_db, "", ["product_owner", "product_consumer"]) == {
        {
            "methods": http.do_anything,
            "url_regex": "^/httpbin/anything/.*"
        },
        {
            "methods": http.read,
            "url_regex": "^/httpbin/anything/.*"
        },
        {
            "methods": http.read,
            "url_regex": "^/httpbin/get$"
        }
    }
    user_perms(ext_rbac_db, "", ["product_consumer"]) == {
        {
            "methods": http.read,
            "url_regex": "^/httpbin/anything/.*"
        },
        {
            "methods": http.read,
            "url_regex": "^/httpbin/get$"
        }
    }
    user_perms(ext_rbac_db, "", ["sebs"]) == {
        {
            "methods": http.read,
            "url_regex": "^/httpbin/ip$"
        }
    }
    user_perms(ext_rbac_db, "", []) ==
        { 1 | 1 == 0 }
    #   ^ empty set; sadly, {} is an empty object to Rego!
}

assert_user_can_do_anything_on_path(user, path) if {
    check(rbac_db, user, [], {"method": "GET", "path": path})
    check(rbac_db, user, [], {"method": "HEAD", "path": path})
    check(rbac_db, user, [], {"method": "OPTIONS", "path": path})
    check(rbac_db, user, [], {"method": "PUT", "path": path})
    check(rbac_db, user, [], {"method": "POST", "path": path})
    check(rbac_db, user, [], {"method": "PATCH", "path": path})
    check(rbac_db, user, [], {"method": "DELETE", "path": path})
    check(rbac_db, user, [], {"method": "CONNECT", "path": path})
    check(rbac_db, user, [], {"method": "TRACE", "path": path})
}

assert_user_can_only_read_path(user, path) if {
    check(rbac_db, user, [], {"method": "GET", "path": path})
    check(rbac_db, user, [], {"method": "HEAD", "path": path})
    check(rbac_db, user, [], {"method": "OPTIONS", "path": path})
    not check(rbac_db, user, [], {"method": "PUT", "path": path})
    not check(rbac_db, user, [], {"method": "POST", "path": path})
    not check(rbac_db, user, [], {"method": "PATCH", "path": path})
    not check(rbac_db, user, [], {"method": "DELETE", "path": path})
    not check(rbac_db, user, [], {"method": "CONNECT", "path": path})
    not check(rbac_db, user, [], {"method": "TRACE", "path": path})
}

test_check_perms if {
    assert_user_can_do_anything_on_path("jeejee", "/httpbin/anything/")
    assert_user_can_only_read_path("sebs", "/httpbin/anything/")
    assert_user_can_only_read_path("jeejee", "/httpbin/get")
    assert_user_can_only_read_path("sebs", "/httpbin/get")
}

assert_user_can_read_path_ext_db(user, roles, path) if {
    check(ext_rbac_db, user, roles, {"method": "GET", "path": path})
}

test_check_perms_ext_db if {
    assert_user_can_read_path_ext_db("sebs", [], "/httpbin/ip")
    assert_user_can_read_path_ext_db(
        "sebs", ["product_consumer"], "/httpbin/ip")
    not assert_user_can_read_path_ext_db("sebs", [], "/httpbin/get")
    assert_user_can_read_path_ext_db(
        "sebs", ["product_consumer"], "/httpbin/get")
}
