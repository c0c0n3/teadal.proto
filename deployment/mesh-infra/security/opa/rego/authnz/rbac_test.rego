package authnz.rbac

import data.authnz.http as http
import data.authnz.rbacdb as rbac_db


test_role_lookup {
    user_roles(rbac_db, "jeejee") == { "product_owner", "product_consumer" }
    user_roles(rbac_db, "sebs") == { "product_consumer" }
}

test_role_perms {
    role_perms(rbac_db, "product_owner") == {
        {
            "methods": http.do_anything,
            "url_regex": "^/httpbin/anything/.*"
        }
    }
    role_perms(rbac_db, "product_consumer") == {
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

test_user_perms {
    user_perms(rbac_db, "jeejee") == {
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
    user_perms(rbac_db, "sebs") == {
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

assert_user_can_do_anything_on_path(user, path) {
    check(rbac_db, user, {"method": "GET", "path": path})
    check(rbac_db, user, {"method": "HEAD", "path": path})
    check(rbac_db, user, {"method": "OPTIONS", "path": path})
    check(rbac_db, user, {"method": "PUT", "path": path})
    check(rbac_db, user, {"method": "POST", "path": path})
    check(rbac_db, user, {"method": "PATCH", "path": path})
    check(rbac_db, user, {"method": "DELETE", "path": path})
    check(rbac_db, user, {"method": "CONNECT", "path": path})
    check(rbac_db, user, {"method": "TRACE", "path": path})
}

assert_user_can_only_read_path(user, path) {
    check(rbac_db, user, {"method": "GET", "path": path})
    check(rbac_db, user, {"method": "HEAD", "path": path})
    check(rbac_db, user, {"method": "OPTIONS", "path": path})
    not check(rbac_db, user, {"method": "PUT", "path": path})
    not check(rbac_db, user, {"method": "POST", "path": path})
    not check(rbac_db, user, {"method": "PATCH", "path": path})
    not check(rbac_db, user, {"method": "DELETE", "path": path})
    not check(rbac_db, user, {"method": "CONNECT", "path": path})
    not check(rbac_db, user, {"method": "TRACE", "path": path})
}

test_check_perms {
    assert_user_can_do_anything_on_path("jeejee", "/httpbin/anything/")
    assert_user_can_only_read_path("sebs", "/httpbin/anything/")
    assert_user_can_only_read_path("jeejee", "/httpbin/get")
    assert_user_can_only_read_path("sebs", "/httpbin/get")
}
