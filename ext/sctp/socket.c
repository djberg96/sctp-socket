#include "ruby.h"
#include <netinet/sctp.h>

void Init_socket(){
  VALUE mSCTP, cSocket, cClient, cServer;

  mSCTP   = rb_define_module("SCTP");
  cSocket = rb_define_class_under(mSCTP, "Socket", rb_cObject);
  cClient = rb_define_class_under(cSocket, "Client", rb_cObject);
  cServer = rb_define_class_under(cSocket, "Server", rb_cObject);
}
