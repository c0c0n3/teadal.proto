package authnz.http

test_read_set if {
    read == { "GET", "HEAD", "OPTIONS" }
}

test_write_set if {
    write == { "PUT", "PATCH", "POST", "DELETE" }
}

test_read_n_write_set if {
    read_n_write ==
        { "GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE" }
}

test_do_anything_set if {
    do_anything ==
        { "GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE",
          "TRACE", "CONNECT" }
}
