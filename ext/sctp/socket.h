#ifndef SCTP_SOCKET_INCLUDED
#define SCTP_SOCKET_INCLUDED

#include <ruby.h>
#include <netinet/sctp.h>

void Init_socket();
void Init_server();
void Init_client();

extern VALUE mSCTP;
extern VALUE cSocket;
extern VALUE cClient;
extern VALUE cServer;

#endif
