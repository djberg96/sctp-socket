#ifndef SCTP_SOCKET_INCLUDED
#define SCTP_SOCKET_INCLUDED

#include <ruby.h>
#include <netinet/sctp.h>

VALUE rb_hash_aref2(VALUE, const char*);

void Init_socket();

extern VALUE mSCTP;
extern VALUE cSocket;

#endif
