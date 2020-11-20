#include "ruby.h"
#include <string.h>
#include <errno.h>
#include <arpa/inet.h>
#include <netinet/sctp.h>

VALUE mSCTP;
VALUE cSocket;

static VALUE rsctp_init(int argc, VALUE* argv, VALUE self){
  int sock_fd;
  VALUE v_domain, v_type;

  rb_scan_args(argc, argv, "02", &v_domain, &v_type);

  if(NIL_P(v_domain))
    v_domain = INT2NUM(AF_INET);
  
  if(NIL_P(v_type))
    v_type = INT2NUM(SOCK_SEQPACKET);

  sock_fd = socket(NUM2INT(v_domain), NUM2INT(v_type), IPPROTO_SCTP);

  if(sock_fd < 0)
    rb_raise(rb_eSystemCallError, "socket: %s", strerror(errno));

  rb_iv_set(self, "@domain", v_domain);
  rb_iv_set(self, "@type", v_type);
  rb_iv_set(self, "@sock_fd", INT2NUM(sock_fd));
  rb_iv_set(self, "@association_id", INT2NUM(0));

  return self;
}

static VALUE rsctp_bindx(int argc, VALUE* argv, VALUE self){
  int i, sock_fd, num_ip;
  VALUE v_addresses, v_port, v_family;
  VALUE v_address;
  struct sockaddr_in addrs[8];

  bzero(&addrs, sizeof(addrs));

  rb_scan_args(argc, argv, "12", &v_addresses, &v_port, &v_family);

  if(NIL_P(v_port))
    v_port = INT2NUM(0);

  if(NIL_P(v_family))
    v_family = INT2NUM(AF_INET);

  num_ip = RARRAY_LEN(v_addresses);

  for(i = 0; i < num_ip; i++){
    v_address = RARRAY_PTR(v_addresses)[i];
    addrs[i].sin_family = NUM2INT(v_family);
    addrs[i].sin_port = htons(NUM2INT(v_port));
    addrs[i].sin_addr.s_addr = inet_addr(StringValueCStr(v_address));
  }

  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));

  if(sctp_bindx(sock_fd, (struct sockaddr *) addrs, num_ip, SCTP_BINDX_ADD_ADDR) != 0)
    rb_raise(rb_eSystemCallError, "sctp_bindx: %s", strerror(errno));

  return self;
}

static VALUE rsctp_connectx(VALUE self, VALUE v_addresses){
  struct sockaddr_in addrs[8];
  int i, num_ip, sock_fd;
  sctp_assoc_t assoc;
  VALUE v_address;

  num_ip = RARRAY_LEN(v_addresses);
  bzero(&addrs, sizeof(addrs));

  for(i = 0; i < num_ip; i++){
    v_address = RARRAY_PTR(v_addresses)[i];
    addrs[i].sin_family = NUM2INT(rb_iv_get(self, "@v_family"));
    addrs[i].sin_port = 0; // TODO: should this be set?
    addrs[i].sin_addr.s_addr = inet_addr(StringValueCStr(v_address));
  }

  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));

  if(sctp_connectx(sock_fd, (struct sockaddr *) addrs, num_ip, &assoc) < 0)
    rb_raise(rb_eSystemCallError, "sctp_connectx: %s", strerror(errno));

  rb_iv_set(self, "@assocation_id", INT2NUM(assoc));

  return self;
}

static VALUE rsctp_close(VALUE self){
  VALUE v_sock_fd = rb_iv_get(self, "@sock_fd");

  if(close(NUM2INT(v_sock_fd)))
    rb_raise(rb_eSystemCallError, "close: %s", strerror(errno));

  return self;
}

static VALUE rsctp_getpeernames(VALUE self){
  VALUE v_assoc_id = rb_iv_get(self, "@assocation_id"); 
  sctp_assoc_t assoc_id;
  struct sockaddr* addrs;
  int i, sock_fd, num_addrs;

  bzero(&addrs, sizeof(addrs));

  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));
  assoc_id = NUM2INT(v_assoc_id);

  num_addrs = sctp_getpaddrs(sock_fd, assoc_id, &addrs);

  if(num_addrs < 0){
    sctp_freepaddrs(addrs);
    rb_raise(rb_eSystemCallError, "sctp_getpaddrs: %s", strerror(errno));
  }

  for(i = 0; i < num_addrs; i++){
    // TODO: Create and return array of IpAddr objects
  }

  sctp_freepaddrs(addrs);

  return self;
}

static VALUE rsctp_getlocalnames(VALUE self){
  sctp_assoc_t assoc_id;
  struct sockaddr* addrs;
  int i, sock_fd, num_addrs;

  bzero(&addrs, sizeof(addrs));

  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));
  assoc_id = NUM2INT(rb_iv_get(self, "@assocation_id"));

  num_addrs = sctp_getladdrs(sock_fd, assoc_id, &addrs);

  if(num_addrs < 0){
    sctp_freeladdrs(addrs);
    rb_raise(rb_eSystemCallError, "sctp_getladdrs: %s", strerror(errno));
  }

  for(i = 0; i < num_addrs; i++){
    // TODO: Create and return array of IpAddr objects
  }

  sctp_freeladdrs(addrs);

  return self;
}

void Init_socket(){
  mSCTP   = rb_define_module("SCTP");
  cSocket = rb_define_class_under(mSCTP, "Socket", rb_cObject);

  rb_define_method(cSocket, "initialize", rsctp_init, -1);

  rb_define_method(cSocket, "bindx", rsctp_bindx, -1);
  rb_define_method(cSocket, "close", rsctp_close, 0);
  rb_define_method(cSocket, "connectx", rsctp_connectx, 0);
  rb_define_method(cSocket, "getpeernames", rsctp_getpeernames, 0);
  rb_define_method(cSocket, "getlocalnames", rsctp_getlocalnames, 0);

  rb_define_attr(cSocket, "domain", 1, 1);
  rb_define_attr(cSocket, "type", 1, 1);
  rb_define_attr(cSocket, "sock_fd", 1, 1);
  rb_define_attr(cSocket, "association_id", 1, 1);
}
