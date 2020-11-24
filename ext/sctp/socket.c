#include "ruby.h"
#include <string.h>
#include <errno.h>
#include <arpa/inet.h>
#include <netinet/sctp.h>

VALUE mSCTP;
VALUE cSocket;

// Helper function to get a hash value via string or symbol.
VALUE rb_hash_aref2(VALUE v_hash, const char* key){
  VALUE v_key, v_val;

  v_key = rb_str_new2(key);
  v_val = rb_hash_aref(v_hash, v_key);

  if(NIL_P(v_val))
    v_val = rb_hash_aref(v_hash, ID2SYM(rb_intern(key)));

  return v_val;
}

/*
 * Create and return a new SCTP::Socket instance. You may optionally pass in
 * a domain (aka family) value and socket type. By default these are AF_INET
 * and SOCK_SEQPACKET, respectively.
 *
 * Example:
 *
 *   socket1 = SCTP::Socket.new
 *   socket2 = SCTP::Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
 */
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

/*
 *  Bind a subset of IP addresses associated with the host system on the
 *  given port, or a port assigned by the operating system if none is provided.
 *
 *  Note that you can both add or remove an address to or from the socket
 *  using the SCTP_BINDX_ADD_ADDR (default) or SCTP_BINDX_REM_ADDR constants,
 *  respectively.
 *
 *  Example:
 *
 *    socket = SCTP::Socket.new
 *
 *    # Bind 2 addresses
 *    socket.bind(:port => 64325, :addresses => ['10.0.4.5', '10.0.5.5'])
 *
 *    # Remove 1 later
 *    socket.bind(:addresses => ['10.0.4.5'], :flags => SCTP::Socket::BINDX_REM_ADDR)
 *
 *  If no addresses are specified, then it will bind to all available interfaces. If
 *  no port is specified, then one will be assigned by the host.
 *
 *  Returns the port that it was bound to.
 */
static VALUE rsctp_bind(int argc, VALUE* argv, VALUE self){
  struct sockaddr_in addrs[8];
  int i, sock_fd, num_ip, flags, domain, port;
  VALUE v_addresses, v_port, v_flags, v_address, v_options;

  rb_scan_args(argc, argv, "01", &v_options);

  bzero(&addrs, sizeof(addrs));

  if(NIL_P(v_options))
    v_options = rb_hash_new();

  v_addresses = rb_hash_aref2(v_options, "addresses");
  v_flags = rb_hash_aref2(v_options, "flags");
  v_port = rb_hash_aref2(v_options, "port");

  if(NIL_P(v_port))
    port = 0;
  else
    port = NUM2INT(v_port);

  if(NIL_P(v_flags))
    flags = SCTP_BINDX_ADD_ADDR;
  else
    flags = NUM2INT(v_flags);

  if(NIL_P(v_addresses))
    num_ip = 1;
  else
    num_ip = RARRAY_LEN(v_addresses);

  domain = NUM2INT(rb_iv_get(self, "@domain"));
  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));

  if(num_ip > 1){
    for(i = 0; i < num_ip; i++){
      v_address = RARRAY_PTR(v_addresses)[i];
      addrs[i].sin_family = domain;
      addrs[i].sin_port = htons(port);
      addrs[i].sin_addr.s_addr = inet_addr(StringValueCStr(v_address));
    }
  }
  else{
    addrs[0].sin_family = domain;
    addrs[0].sin_port = htons(port);
    addrs[0].sin_addr.s_addr = htonl(INADDR_ANY);
  }

  if(sctp_bindx(sock_fd, (struct sockaddr *) addrs, num_ip, flags) != 0)
    rb_raise(rb_eSystemCallError, "sctp_bindx: %s", strerror(errno));

  if(port == 0){
    struct sockaddr_in sin;
    socklen_t len = sizeof(sin);

    if(getsockname(sock_fd, (struct sockaddr *)&sin, &len) == -1)
      rb_raise(rb_eSystemCallError, "getsockname: %s", strerror(errno));

    port = sin.sin_port;
  }

  return INT2NUM(port);
}

