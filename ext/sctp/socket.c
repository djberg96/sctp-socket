#include "ruby.h"
#include <netinet/sctp.h>

VALUE mSCTP;
VALUE cSocket;

void Init_socket(){
  mSCTP   = rb_define_module("SCTP");
  cSocket = rb_define_class_under(mSCTP, "Socket", rb_cObject);
}
