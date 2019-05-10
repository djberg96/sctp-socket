#include <sctp/socket.h>

VALUE cServer;

void Init_server(){
  cServer = rb_define_class_under(cSocket, "Server", rb_cObject);
}