/*
 * Connect the socket to a multihomed peer via the provided array of addresses
 * using the domain specified in the constructor. You must also specify the port.
 *
 * Example:
 *
 *   socket = SCTP::Socket.new
 *   socket.connect(:port => 62354, :addresses => ['10.0.4.5', '10.0.5.5'])
 *
 * Note that this will also set/update the object's association_id.
 */
static VALUE rsctp_connect(int argc, VALUE* argv, VALUE self){
  struct sockaddr_in addrs[8];
  int i, num_ip, sock_fd;
  sctp_assoc_t assoc;
  VALUE v_address, v_domain, v_options, v_addresses, v_port;

  rb_scan_args(argc, argv, "01", &v_options);

  if(NIL_P(v_options))
    rb_raise(rb_eArgError, "you must specify an array of addresses");

  Check_Type(v_options, T_HASH);

  v_addresses = rb_hash_aref2(v_options, "addresses");
  v_port = rb_hash_aref2(v_options, "port");

  if(NIL_P(v_addresses) || RARRAY_LEN(v_addresses) == 0)
    rb_raise(rb_eArgError, "you must specify an array of addresses containing at least one address");

  if(NIL_P(v_port))
    rb_raise(rb_eArgError, "you must specify a port");

  v_domain = rb_iv_get(self, "@domain");

  num_ip = RARRAY_LEN(v_addresses);
  bzero(&addrs, sizeof(addrs));

  for(i = 0; i < num_ip; i++){
    v_address = RARRAY_PTR(v_addresses)[i];
    addrs[i].sin_family = NUM2INT(v_domain);
    addrs[i].sin_port = htons(NUM2INT(v_port));
    addrs[i].sin_addr.s_addr = inet_addr(StringValueCStr(v_address));
  }

  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));

  if(sctp_connectx(sock_fd, (struct sockaddr *) addrs, num_ip, &assoc) < 0)
    rb_raise(rb_eSystemCallError, "sctp_connectx: %s", strerror(errno));

  rb_iv_set(self, "@assocation_id", INT2NUM(assoc));

  return self;
}

/*
 * Close the socket. You should always do this.
 *
 * Example:
 *
 *   socket = SCTP::Socket.new
 *   socket.close
 */
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
 * Transmit a message to an SCTP endpoint. The following hash of options
 * is permitted:
 *
 *  :message -> The message to send to the endpoint. Mandatory.
 *  :stream  -> The SCTP stream number you wish to send the message on.
 *  :to      -> An array of addresses to send the message to.
 *  :context -> An opaque integer used in the event the message cannot be set.
 *  :ppid    -> An opaque integer that is passed transparently through the stack to the peer endpoint. 
 *  :flags   -> A bitwise integer that contain one or more values that control behavior.
 *
 *  Note that the :to option is not mandatory in a one-to-one (SOCK_STREAM)
 *  socket connection. However, it must have been set previously via the
 *  connect method.
 *
 *  Example:
 *
 *    socket = SCTP::Socket.new
 *
 *    socket.sendmsg(
 *      :message => "Hello World!",
 *      :stream  => 3,
 *      :flags   => SCTP::Socket::SCTP_UNORDERED | SCTP::Socket::SCTP_SENDALL,
 *      :ttl     => 100,
 *      :to      => ['10.0.5.4', '10.0.6.4']
 *    )
 */
