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

VALUE convert_sockaddr_in_to_struct(struct sockaddr_in* addr){
  char ipbuf[16];

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
  VALUE v_sock_fd = rb_iv_get(self, "@sock_fd");

  if(close(NUM2INT(v_sock_fd)))
    rb_raise(rb_eSystemCallError, "close: %s", strerror(errno));

  return self;
}

/*
 *  Return an array of all addresses of a peer.
 */
static VALUE rsctp_getpeernames(VALUE self){
  sctp_assoc_t assoc_id;
  struct sockaddr* addrs;
  int i, sock_fd, num_addrs;
  char str[16];
  VALUE v_array = rb_ary_new();

  bzero(&addrs, sizeof(addrs));

  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));
  assoc_id = NUM2INT(rb_iv_get(self, "@association_id"));

  num_addrs = sctp_getpaddrs(sock_fd, assoc_id, &addrs);

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
 */
static VALUE rsctp_getlocalnames(VALUE self){
  sctp_assoc_t assoc_id;
  struct sockaddr* addrs;
  int i, sock_fd, num_addrs;
  char str[16];
  VALUE v_array = rb_ary_new();

  bzero(&addrs, sizeof(addrs));

  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));
  assoc_id = NUM2INT(rb_iv_get(self, "@association_id"));

  num_addrs = sctp_getladdrs(sock_fd, assoc_id, &addrs);

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

/*
 * Transmit a message to an SCTP endpoint. The following hash of options
 * is permitted:
 *
 *  :message -> The message to send to the endpoint. Mandatory.
 *  :stream  -> The SCTP stream number you wish to send the message on.
 *  :to      -> An array of addresses to send the message to.
 *  :context -> The default context used for the sendmsg call if the send fails.
 *  :ppid    -> The payload protocol identifier that is passed to the peer endpoint. 
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
 *   - Message data was received. On by default.
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
 * By default only data_io is subscribed to.
 *
 * Example:
 * 
 *   socket = SCTP::Socket.new
 *
 *   socket.bind(:port => port, :addresses => ['127.0.0.1'])
 *   socket.subscribe(:shutdown => true, :send_failure => true)
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

  // Use the new version
  if(RTEST(rb_hash_aref2(v_options, "send_failure")))
    events.sctp_send_failure_event_event = 1;

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

/*
 * Marks the socket referred to by sockfd as a passive socket, i.e. a socket that
 * will be used to accept incoming connection requests.
 *
 * The backlog argument defines the maximum length to which the queue of
 * pending connections for sockfd may grow. The default is 1024.
 *
 * Example:
 *
 *  socket = SCTP::Socket.new
 *  socket.bind(:port => 62534, :addresses => ['127.0.0.1'])
 *  socket.listen
 *
 */
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

/*
 * Extracts an association contained by a one-to-many socket connection into
 * a one-to-one style socket. Note that this modifies the underlying sock_fd.
 */
static VALUE rsctp_peeloff(VALUE self, VALUE v_assoc_id){
  int sock_fd, new_sock_fd;
  sctp_assoc_t assoc_id;
    
  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));
  assoc_id = NUM2INT(v_assoc_id);

  new_sock_fd = sctp_peeloff(sock_fd, assoc_id);

  if(new_sock_fd < 0)
    rb_raise(rb_eSystemCallError, "sctp_peeloff: %s", strerror(errno));

  rb_iv_set(self, "@sock_fd", INT2NUM(new_sock_fd));

  return self;
}

static VALUE rsctp_shutdown(int argc, VALUE* argv, VALUE self){
  int how, sock_fd;
  VALUE v_how;

  sock_fd = NUM2INT(rb_iv_get(self, "@sock_fd"));

  rb_scan_args(argc, argv, "01", &v_how);

  if(NIL_P(v_how)){
    how = SHUT_RDWR;
  }
  else{
    Check_Type(v_how, T_FIXNUM);
    how = NUM2INT(v_how);
  }

  if(shutdown(sock_fd, how) < 0)
    rb_raise(rb_eSystemCallError, "shutdown: %s", strerror(errno));

  return self;
}

void Init_socket(){
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

  rb_define_method(cSocket, "initialize", rsctp_init, -1);

  rb_define_method(cSocket, "bind", rsctp_bind, -1);
  rb_define_method(cSocket, "close", rsctp_close, 0);
  rb_define_method(cSocket, "connect", rsctp_connect, -1);
  rb_define_method(cSocket, "getpeernames", rsctp_getpeernames, 0);
  rb_define_method(cSocket, "getlocalnames", rsctp_getlocalnames, 0);
  rb_define_method(cSocket, "listen", rsctp_listen, -1);
  rb_define_method(cSocket, "peeloff!", rsctp_peeloff, 1);
  rb_define_method(cSocket, "recvmsg", rsctp_recvmsg, -1);
  rb_define_method(cSocket, "sendmsg", rsctp_sendmsg, 1);
  rb_define_method(cSocket, "set_initmsg", rsctp_set_initmsg, 1);
  rb_define_method(cSocket, "shutdown", rsctp_shutdown, -1);
  rb_define_method(cSocket, "subscribe", rsctp_subscribe, 1);

  rb_define_attr(cSocket, "domain", 1, 1);
  rb_define_attr(cSocket, "type", 1, 1);
  rb_define_attr(cSocket, "sock_fd", 1, 1);
  rb_define_attr(cSocket, "association_id", 1, 1);
  rb_define_attr(cSocket, "port", 1, 1);

  /* 0.0.4: The version of this library */
  rb_define_const(cSocket, "VERSION", rb_str_new2("0.0.3"));

  /* send flags */

  rb_define_const(cSocket, "SCTP_UNORDERED", INT2NUM(SCTP_UNORDERED));
  rb_define_const(cSocket, "SCTP_ADDR_OVER", INT2NUM(SCTP_ADDR_OVER));
  rb_define_const(cSocket, "SCTP_ABORT", INT2NUM(SCTP_ABORT));
  rb_define_const(cSocket, "SCTP_EOF", INT2NUM(SCTP_EOF));
  rb_define_const(cSocket, "SCTP_SENDALL", INT2NUM(SCTP_SENDALL));
}
