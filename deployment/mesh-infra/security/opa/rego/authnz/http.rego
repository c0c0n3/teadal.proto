#
# Rules for defining RBAC REST policies.
#

package authnz.http


# HTTP methods to use for policy definitions.
get := "GET"
head := "HEAD"
options := "OPTIONS"
put := "PUT"
patch := "PATCH"
post := "POST"
delete := "DELETE"
trace := "TRACE"
connect := "CONNECT"

# Common HTTP method sets used for permission assignment.
read := { get, head, options }
write := { put, patch, post, delete }
read_n_write := read | write
do_anything := read_n_write | { trace, connect }
