#include <sctp/socket.h>

VALUE cClient;

void Init_client(){
  cClient = rb_define_class_under(cSocket, "Client", rb_cObject);
}
