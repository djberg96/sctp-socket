#include "ruby.h"
#include <string.h>
#include <errno.h>
#include <arpa/inet.h>
#include <netinet/sctp.h>

VALUE mSCTP;
VALUE cSocket;
VALUE v_sndrcv_struct;
VALUE v_assoc_change_struct;
VALUE v_peeraddr_change_struct;
VALUE v_remote_error_struct;
VALUE v_send_failed_event_struct;
VALUE v_shutdown_event_struct;
VALUE v_sndinfo_struct;
VALUE v_adaptation_event_struct;
VALUE v_partial_delivery_event_struct;
VALUE v_auth_event_struct;
VALUE v_sockaddr_in_struct;
VALUE v_sctp_status_struct;
VALUE v_sctp_rtoinfo_struct;
VALUE v_sctp_associnfo_struct;
VALUE v_sctp_default_send_params_struct;
VALUE v_sctp_event_subscribe_struct;
VALUE v_sctp_receive_info_struct;

#if !defined(IOV_MAX)
#if defined(_SC_IOV_MAX)
#define IOV_MAX (sysconf(_SC_IOV_MAX))
#else
#define IOV_MAX INT_MAX
#endif
#endif

// TODO: Yes, I know I need to update the signature.
VALUE convert_sockaddr_in_to_struct(struct sockaddr_in* addr){
  char ipbuf[INET6_ADDRSTRLEN];

  if(addr->sin_family == AF_INET6)
    inet_ntop(addr->sin_family, &(((struct sockaddr_in6 *)addr)->sin6_addr), ipbuf, sizeof(ipbuf));
  else
    inet_ntop(addr->sin_family, &(((struct sockaddr_in *)addr)->sin_addr), ipbuf, sizeof(ipbuf));

  return rb_struct_new(v_sockaddr_in_struct,
    INT2NUM(addr->sin_family),
    INT2NUM(ntohs(addr->sin_port)),
    rb_str_new2(ipbuf)
  );
}

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
 * There are only two supported families: SOCK_SEQPACKET for the creation
 * of a one-to-many socket, and SOCK_STREAM for the creation of a
 * one-to-one socket.
 *
 * Example:
 *
 *   require 'socket'
 *   require 'sctp/socket'
 *
 *   socket1 = SCTP::Socket.new
 *   socket2 = SCTP::Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
 */
