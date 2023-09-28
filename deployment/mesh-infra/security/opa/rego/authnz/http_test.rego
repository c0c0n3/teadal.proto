package authnz.http

test_read_set {
    read == { "GET", "HEAD", "OPTIONS" }
}

test_write_set {
    write == { "PUT", "PATCH", "POST", "DELETE" }
}

test_read_n_write_set {
    read_n_write ==
        { "GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE" }
}

test_do_anything_set {
    do_anything ==
        { "GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE",
          "TRACE", "CONNECT" }
}