static VALUE rsctp_sendmsg(VALUE self, VALUE v_options){
  VALUE v_msg, v_ppid, v_flags, v_stream, v_ttl, v_context, v_addresses;
  uint16_t stream;
  uint32_t ppid, flags, ttl, context;
  ssize_t num_bytes;
  struct sockaddr_in addrs[8];
  int sock_fd, size;

  Check_Type(v_options, T_HASH);

  bzero(&addrs, sizeof(addrs));

  v_msg       = rb_hash_aref2(v_options, "message");
  v_stream    = rb_hash_aref2(v_options, "stream");
  v_ppid      = rb_hash_aref2(v_options, "ppid");
  v_context   = rb_hash_aref2(v_options, "context");
  v_flags     = rb_hash_aref2(v_options, "flags");
  v_ttl       = rb_hash_aref2(v_options, "ttl");
  v_addresses = rb_hash_aref2(v_options, "addresses");

  if(NIL_P(v_stream))
    stream = 0;
  else
    stream = NUM2INT(v_stream);

  if(NIL_P(v_flags))
    flags = 0;
  else
    flags = NUM2INT(v_stream);

  if(NIL_P(v_ttl))
    ttl = 0;
  else
    ttl = NUM2INT(v_ttl);

  if(NIL_P(v_ppid))
    ppid = 0;
  else
    ppid = NUM2INT(v_ppid);

  if(NIL_P(v_context))
    context = 0;
  else
    context = NUM2INT(v_context);

  if(!NIL_P(v_addresses)){
    int i, num_ip, port;
    VALUE v_address, v_port;

    num_ip = RARRAY_LEN(v_addresses);
    v_port = rb_hash_aref2(v_options, "port");

    if(NIL_P(v_port))
      port = 0;
    else
      port = NUM2INT(v_port);

    for(i = 0; i < num_ip; i++){
      v_address = RARRAY_PTR(v_addresses)[i];
      addrs[i].sin_family = NUM2INT(rb_iv_get(self, "@domain"));
      addrs[i].sin_port = htons(port);
      addrs[i].sin_addr.s_addr = inet_addr(StringValueCStr(v_address));
    }

    size = sizeof(addrs);
  }
  else{
    size = 0;
  }

  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));

  num_bytes = sctp_sendmsg(
    sock_fd,
    StringValueCStr(v_msg),
    RSTRING_LEN(v_msg),
    (struct sockaddr*)addrs,
    size,
    ppid,
    flags,
    stream,
    ttl,
    context
  );

  if(num_bytes < 0)
    rb_raise(rb_eSystemCallError, "sctp_sendmsg: %s", strerror(errno));

  return INT2NUM(num_bytes);
}

static VALUE rsctp_recvmsg(int argc, VALUE* argv, VALUE self){
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
  bzero(buffer, sizeof(buffer));

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
  return rb_str_new(buffer, bytes);
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

static VALUE rsctp_peeloff(VALUE self, VALUE v_assoc_id){
  int sock_fd;
  sctp_assoc_t assoc_id;
    
  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));
  assoc_id = NUM2INT(v_assoc_id);

  if(sctp_peeloff(sock_fd, assoc_id) < 0)
    rb_raise(rb_eSystemCallError, "sctp_peeloff: %s", strerror(errno));

  return self;
}

void Init_socket(){
  mSCTP   = rb_define_module("SCTP");
  cSocket = rb_define_class_under(mSCTP, "Socket", rb_cObject);

  rb_define_method(cSocket, "initialize", rsctp_init, -1);

  rb_define_method(cSocket, "bind", rsctp_bind, -1);
  rb_define_method(cSocket, "close", rsctp_close, 0);
  rb_define_method(cSocket, "connect", rsctp_connect, -1);
  rb_define_method(cSocket, "getpeernames", rsctp_getpeernames, 0);
  rb_define_method(cSocket, "getlocalnames", rsctp_getlocalnames, 0);
  rb_define_method(cSocket, "listen", rsctp_listen, -1);
  rb_define_method(cSocket, "peeloff", rsctp_peeloff, 1);
  rb_define_method(cSocket, "recvmsg", rsctp_recvmsg, -1);
  rb_define_method(cSocket, "sendmsg", rsctp_sendmsg, 1);
  rb_define_method(cSocket, "set_initmsg", rsctp_set_initmsg, 1);
  rb_define_method(cSocket, "subscribe", rsctp_subscribe, 1);

  rb_define_attr(cSocket, "domain", 1, 1);
  rb_define_attr(cSocket, "type", 1, 1);
  rb_define_attr(cSocket, "sock_fd", 1, 1);
  rb_define_attr(cSocket, "association_id", 1, 1);
  rb_define_attr(cSocket, "port", 1, 1);
}
