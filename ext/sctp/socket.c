#include "ruby.h"
#include <string.h>
#include <errno.h>
#include <arpa/inet.h>
#include <netinet/sctp.h>

VALUE mSCTP;
VALUE cSocket;

VALUE rb_hash_aref2(VALUE v_hash, const char* key){
  VALUE v_key, v_val;

  v_key = rb_str_new2(key);
  v_val = rb_hash_aref(v_hash, v_key);

  if(NIL_P(v_val))
    v_val = rb_hash_aref(v_hash, ID2SYM(rb_intern(key)));

  return v_val;
}

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

static VALUE rsctp_connectx(VALUE self, VALUE v_port, VALUE v_addresses){
  struct sockaddr_in addrs[8];
  int i, num_ip, sock_fd;
  sctp_assoc_t assoc;
  VALUE v_address;

  num_ip = RARRAY_LEN(v_addresses);
  bzero(&addrs, sizeof(addrs));

  for(i = 0; i < num_ip; i++){
    v_address = RARRAY_PTR(v_addresses)[i];
    addrs[i].sin_family = NUM2INT(rb_iv_get(self, "@v_family"));
    addrs[i].sin_port = NUM2INT(v_port);
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

/*
 *  socket.connectx
 *  socket.sendmsgx(message, stream_number, flags, time_to_live, ppid, context)
 */
static VALUE rsctp_sendmsgx(int argc, VALUE* argv, VALUE self){
  VALUE v_msg, v_ppid, v_flags, v_stream, v_ttl, v_context;
  uint16_t stream;
  uint32_t ppid, flags, timetolive, context;
  ssize_t num_bytes;
  int sock_fd;

  rb_scan_args(argc, argv, "15", &v_msg, &v_stream, &v_flags, &v_ttl, &v_ppid, &v_context);

  if(NIL_P(v_stream))
    stream = 0;
  else
    stream = NUM2INT(v_stream);

  if(NIL_P(v_flags))
    flags = 0;
  else
    flags = NUM2INT(v_stream);

  if(NIL_P(v_ttl))
    timetolive = 0;
  else
    timetolive = NUM2INT(v_ttl);

  if(NIL_P(v_ppid))
    ppid = 0;
  else
    ppid = NUM2INT(v_ppid);

  if(NIL_P(v_context))
    context = 0;
  else
    context = NUM2INT(v_context);

  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));

  num_bytes = sctp_sendmsg(
    sock_fd,
    StringValueCStr(v_msg),
    RSTRING_LEN(v_msg),
    NULL,
    0,
    ppid,
    flags,
    stream,
    timetolive,
    context
  );

  if(num_bytes < 0)
    rb_raise(rb_eSystemCallError, "sctp_sendmsg: %s", strerror(errno));

  return INT2NUM(num_bytes);
}

static VALUE rsctp_recvmsgx(int argc, VALUE* argv, VALUE self){
  VALUE v_flags;
  struct sctp_sndrcvinfo sndrcvinfo;
  struct sockaddr_in clientaddr;
  int flags, bytes, sock_fd;
  char buffer[1024]; // TODO: Let this be configurable?
  socklen_t length;

  rb_scan_args(argc, argv, "01", &v_flags);

  if(NIL_P(v_flags))
    flags = 0;
  else
    flags = NUM2INT(v_flags);  

  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));
  length = sizeof(struct sockaddr_in);

  bytes = sctp_recvmsg(
    sock_fd,
    buffer,
    sizeof(buffer),
    (struct sockaddr*)&clientaddr,
    &length,
    &sndrcvinfo,
    &flags
  );

  if(bytes < 0)
    rb_raise(rb_eSystemCallError, "sctp_recvmsg: %s", strerror(errno));

  // TODO: Return a struct with clienaddr info, plus buffer.
  return rb_str_new2(buffer);
}

/*
 *  {
 *    :output_streams => 2,
 *    :input_streams  => 3,
 *    :max_attempts   => 5,
 *    :timeout        => 30
 *  }
 */