static VALUE rsctp_init(int argc, VALUE* argv, VALUE self){
  int fileno;
  VALUE v_domain, v_type;

  rb_scan_args(argc, argv, "02", &v_domain, &v_type);

  if(NIL_P(v_domain))
    v_domain = INT2NUM(AF_INET);
  
  if(NIL_P(v_type))
    v_type = INT2NUM(SOCK_SEQPACKET);

  fileno = socket(NUM2INT(v_domain), NUM2INT(v_type), IPPROTO_SCTP);

  if(fileno < 0)
    rb_raise(rb_eSystemCallError, "socket: %s", strerror(errno));

  rb_iv_set(self, "@domain", v_domain);
  rb_iv_set(self, "@type", v_type);
  rb_iv_set(self, "@fileno", INT2NUM(fileno));
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
 *    socket.bindx(:port => 64325, :addresses => ['10.0.4.5', '10.0.5.5'])
 *
 *    # Remove 1 later
 *    socket.bindx(:addresses => ['10.0.4.5'], :flags => SCTP::Socket::BINDX_REM_ADDR)
 *
 *  If no addresses are specified, then it will bind to all available interfaces. If
 *  no port is specified, then one will be assigned by the host.
 *
 *  Returns the port that it was bound to.
 */
static VALUE rsctp_bindx(int argc, VALUE* argv, VALUE self){
  struct sockaddr_in addrs[8];
  int i, fileno, num_ip, flags, domain, port;
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
  fileno = NUM2INT(rb_iv_get(self, "@fileno"));

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

  if(sctp_bindx(fileno, (struct sockaddr *) addrs, num_ip, flags) != 0)
    rb_raise(rb_eSystemCallError, "sctp_bindx: %s", strerror(errno));

  if(port == 0){
    struct sockaddr_in sin;
    socklen_t len = sizeof(sin);

    if(getsockname(fileno, (struct sockaddr *)&sin, &len) == -1)
      rb_raise(rb_eSystemCallError, "getsockname: %s", strerror(errno));

    port = sin.sin_port;
  }

  rb_iv_set(self, "@port", INT2NUM(port));

  return INT2NUM(port);
}

/*
 * Connect the socket to a multihomed peer via the provided array of addresses
 * using the domain specified in the constructor. You must also specify the port.
 *
 * Example:
 *
 *   socket = SCTP::Socket.new
 *   socket.connectx(:port => 62354, :addresses => ['10.0.4.5', '10.0.5.5'])
 *
 * Note that this will also set/update the object's association_id.
 */
static VALUE rsctp_connectx(int argc, VALUE* argv, VALUE self){
  struct sockaddr_in addrs[8];
  int i, num_ip, fileno;
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

  fileno = NUM2INT(rb_iv_get(self, "@fileno"));

  if(sctp_connectx(fileno, (struct sockaddr *) addrs, num_ip, &assoc) < 0)
    rb_raise(rb_eSystemCallError, "sctp_connectx: %s", strerror(errno));

  rb_iv_set(self, "@association_id", INT2NUM(assoc));

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
  VALUE v_fileno = rb_iv_get(self, "@fileno");

  if(close(NUM2INT(v_fileno)))
    rb_raise(rb_eSystemCallError, "close: %s", strerror(errno));

  return self;
}

/*
 *  Return an array of all addresses of a peer of the current socket
 *  and association number.
 *
 *  You may optionally pass a assocation fileno and association ID. Typically
 *  this information would come from the peeloff method.
 *
 *  Example:
 *
 *    socket = SCTP::Socket.new
 *    # ...
 *    p socket.getpeernames
 *
 *    info = socket.recvmsg
 *    association_fileno = socket.peeloff(info.association_id)
 *
 *    p socket.getpeernames(association_fileno, info.association_id)
 */
static VALUE rsctp_getpeernames(int argc, VALUE* argv, VALUE self){
  sctp_assoc_t assoc_id;
  struct sockaddr* addrs;
  int i, fileno, num_addrs;
  char str[16];
  VALUE v_fileno, v_association_id;
  VALUE v_array = rb_ary_new();

  bzero(&addrs, sizeof(addrs));

  rb_scan_args(argc, argv, "02", &v_fileno, &v_association_id);

  if(NIL_P(v_fileno))
    fileno = NUM2INT(rb_iv_get(self, "@fileno"));
  else
    fileno = NUM2INT(v_fileno);

  if(NIL_P(v_association_id))
    assoc_id = NUM2INT(rb_iv_get(self, "@association_id"));
  else
    assoc_id = NUM2INT(v_association_id);

  num_addrs = sctp_getpaddrs(fileno, assoc_id, &addrs);

  if(num_addrs < 0){
    sctp_freepaddrs(addrs);
    rb_raise(rb_eSystemCallError, "sctp_getpaddrs: %s", strerror(errno));
  }

  for(i = 0; i < num_addrs; i++){
    inet_ntop(AF_INET, &(((struct sockaddr_in *)&addrs[i])->sin_addr), str, sizeof(str));
    rb_ary_push(v_array, rb_str_new2(str));
    bzero(&str, sizeof(str));
  }

  sctp_freepaddrs(addrs);

  return v_array;
}

/*
 * Return an array of local addresses that are part of the association.
 *
 * Example:
 *
 *  socket = SCTP::Socket.new
 *  socket.bind(:addresses => ['10.0.4.5', '10.0.5.5'])
 *  socket.getlocalnames # => ['10.0.4.5', '10.0.5.5'])
 *
 *  # or get info from a peeled off association...
 *
 *  assoc_fileno = socket.peeloff(some_association_id)
 *  socket.getlocalnames(assoc_fileno, some_association_id)
 */
static VALUE rsctp_getlocalnames(int argc, VALUE* argv, VALUE self){
  sctp_assoc_t assoc_id;
  struct sockaddr* addrs;
  int i, fileno, num_addrs;
  char str[16];
  VALUE v_assoc_fileno, v_assoc_id;
  VALUE v_array = rb_ary_new();

  bzero(&addrs, sizeof(addrs));

  rb_scan_args(argc, argv, "02", &v_assoc_fileno, &v_assoc_id);

  if(NIL_P(v_assoc_fileno))
    fileno = NUM2INT(rb_iv_get(self, "@fileno"));
  else
    fileno = NUM2INT(v_assoc_fileno);

  if(NIL_P(v_assoc_id))
    assoc_id = NUM2INT(rb_iv_get(self, "@association_id"));
  else
    assoc_id = NUM2INT(v_assoc_id);

  num_addrs = sctp_getladdrs(fileno, assoc_id, &addrs);

  if(num_addrs < 0){
    sctp_freeladdrs(addrs);
    rb_raise(rb_eSystemCallError, "sctp_getladdrs: %s", strerror(errno));
  }

  for(i = 0; i < num_addrs; i++){
    inet_ntop(AF_INET, &(((struct sockaddr_in *)&addrs[i])->sin_addr), str, sizeof(str));
    rb_ary_push(v_array, rb_str_new2(str));
    bzero(&str, sizeof(str));
  }

  sctp_freeladdrs(addrs);

  return v_array;
}

#ifdef HAVE_SCTP_SENDV
/*
 * Transmit a message to an SCTP endpoint using a gather-write. The following
 * hash of options is permitted:
 *
 *  * message   - An array of strings that will be joined into a single message.
 *  * addresses - An array of IP addresses to setup an association to send the message.
 *  * info_type - The type of information provided. The default is SCTP_SENDV_SNDINFO.
 *
 *  Example:
 *
 *    socket = SCTP::Socket.new
 *
 *    socket.sendv
 *      :message   => ['Hello ', 'World.'],
 *      :addresses => ['10.0.5.4', '10.0.6.4'],
 *      :info_type => SCTP::Socket:::SCTP_SENDV_SNDINFO
 *    )
 *
 *  CAVEAT: Currently addresses does not work, and info_type is not yet supported.
 *
 *  Returns the number of bytes sent.
 */
static VALUE rsctp_sendv(VALUE self, VALUE v_options){
  VALUE v_msg, v_message, v_addresses;
  struct iovec iov[IOV_MAX];
  struct sockaddr_in* addrs;
  struct sctp_sndinfo info;
  int i, fileno, num_bytes, size, num_ip;

  Check_Type(v_options, T_HASH);

  bzero(&iov, sizeof(iov));
  bzero(&info, sizeof(info));

  v_message   = rb_hash_aref2(v_options, "message");
  v_addresses = rb_hash_aref2(v_options, "addresses");

  if(!NIL_P(v_message))
    Check_Type(v_message, T_ARRAY);

  if(!NIL_P(v_addresses)){
    Check_Type(v_addresses, T_ARRAY);
    num_ip = RARRAY_LEN(v_addresses);
    addrs = (struct sockaddr_in*)alloca(sizeof(struct sockaddr_in) * num_ip);
  }
  else{
    addrs = NULL;
    num_ip = 0;
  }

  fileno = NUM2INT(rb_iv_get(self, "@fileno"));
  size = RARRAY_LEN(v_message);

  if(!size)
    rb_raise(rb_eArgError, "Must contain at least one message");

  if(size > IOV_MAX)
    rb_raise(rb_eArgError, "Array size is greater than IOV_MAX");

  info.snd_flags = SCTP_UNORDERED;
  info.snd_assoc_id = NUM2INT(rb_iv_get(self, "@association_id"));

  if(!NIL_P(v_addresses)){
    int i, port;
    VALUE v_address, v_port;

    v_port = NUM2INT(rb_iv_get(self, "@port"));

    if(NIL_P(v_port))
      port = 0;
    else
      port = NUM2INT(v_port);

    for(i = 0; i < num_ip; i++){
      v_address = RARRAY_PTR(v_addresses)[i];
      addrs->sin_family = NUM2INT(rb_iv_get(self, "@domain"));
      addrs->sin_port = htons(port);
      addrs->sin_addr.s_addr = inet_addr(StringValueCStr(v_address));
      addrs += sizeof(struct sockaddr_in);
    }
  }

  for(i = 0; i < size; i++){
    v_msg = RARRAY_PTR(v_message)[i];
    iov[i].iov_base = StringValueCStr(v_msg);
    iov[i].iov_len = RSTRING_LEN(v_msg);
  }

  num_bytes = sctp_sendv(
    fileno,
    iov,
    size,
    (struct sockaddr*)addrs,
    num_ip,
    &info,
    sizeof(info),
    SCTP_SENDV_SNDINFO,
    0
  );

  if(num_bytes < 0)
    rb_raise(rb_eSystemCallError, "sctp_sendv: %s", strerror(errno));

  return INT2NUM(num_bytes);
}
#endif

#ifdef HAVE_SCTP_RECVV
static VALUE rsctp_recvv(int argc, VALUE* argv, VALUE self){
  VALUE v_flags;
  int fileno, flags, bytes;
  uint infotype;
  socklen_t infolen;
  struct iovec iov[1];
  struct sctp_rcvinfo info;
  char buffer[1024];

  bzero(&iov, sizeof(iov));
  bzero(&info, sizeof(info));
  bzero(&buffer, sizeof(buffer));

	iov->iov_base = buffer;
	iov->iov_len = sizeof(buffer);

  rb_scan_args(argc, argv, "01", &v_flags);

  fileno = NUM2INT(rb_iv_get(self, "@fileno"));

  if(NIL_P(v_flags))
    flags = 0;
  else
    flags = NUM2INT(v_flags);

  infolen = sizeof(struct sctp_rcvinfo);
  infotype = SCTP_RECVRCVINFO;

  bytes = sctp_recvv(
    fileno,
    iov,
    1,
    NULL,
    NULL,
    &info,
    &infolen,
    &infotype,
    &flags
  );

  if(bytes < 0)
    rb_raise(rb_eSystemCallError, "sctp_recvv: %s", strerror(errno));

  return rb_struct_new(
    v_sctp_receive_info_struct,
    rb_str_new2(iov->iov_base),
    UINT2NUM(info.rcv_sid),
    UINT2NUM(info.rcv_ssn),
    UINT2NUM(info.rcv_flags),
    UINT2NUM(info.rcv_ppid),
    UINT2NUM(info.rcv_tsn),
    UINT2NUM(info.rcv_cumtsn),
    UINT2NUM(info.rcv_context),
    UINT2NUM(info.rcv_assoc_id)
  );
}
#endif

/*
 * Send a message on an already-connected socket to a specific association.
 *
 * Example:
 *
 *   socket = SCTP::Socket.new
 *   socket.connect(:port => 42000, :addresses => ['10.0.4.5', '10.0.5.5'])
 *
 *   socket.send(:message => "Hello World")
 *   socket.send(:message => "Hello World", :association_id => 37)
 *
 */
static VALUE rsctp_send(VALUE self, VALUE v_options){
  uint16_t stream;
  uint32_t ppid, send_flags, ctrl_flags, ttl, context;
  ssize_t num_bytes;
  int fileno;
  sctp_assoc_t assoc_id;
  struct sctp_sndrcvinfo info;
  VALUE v_msg, v_stream, v_ppid, v_context, v_send_flags, v_ctrl_flags, v_ttl, v_assoc_id;

  Check_Type(v_options, T_HASH);

  v_msg        = rb_hash_aref2(v_options, "message");
  v_stream     = rb_hash_aref2(v_options, "stream");
  v_ppid       = rb_hash_aref2(v_options, "ppid");
  v_context    = rb_hash_aref2(v_options, "context");
  v_send_flags = rb_hash_aref2(v_options, "send_flags");
  v_ctrl_flags = rb_hash_aref2(v_options, "control_flags");
  v_ttl        = rb_hash_aref2(v_options, "ttl");
  v_assoc_id   = rb_hash_aref2(v_options, "association_id");

  if(NIL_P(v_stream))
    stream = 0;
  else
    stream = NUM2INT(v_stream);

  if(NIL_P(v_send_flags))
    send_flags = 0;
  else
    send_flags = NUM2INT(v_send_flags);

  if(NIL_P(v_ctrl_flags))
    ctrl_flags = 0;
  else
    ctrl_flags = NUM2INT(v_ctrl_flags);

  if(NIL_P(v_ttl)){
    ttl = 0;
  }
  else{
    ttl = NUM2INT(v_ttl);
    send_flags |= SCTP_PR_SCTP_TTL;
  }

  if(NIL_P(v_ppid))
    ppid = 0;
  else
    ppid = NUM2INT(v_ppid);

  if(NIL_P(v_context))
    context = 0;
  else
    context = NUM2INT(v_context);

  if(NIL_P(v_assoc_id))
    assoc_id = NUM2INT(rb_iv_get(self, "@association_id"));
  else
    assoc_id = NUM2INT(v_assoc_id);

  info.sinfo_stream = stream;
  info.sinfo_flags = send_flags;
  info.sinfo_ppid = ppid;
  info.sinfo_context = context;
  info.sinfo_timetolive = ttl;
  info.sinfo_assoc_id = assoc_id;

  fileno = NUM2INT(rb_iv_get(self, "@fileno"));

  num_bytes = sctp_send(
    fileno,
    StringValueCStr(v_msg),
    RSTRING_LEN(v_msg),
    &info,
    ctrl_flags
  );

  if(num_bytes < 0)
    rb_raise(rb_eSystemCallError, "sctp_send: %s", strerror(errno));

  return INT2NUM(num_bytes);
}

/*
 * Transmit a message to an SCTP endpoint. The following hash of options
 * is permitted:
 *
 *  :message   -> The message to send to the endpoint. Mandatory.
 *  :stream    -> The SCTP stream number you wish to send the message on.
 *  :addresses -> An array of addresses to send the message to.
 *  :context   -> The default context used for the sendmsg call if the send fails.
 *  :ppid      -> The payload protocol identifier that is passed to the peer endpoint. 
 *  :flags     -> A bitwise integer that contain one or more values that control behavior.
 *
 *  Note that the :addresses option is not mandatory in a one-to-one (SOCK_STREAM)
 *  socket connection. However, it must have been set previously via the
 *  connect method.
 *
 *  Example:
 *
 *    socket = SCTP::Socket.new
 *
 *    socket.sendmsg(
 *      :message   => "Hello World!",
 *      :stream    => 3,
 *      :flags     => SCTP::Socket::SCTP_UNORDERED | SCTP::Socket::SCTP_SENDALL,
 *      :ttl       => 100,
 *      :addresses => ['10.0.5.4', '10.0.6.4']
 *    )
 *
 *  Returns the number of bytes sent.
 */
static VALUE rsctp_sendmsg(VALUE self, VALUE v_options){
  VALUE v_msg, v_ppid, v_flags, v_stream, v_ttl, v_context, v_addresses;
  uint16_t stream;
  uint32_t ppid, flags, ttl, context;
  ssize_t num_bytes;
  struct sockaddr_in addrs[8];
  int fileno, size;

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
    flags = NUM2INT(v_flags);

  if(NIL_P(v_ttl)){
    ttl = 0;
  }
  else{
    ttl = NUM2INT(v_ttl);
    flags |= SCTP_PR_SCTP_TTL;
  }

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

  fileno = NUM2INT(rb_iv_get(self, "@fileno"));

  num_bytes = sctp_sendmsg(
    fileno,
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

/*
 * Receive a message from another SCTP endpoint.
 *
 * Example:
 *
 *   begin
 *     socket = SCTP::Socket.new
 *     socket.bind(:port => 62534, :addresses => ['10.0.4.5', '10.0.5.5'])
 *     socket.subscribe(:data_io => 1)
 *     socket.listen
 *
 *     while true
 *       info = socket.recvmsg
 *       puts "Received message: #{info.message}"
 *     end
 *   ensure
 *     socket.close
 *   end
 */
static VALUE rsctp_recvmsg(int argc, VALUE* argv, VALUE self){
  VALUE v_flags, v_notification, v_message;
  struct sctp_sndrcvinfo sndrcvinfo;
  struct sockaddr_in clientaddr;
  int flags, bytes, fileno;
  char buffer[1024]; // TODO: Let this be configurable?
  socklen_t length;

  rb_scan_args(argc, argv, "01", &v_flags);

  if(NIL_P(v_flags))
    flags = 0;
  else
    flags = NUM2INT(v_flags);  

  fileno = NUM2INT(rb_iv_get(self, "@fileno"));
  length = sizeof(struct sockaddr_in);

  bzero(buffer, sizeof(buffer));
  bzero(&clientaddr, sizeof(clientaddr));
  bzero(&sndrcvinfo, sizeof(sndrcvinfo));

  bytes = sctp_recvmsg(
    fileno,
    buffer,
    sizeof(buffer),
    (struct sockaddr*)&clientaddr,
    &length,
    &sndrcvinfo,
    &flags
  );

  if(bytes < 0)
    rb_raise(rb_eSystemCallError, "sctp_recvmsg: %s", strerror(errno));

  v_notification = Qnil;

  if(flags & MSG_NOTIFICATION){
    uint32_t i;
    char str[16];
    union sctp_notification* snp;
    VALUE v_str;
    VALUE* v_temp;

    snp = (union sctp_notification*)buffer;

    switch(snp->sn_header.sn_type){
      case SCTP_ASSOC_CHANGE:
        switch(snp->sn_assoc_change.sac_state){
          case SCTP_COMM_LOST:
            v_str = rb_str_new2("comm lost");
            break;
          case SCTP_COMM_UP:
            v_str = rb_str_new2("comm up");
            break;
          case SCTP_RESTART:
            v_str = rb_str_new2("restart");
            break;
          case SCTP_SHUTDOWN_COMP:
            v_str = rb_str_new2("shutdown complete");
            break;
          case SCTP_CANT_STR_ASSOC:
            v_str = rb_str_new2("association setup failed");
            break;
          default:
            v_str = rb_str_new2("unknown");
        }

        v_notification = rb_struct_new(v_assoc_change_struct,
          UINT2NUM(snp->sn_assoc_change.sac_type),
          UINT2NUM(snp->sn_assoc_change.sac_length),
          UINT2NUM(snp->sn_assoc_change.sac_state),
          UINT2NUM(snp->sn_assoc_change.sac_error),
          UINT2NUM(snp->sn_assoc_change.sac_outbound_streams),
          UINT2NUM(snp->sn_assoc_change.sac_inbound_streams),
          UINT2NUM(snp->sn_assoc_change.sac_assoc_id),
          v_str
        );
        break;
      case SCTP_PEER_ADDR_CHANGE:
        switch(snp->sn_paddr_change.spc_state){
          case SCTP_ADDR_AVAILABLE:
            v_str = rb_str_new2("available");
            break;
          case SCTP_ADDR_UNREACHABLE:
            v_str = rb_str_new2("unreachable");
            break;
          case SCTP_ADDR_REMOVED:
            v_str = rb_str_new2("removed from association");
            break;
          case SCTP_ADDR_ADDED:
            v_str = rb_str_new2("added to association");
            break;
          case SCTP_ADDR_MADE_PRIM:
            v_str = rb_str_new2("primary destination");
            break;
          default:
            v_str = rb_str_new2("unknown");
        }

        inet_ntop(
          ((struct sockaddr_in *)&snp->sn_paddr_change.spc_aaddr)->sin_family,
          &(((struct sockaddr_in *)&snp->sn_paddr_change.spc_aaddr)->sin_addr),
          str,
          sizeof(str)
        );

        v_notification = rb_struct_new(v_peeraddr_change_struct,
          UINT2NUM(snp->sn_paddr_change.spc_type),
          UINT2NUM(snp->sn_paddr_change.spc_length),
          rb_str_new2(str),
          UINT2NUM(snp->sn_paddr_change.spc_state),
          UINT2NUM(snp->sn_paddr_change.spc_error),
          UINT2NUM(snp->sn_paddr_change.spc_assoc_id),
          v_str
        );
        break;
      case SCTP_REMOTE_ERROR:
        v_temp = ALLOCA_N(VALUE, snp->sn_remote_error.sre_length);

        for(i = 0; i < snp->sn_remote_error.sre_length; i++){
          v_temp[i] = UINT2NUM(snp->sn_remote_error.sre_data[i]);
        }

        v_notification = rb_struct_new(v_remote_error_struct,
          UINT2NUM(snp->sn_remote_error.sre_type),
          UINT2NUM(snp->sn_remote_error.sre_length),
          UINT2NUM(snp->sn_remote_error.sre_error),
          UINT2NUM(snp->sn_remote_error.sre_assoc_id),
          rb_ary_new4(snp->sn_remote_error.sre_length, v_temp)
        );
        break;
#ifdef SCTP_SEND_FAILED_EVENT
      case SCTP_SEND_FAILED_EVENT:
        v_temp = ALLOCA_N(VALUE, snp->sn_send_failed_event.ssf_length);

        for(i = 0; i < snp->sn_send_failed_event.ssf_length; i++){
          v_temp[i] = UINT2NUM(snp->sn_send_failed_event.ssf_data[i]);
        }

        v_notification = rb_struct_new(v_send_failed_event_struct,
          UINT2NUM(snp->sn_send_failed_event.ssf_type),
          UINT2NUM(snp->sn_send_failed_event.ssf_length),
          UINT2NUM(snp->sn_send_failed_event.ssf_error),
          rb_struct_new(v_sndinfo_struct,
            UINT2NUM(snp->sn_send_failed_event.ssfe_info.snd_sid),
            UINT2NUM(snp->sn_send_failed_event.ssfe_info.snd_flags),
            UINT2NUM(snp->sn_send_failed_event.ssfe_info.snd_ppid),
            UINT2NUM(snp->sn_send_failed_event.ssfe_info.snd_context),
            UINT2NUM(snp->sn_send_failed_event.ssfe_info.snd_assoc_id)
          ),
          UINT2NUM(snp->sn_send_failed_event.ssf_assoc_id),
          rb_ary_new4(snp->sn_send_failed_event.ssf_length, v_temp)
        );
        break;
#else
      case SCTP_SEND_FAILED:
        v_temp = ALLOCA_N(VALUE, snp->sn_send_failed.ssf_length);

        for(i = 0; i < snp->sn_send_failed.ssf_length; i++){
          v_temp[i] = UINT2NUM(snp->sn_send_failed.ssf_data[i]);
        }

        v_notification = rb_struct_new(v_send_failed_event_struct,
          UINT2NUM(snp->sn_send_failed.ssf_type),
          UINT2NUM(snp->sn_send_failed.ssf_length),
          UINT2NUM(snp->sn_send_failed.ssf_error),
          Qnil,
          UINT2NUM(snp->sn_send_failed.ssf_assoc_id),
          rb_ary_new4(snp->sn_send_failed.ssf_length, v_temp)
        );
        break;
#endif
      case SCTP_SHUTDOWN_EVENT:
        v_notification = rb_struct_new(v_shutdown_event_struct,
          UINT2NUM(snp->sn_shutdown_event.sse_type),
          UINT2NUM(snp->sn_shutdown_event.sse_length),
          UINT2NUM(snp->sn_shutdown_event.sse_assoc_id)
        );
        break;
      case SCTP_ADAPTATION_INDICATION:
        v_notification = rb_struct_new(v_adaptation_event_struct,
          UINT2NUM(snp->sn_adaptation_event.sai_type),
          UINT2NUM(snp->sn_adaptation_event.sai_length),
          UINT2NUM(snp->sn_adaptation_event.sai_adaptation_ind),
          UINT2NUM(snp->sn_adaptation_event.sai_assoc_id)
        );
        break;
      case SCTP_PARTIAL_DELIVERY_EVENT:
        v_notification = rb_struct_new(v_partial_delivery_event_struct,
          UINT2NUM(snp->sn_pdapi_event.pdapi_type),
          UINT2NUM(snp->sn_pdapi_event.pdapi_length),
          UINT2NUM(snp->sn_pdapi_event.pdapi_indication),
          UINT2NUM(snp->sn_pdapi_event.pdapi_stream),
          UINT2NUM(snp->sn_pdapi_event.pdapi_seq),
          UINT2NUM(snp->sn_pdapi_event.pdapi_assoc_id)
        );
        break;
      case SCTP_AUTHENTICATION_EVENT:
        v_notification = rb_struct_new(v_auth_event_struct,
          UINT2NUM(snp->sn_authkey_event.auth_type),
          UINT2NUM(snp->sn_authkey_event.auth_length),
          UINT2NUM(snp->sn_authkey_event.auth_keynumber),
          UINT2NUM(snp->sn_authkey_event.auth_indication),
          UINT2NUM(snp->sn_authkey_event.auth_assoc_id)
        );
        break;
    }
  }

  if(NIL_P(v_notification))
    v_message = rb_str_new(buffer, bytes);
  else
    v_message = Qnil;

  return rb_struct_new(v_sndrcv_struct,
    v_message,
    UINT2NUM(sndrcvinfo.sinfo_stream),
    UINT2NUM(sndrcvinfo.sinfo_flags),
    UINT2NUM(sndrcvinfo.sinfo_ppid),
    UINT2NUM(sndrcvinfo.sinfo_context),
    UINT2NUM(sndrcvinfo.sinfo_timetolive),
    UINT2NUM(sndrcvinfo.sinfo_assoc_id),
    v_notification,
    convert_sockaddr_in_to_struct(&clientaddr)
  );
}

/*
 * Set the initial parameters used by the socket when sending out the INIT message.
 *
 * Example:
 *
 *  socket = SCTP::Socket.new
 *  socket.set_initmsg(:output_streams => 5, :input_streams => 5, :max_attempts => 4, :timeout => 30)
 *
 * The following parameters can be configured:
 *
 * :output_streams - The number of outbound SCTP streams an application would like to request.
 * :input_streams - The maximum number of inbound streams an application is prepared to allow.
 * :max_attempts - How many times the the SCTP stack should send the initial INIT message before it's considered unreachable.
 * :timeout - The maximum RTO value for the INIT timer.
 *
 * By default these values are set to zero (i.e. ignored).
 */
static VALUE rsctp_set_initmsg(VALUE self, VALUE v_options){
  int fileno;
  struct sctp_initmsg initmsg;
  VALUE v_output, v_input, v_attempts, v_timeout;

  bzero(&initmsg, sizeof(initmsg));

  v_output   = rb_hash_aref2(v_options, "output_streams");
  v_input    = rb_hash_aref2(v_options, "input_streams");
  v_attempts = rb_hash_aref2(v_options, "max_attempts");
  v_timeout  = rb_hash_aref2(v_options, "timeout");

  fileno = NUM2INT(rb_iv_get(self, "@fileno"));

  if(!NIL_P(v_output))
    initmsg.sinit_num_ostreams = NUM2INT(v_output);

  if(!NIL_P(v_input))
    initmsg.sinit_max_instreams = NUM2INT(v_input);

  if(!NIL_P(v_attempts))
    initmsg.sinit_max_attempts = NUM2INT(v_attempts);

  if(!NIL_P(v_timeout))
    initmsg.sinit_max_init_timeo = NUM2INT(v_timeout);

  if(setsockopt(fileno, IPPROTO_SCTP, SCTP_INITMSG, &initmsg, sizeof(initmsg)) < 0)
    rb_raise(rb_eSystemCallError, "setsockopt: %s", strerror(errno));

  return self;
}

/*
 * Subscribe to various notification types, which will generate additional
 * data that the socket may receive. The possible notification types are
 * as follows:
 *
 *   :association
 *   - A change has occurred to an association, either a new one has begun or an existing one has end.
 *
 *   :address
 *   - The state of one of the peer's addresses has experienced a change.
 *
 *   :send_failure
 *   - The message could not be delivered to a peer.
 *
 *   :shutdown
 *   - The peer has sent a shutdown to the local endpoint.
 *
 *   :data_io
 *   - Message data was received. You will want to subscribe to this in most cases.
 *
 *   Others:
 *
 *   :adaptation
 *   :authentication
 *   :partial_delivery
 *
 *   Not yet supported:
 *
 *   :sender_dry
 *   :peer_error
 *
 * Example:
 * 
 *   socket = SCTP::Socket.new
 *
 *   socket.bind(:port => port, :addresses => ['127.0.0.1'])
 *   socket.subscribe(:data_io => true, :shutdown => true, :send_failure => true)
 */
static VALUE rsctp_subscribe(VALUE self, VALUE v_options){
  int fileno;
  struct sctp_event_subscribe events;

  bzero(&events, sizeof(events));
  Check_Type(v_options, T_HASH);

  fileno = NUM2INT(rb_iv_get(self, "@fileno"));

  if(RTEST(rb_hash_aref2(v_options, "data_io")))
    events.sctp_data_io_event = 1;

  if(RTEST(rb_hash_aref2(v_options, "association")))
    events.sctp_association_event = 1;

  if(RTEST(rb_hash_aref2(v_options, "address")))
    events.sctp_address_event = 1;

  if(RTEST(rb_hash_aref2(v_options, "send_failure")))
#ifdef HAVE_STRUCT_SCTP_EVENT_SUBSCRIBE_SCTP_SEND_FAILURE_EVENT
    events.sctp_send_failure_event = 1;
#else
    events.sctp_send_failure_event_event = 1;
#endif

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

  if(setsockopt(fileno, IPPROTO_SCTP, SCTP_EVENTS, &events, sizeof(events)) < 0)
    rb_raise(rb_eSystemCallError, "setsockopt: %s", strerror(errno));

  return self;
}

/*
 * Marks the socket referred to by sockfd as a passive socket, i.e. a socket that
 * will be used to accept incoming connection requests.
 *
 * The backlog argument defines the maximum length to which the queue of
 * pending connections for sockfd may grow. The default value is 128. The
 * maximum value is Socket::SOMAXCONN.
 *
 * Why a default of 128? The answer is a "best guess" compromise between
 * handling server load versus avoiding SYN flood attacks. I leave it as an
 * exercise to the programmer to adjust as desired.
 *
 * See https://tangentsoft.com/wskfaq/advanced.html#backlog if you want
 * more details on the advantages and drawbacks of various values.
 *
 * Example:
 *
 *  socket = SCTP::Socket.new
 *  socket.bind(:port => 62534, :addresses => ['127.0.0.1'])
 *  socket.listen
 */
static VALUE rsctp_listen(int argc, VALUE* argv, VALUE self){
  VALUE v_backlog;
  int backlog, fileno;

  rb_scan_args(argc, argv, "01", &v_backlog);

  if(NIL_P(v_backlog))
    backlog = 128;
  else
    backlog = NUM2INT(v_backlog);

  if(backlog > SOMAXCONN)
    rb_raise(rb_eArgError, "backlog value exceeds maximum value of: %i", SOMAXCONN);

  fileno = NUM2INT(rb_iv_get(self, "@fileno"));

  if(listen(fileno, backlog) < 0)
    rb_raise(rb_eSystemCallError, "listen: %s", strerror(errno));
  
  return self;
}

/*
 * Extracts an association contained by a one-to-many socket connection into
 * a one-to-one style socket. Returns the socket descriptor (fileno).
 *
 * Example:
 *
 *   socket = SCTP::Socket.new
 *   # etc...
 *
 *   while true
 *     info = socket.recvmsg
 *     assoc_fileno = socket.peeloff(info.association_id)
 *     # ... Do something with this new
 *   end
 */
static VALUE rsctp_peeloff(VALUE self, VALUE v_assoc_id){
  int fileno, assoc_fileno;
  sctp_assoc_t assoc_id;
    
  fileno = NUM2INT(rb_iv_get(self, "@fileno"));
  assoc_id = NUM2INT(v_assoc_id);

  assoc_fileno = sctp_peeloff(fileno, assoc_id);

  if(assoc_fileno < 0)
    rb_raise(rb_eSystemCallError, "sctp_peeloff: %s", strerror(errno));

  return INT2NUM(assoc_fileno);
}

static VALUE rsctp_get_default_send_params(VALUE self){
  int fileno;
  socklen_t size;
  sctp_assoc_t assoc_id;
  struct sctp_sndrcvinfo sndrcv;

  bzero(&sndrcv, sizeof(sndrcv));

  fileno = NUM2INT(rb_iv_get(self, "@fileno"));
  assoc_id = NUM2INT(rb_iv_get(self, "@association_id"));
  size = sizeof(struct sctp_sndrcvinfo);

  if(sctp_opt_info(fileno, assoc_id, SCTP_DEFAULT_SEND_PARAM, (void*)&sndrcv, &size) < 0)
    rb_raise(rb_eSystemCallError, "sctp_opt_info: %s", strerror(errno));

  return rb_struct_new(
    v_sctp_default_send_params_struct,
    INT2NUM(sndrcv.sinfo_stream),
    INT2NUM(sndrcv.sinfo_ssn),
    INT2NUM(sndrcv.sinfo_flags),
    INT2NUM(sndrcv.sinfo_ppid),
    INT2NUM(sndrcv.sinfo_context),
    INT2NUM(sndrcv.sinfo_timetolive),
    INT2NUM(sndrcv.sinfo_tsn),
    INT2NUM(sndrcv.sinfo_cumtsn),
    INT2NUM(sndrcv.sinfo_assoc_id)
  );
}

static VALUE rsctp_get_association_info(VALUE self){
  int fileno;
  socklen_t size;
  sctp_assoc_t assoc_id;
  struct sctp_assocparams assoc;

  bzero(&assoc, sizeof(assoc));

  fileno = NUM2INT(rb_iv_get(self, "@fileno"));
  assoc_id = NUM2INT(rb_iv_get(self, "@association_id"));
  size = sizeof(struct sctp_assocparams);

  if(sctp_opt_info(fileno, assoc_id, SCTP_ASSOCINFO, (void*)&assoc, &size) < 0)
    rb_raise(rb_eSystemCallError, "sctp_opt_info: %s", strerror(errno));

  return rb_struct_new(
    v_sctp_associnfo_struct,
    INT2NUM(assoc.sasoc_assoc_id),
    INT2NUM(assoc.sasoc_asocmaxrxt),
    INT2NUM(assoc.sasoc_number_peer_destinations),
    INT2NUM(assoc.sasoc_peer_rwnd),
    INT2NUM(assoc.sasoc_local_rwnd),
    INT2NUM(assoc.sasoc_cookie_life)
  );
}

static VALUE rsctp_shutdown(int argc, VALUE* argv, VALUE self){
  int how, fileno;
  VALUE v_how;

  fileno = NUM2INT(rb_iv_get(self, "@fileno"));

  rb_scan_args(argc, argv, "01", &v_how);

  if(NIL_P(v_how)){
    how = SHUT_RDWR;
  }
  else{
    Check_Type(v_how, T_FIXNUM);
    how = NUM2INT(v_how);
  }

  if(shutdown(fileno, how) < 0)
    rb_raise(rb_eSystemCallError, "shutdown: %s", strerror(errno));

  return self;
}

static VALUE rsctp_get_retransmission_info(VALUE self){
  int fileno;
  socklen_t size;
  sctp_assoc_t assoc_id;
  struct sctp_rtoinfo rto;

  bzero(&rto, sizeof(rto));

  fileno = NUM2INT(rb_iv_get(self, "@fileno"));
  assoc_id = NUM2INT(rb_iv_get(self, "@association_id"));
  size = sizeof(struct sctp_rtoinfo);

  if(sctp_opt_info(fileno, assoc_id, SCTP_RTOINFO, (void*)&rto, &size) < 0)
    rb_raise(rb_eSystemCallError, "sctp_opt_info: %s", strerror(errno));

  return rb_struct_new(
    v_sctp_rtoinfo_struct,
    INT2NUM(rto.srto_assoc_id),
    INT2NUM(rto.srto_initial),
    INT2NUM(rto.srto_max),
    INT2NUM(rto.srto_min)
  );
}

/*
 * Get the status of a connected socket.
 *
 * Example:
 *
 *   socket = SCTP::Socket.new
 *   socket.connect(...)
 *   socket.get_status
 *
 * Returns a Struct::Status object, which contains the following fields:
 *
 *  * association_id
 *  * state
 *  * receive_window
 *  * unacknowledged_data
 *  * pending_data
 *  * inbound_streams
 *  * outbound_streams
 *  * fragmentation_point
 *  * primary (IP)
 */
static VALUE rsctp_get_status(VALUE self){
  int fileno;
  socklen_t size;
  sctp_assoc_t assoc_id;
  struct sctp_status status;
  struct sctp_paddrinfo* spinfo;
  char tmpname[INET_ADDRSTRLEN];

  bzero(&status, sizeof(status));

  fileno = NUM2INT(rb_iv_get(self, "@fileno"));
  assoc_id = NUM2INT(rb_iv_get(self, "@association_id"));
  size = sizeof(struct sctp_status);

  if(sctp_opt_info(fileno, assoc_id, SCTP_STATUS, (void*)&status, &size) < 0)
    rb_raise(rb_eSystemCallError, "sctp_opt_info: %s", strerror(errno));

  spinfo = &status.sstat_primary;

  if (spinfo->spinfo_address.ss_family == AF_INET6) {
		struct sockaddr_in6 *sin6;
		sin6 = (struct sockaddr_in6 *)&spinfo->spinfo_address;
		inet_ntop(AF_INET6, &sin6->sin6_addr, tmpname, sizeof (tmpname));
	}
  else {
		struct sockaddr_in *sin;
		sin = (struct sockaddr_in *)&spinfo->spinfo_address;
		inet_ntop(AF_INET, &sin->sin_addr, tmpname, sizeof (tmpname));
  }

  return rb_struct_new(v_sctp_status_struct,
    INT2NUM(status.sstat_assoc_id),
    INT2NUM(status.sstat_state),
    INT2NUM(status.sstat_rwnd),
    INT2NUM(status.sstat_unackdata),
    INT2NUM(status.sstat_penddata),
    INT2NUM(status.sstat_instrms),
    INT2NUM(status.sstat_outstrms),
    INT2NUM(status.sstat_fragmentation_point),
    rb_str_new2(tmpname)
  );
}

static VALUE rsctp_get_subscriptions(VALUE self){
  int fileno;
  socklen_t size;
  sctp_assoc_t assoc_id;
  struct sctp_event_subscribe events;

  bzero(&events, sizeof(events));

  fileno = NUM2INT(rb_iv_get(self, "@fileno"));
  assoc_id = NUM2INT(rb_iv_get(self, "@association_id"));
  size = sizeof(struct sctp_event_subscribe);

  if(sctp_opt_info(fileno, assoc_id, SCTP_EVENTS, (void*)&events, &size) < 0)
    rb_raise(rb_eSystemCallError, "sctp_opt_info: %s", strerror(errno));

  return rb_struct_new(v_sctp_event_subscribe_struct,
    (events.sctp_data_io_event ? Qtrue : Qfalse),
    (events.sctp_association_event ? Qtrue : Qfalse),
    (events.sctp_address_event ? Qtrue : Qfalse),
    (events.sctp_send_failure_event ? Qtrue : Qfalse),
    (events.sctp_peer_error_event ? Qtrue : Qfalse),
    (events.sctp_shutdown_event ? Qtrue : Qfalse),
    (events.sctp_partial_delivery_event ? Qtrue : Qfalse),
    (events.sctp_adaptation_layer_event ? Qtrue : Qfalse),
    (events.sctp_authentication_event ? Qtrue : Qfalse),
    (events.sctp_sender_dry_event ? Qtrue : Qfalse),
    (events.sctp_stream_reset_event ? Qtrue : Qfalse),
    (events.sctp_assoc_reset_event ? Qtrue : Qfalse),
    (events.sctp_stream_change_event ? Qtrue : Qfalse),
    (events.sctp_send_failure_event_event ? Qtrue : Qfalse)
  );
}

void Init_socket(void){
  mSCTP   = rb_define_module("SCTP");
  cSocket = rb_define_class_under(mSCTP, "Socket", rb_cObject);

  v_sndrcv_struct = rb_struct_define(
    "SendReceiveInfo", "message", "stream", "flags",
    "ppid", "context", "ttl", "association_id", "notification", "client", NULL
  );

  v_assoc_change_struct = rb_struct_define(
    "AssocChange", "type", "length", "state", "error",
    "outbound_streams", "inbound_streams", "association_id", "info", NULL
  );

  v_peeraddr_change_struct = rb_struct_define(
    "PeerAddrChange", "type", "length", "ip_address",
    "state", "error", "association_id", "info", NULL
  );

  v_remote_error_struct = rb_struct_define(
    "RemoteError", "type", "length", "error", "association_id", "data", NULL
  );

  v_send_failed_event_struct = rb_struct_define(
    "SendFailedEvent", "type", "length", "error", "association_id", "data", NULL
  );

  v_shutdown_event_struct = rb_struct_define(
    "ShutdownEvent", "type", "length", "association_id", NULL
  );

  v_sndinfo_struct = rb_struct_define(
    "SendInfo", "sid", "flags", "ppid", "context", "association_id", NULL
  );

  v_adaptation_event_struct = rb_struct_define(
    "AdaptationEvent", "type", "length", "adaptation_indication", "association_id", NULL
  );

  v_partial_delivery_event_struct = rb_struct_define(
    "PartialDeliveryEvent", "type", "length", "indication", "stream",
    "sequence_number", "association_id", NULL
  );

  v_auth_event_struct = rb_struct_define(
    "AuthEvent", "type", "length", "key_number", "indication", "association_id", NULL
  );

  v_sockaddr_in_struct = rb_struct_define(
    "SockAddrIn", "family", "port", "address", NULL
  );

  v_sctp_status_struct = rb_struct_define(
    "Status", "association_id", "state", "receive_window", "unacknowledged_data",
    "pending_data", "inbound_streams", "outbound_streams", "fragmentation_point", "primary", NULL
  );

  v_sctp_rtoinfo_struct = rb_struct_define(
    "RetransmissionInfo", "association_id", "initial", "max", "min", NULL
  );

  v_sctp_associnfo_struct = rb_struct_define(
    "AssociationInfo", "association_id", "max_retransmission_count",
    "number_peer_destinations", "peer_receive_window", "local_receive_window",
    "cookie_life", NULL
  );

  v_sctp_default_send_params_struct = rb_struct_define(
    "DefaultSendParams", "stream", "ssn", "flags", "ppid", "context",
    "ttl", "tsn", "cumtsn", "association_id", NULL
  );

  v_sctp_event_subscribe_struct = rb_struct_define(
    "EventSubscriptions", "data_io", "association", "address", "send_failure",
    "peer_error", "shutdown", "partial_delivery", "adaptation_layer",
    "authentication", "sender_dry", "stream_reset", "assoc_reset",
    "stream_change", "send_failure_event", NULL
  );

  v_sctp_receive_info_struct = rb_struct_define(
    "ReceiveInfo", "message", "sid", "ssn", "flags", "ppid", "tsn",
    "cumtsn", "context", "assocation_id", NULL
  );

  rb_define_method(cSocket, "initialize", rsctp_init, -1);

  rb_define_method(cSocket, "bindx", rsctp_bindx, -1);
  rb_define_method(cSocket, "close", rsctp_close, 0);
  rb_define_method(cSocket, "connectx", rsctp_connectx, -1);
  rb_define_method(cSocket, "getpeernames", rsctp_getpeernames, -1);
  rb_define_method(cSocket, "getlocalnames", rsctp_getlocalnames, -1);
  rb_define_method(cSocket, "get_status", rsctp_get_status, 0);
  rb_define_method(cSocket, "get_default_send_params", rsctp_get_default_send_params, 0);
  rb_define_method(cSocket, "get_retransmission_info", rsctp_get_retransmission_info, 0);
  rb_define_method(cSocket, "get_association_info", rsctp_get_association_info, 0);
  rb_define_method(cSocket, "get_subscriptions", rsctp_get_subscriptions, 0);
  rb_define_method(cSocket, "listen", rsctp_listen, -1);
  rb_define_method(cSocket, "peeloff", rsctp_peeloff, 1);
  rb_define_method(cSocket, "recvmsg", rsctp_recvmsg, -1);
  rb_define_method(cSocket, "send", rsctp_send, 1);

#ifdef HAVE_SCTP_SENDV
  rb_define_method(cSocket, "sendv", rsctp_sendv, 1);
#endif

#ifdef HAVE_SCTP_RECVV
  rb_define_method(cSocket, "recvv", rsctp_recvv, -1);
#endif

  rb_define_method(cSocket, "sendmsg", rsctp_sendmsg, 1);
  rb_define_method(cSocket, "set_initmsg", rsctp_set_initmsg, 1);
  rb_define_method(cSocket, "shutdown", rsctp_shutdown, -1);
  rb_define_method(cSocket, "subscribe", rsctp_subscribe, 1);

  rb_define_attr(cSocket, "domain", 1, 1);
  rb_define_attr(cSocket, "type", 1, 1);
  rb_define_attr(cSocket, "fileno", 1, 1);
  rb_define_attr(cSocket, "association_id", 1, 1);
  rb_define_attr(cSocket, "port", 1, 1);

  /* 0.0.6: The version of this library */
  rb_define_const(cSocket, "VERSION", rb_str_new2("0.0.7"));

  /* send flags */

  /* Message is unordered */
  rb_define_const(cSocket, "SCTP_UNORDERED", INT2NUM(SCTP_UNORDERED));

  /* Override the primary address */
  rb_define_const(cSocket, "SCTP_ADDR_OVER", INT2NUM(SCTP_ADDR_OVER));

  /* Send an ABORT to peer */
  rb_define_const(cSocket, "SCTP_ABORT", INT2NUM(SCTP_ABORT));

  /* Start a shutdown procedure */
  rb_define_const(cSocket, "SCTP_EOF", INT2NUM(SCTP_EOF));

  /* Send to all associations */
  rb_define_const(cSocket, "SCTP_SENDALL", INT2NUM(SCTP_SENDALL));

  rb_define_const(cSocket, "MSG_NOTIFICATION", INT2NUM(MSG_NOTIFICATION));

  // ASSOCIATION STATES //

  rb_define_const(cSocket, "SCTP_EMPTY", INT2NUM(SCTP_EMPTY));
  rb_define_const(cSocket, "SCTP_CLOSED", INT2NUM(SCTP_CLOSED));
  rb_define_const(cSocket, "SCTP_COOKIE_WAIT", INT2NUM(SCTP_COOKIE_WAIT));
  rb_define_const(cSocket, "SCTP_COOKIE_ECHOED", INT2NUM(SCTP_COOKIE_ECHOED));
  rb_define_const(cSocket, "SCTP_ESTABLISHED", INT2NUM(SCTP_ESTABLISHED));
  rb_define_const(cSocket, "SCTP_SHUTDOWN_PENDING", INT2NUM(SCTP_SHUTDOWN_PENDING));
  rb_define_const(cSocket, "SCTP_SHUTDOWN_SENT", INT2NUM(SCTP_SHUTDOWN_SENT));
  rb_define_const(cSocket, "SCTP_SHUTDOWN_RECEIVED", INT2NUM(SCTP_SHUTDOWN_RECEIVED));
  rb_define_const(cSocket, "SCTP_SHUTDOWN_ACK_SENT", INT2NUM(SCTP_SHUTDOWN_ACK_SENT));

  // BINDING //

  rb_define_const(cSocket, "SCTP_BINDX_ADD_ADDR", INT2NUM(SCTP_BINDX_ADD_ADDR));
  rb_define_const(cSocket, "SCTP_BINDX_REM_ADDR", INT2NUM(SCTP_BINDX_REM_ADDR));
}