static VALUE rsctp_set_initmsg(VALUE self, VALUE v_options){
  int sock_fd;
  struct sctp_initmsg initmsg;
  VALUE v_output, v_input, v_attempts, v_timeout;

  bzero(&initmsg, sizeof(initmsg));

  v_output   = rb_hash_aref2(v_options, "output_streams");
  v_input    = rb_hash_aref2(v_options, "input_streams");
  v_attempts = rb_hash_aref2(v_options, "max_attempts");
  v_timeout  = rb_hash_aref2(v_options, "timeout");

  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));

  if(!NIL_P(v_output))
    initmsg.sinit_num_ostreams = NUM2INT(v_output);

  if(!NIL_P(v_input))
    initmsg.sinit_max_instreams = NUM2INT(v_input);

  if(!NIL_P(v_attempts))
    initmsg.sinit_max_attempts = NUM2INT(v_attempts);

  if(!NIL_P(v_timeout))
    initmsg.sinit_max_init_timeo = NUM2INT(v_timeout);

  if(setsockopt(sock_fd, IPPROTO_SCTP, SCTP_INITMSG, &initmsg, sizeof(initmsg)) < 0)
    rb_raise(rb_eSystemCallError, "setsockopt: %s", strerror(errno));

  return self;
}

/*
 * {
 *   :data_io => true,
 *   :association => true,
 *   :address => true,
 *   :send_failure => true,
 *   :peer_error => true,
 *   :shutdown => true,
 *   :partial_delivery => true,
 *   :adaptation_layer => true,
 *   :authentication_event => true,
 *   :sender_dry => true
 * }
 *
 */
static VALUE rsctp_subscribe(VALUE self, VALUE v_options){
  int sock_fd;
  struct sctp_event_subscribe events;

  bzero(&events, sizeof(events));
  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));

  if(RTEST(rb_hash_aref2(v_options, "data_io")))
    events.sctp_data_io_event = 1;

  if(RTEST(rb_hash_aref2(v_options, "association")))
    events.sctp_association_event = 1;

  if(RTEST(rb_hash_aref2(v_options, "address")))
    events.sctp_address_event = 1;

  if(RTEST(rb_hash_aref2(v_options, "send_failure")))
    events.sctp_send_failure_event = 1;

  if(RTEST(rb_hash_aref2(v_options, "peer_error")))
    events.sctp_peer_error_event = 1;

  if(RTEST(rb_hash_aref2(v_options, "shutdown")))
    events.sctp_shutdown_event = 1;

  if(RTEST(rb_hash_aref2(v_options, "partial_delivery")))
    events.sctp_partial_delivery_event = 1;

  if(RTEST(rb_hash_aref2(v_options, "adaptation_layer")))
    events.sctp_adaptation_layer_event = 1;

  if(RTEST(rb_hash_aref2(v_options, "authentication")))
    events.sctp_authentication_event = 1;

  if(RTEST(rb_hash_aref2(v_options, "sender_dry")))
    events.sctp_sender_dry_event = 1;

  if(setsockopt(sock_fd, IPPROTO_SCTP, SCTP_EVENTS, &events, sizeof(events)) < 0)
    rb_raise(rb_eSystemCallError, "setsockopt: %s", strerror(errno));

  return self;
}

static VALUE rsctp_listen(int argc, VALUE* argv, VALUE self){
  VALUE v_backlog;
  int backlog, sock_fd;

  rb_scan_args(argc, argv, "01", &v_backlog);

  if(NIL_P(v_backlog))
    backlog = 1024;
  else
    backlog = NUM2INT(v_backlog);

  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));

  if(listen(sock_fd, backlog) < 0)
    rb_raise(rb_eSystemCallError, "setsockopt: %s", strerror(errno));
  
  return self;
}

void Init_socket(){
  mSCTP   = rb_define_module("SCTP");
  cSocket = rb_define_class_under(mSCTP, "Socket", rb_cObject);

  rb_define_method(cSocket, "initialize", rsctp_init, -1);

  rb_define_method(cSocket, "bindx", rsctp_bindx, -1);
  rb_define_method(cSocket, "close", rsctp_close, 0);
  rb_define_method(cSocket, "connectx", rsctp_connectx, 2);
  rb_define_method(cSocket, "getpeernames", rsctp_getpeernames, 0);
  rb_define_method(cSocket, "getlocalnames", rsctp_getlocalnames, 0);
  rb_define_method(cSocket, "listen", rsctp_listen, -1);
  rb_define_method(cSocket, "recvmsgx", rsctp_recvmsgx, -1);
  rb_define_method(cSocket, "sendmsgx", rsctp_sendmsgx, -1);
  rb_define_method(cSocket, "set_initmsg", rsctp_set_initmsg, 1);
  rb_define_method(cSocket, "subscribe", rsctp_subscribe, 1);

  rb_define_attr(cSocket, "domain", 1, 1);
  rb_define_attr(cSocket, "type", 1, 1);
  rb_define_attr(cSocket, "sock_fd", 1, 1);
  rb_define_attr(cSocket, "association_id", 1, 1);
}
