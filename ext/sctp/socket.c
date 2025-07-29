#include <ruby.h>
#include <usrsctp.h>
#include <netinet/in.h>
#include <string.h>
#include <stdio.h>
#include <arpa/inet.h>

static VALUE cSCTPSocket;

typedef struct {
    struct socket *sock;
} sctp_socket_wrapper;

static void sctp_socket_free(void *ptr) {
    sctp_socket_wrapper *wrapper = (sctp_socket_wrapper *)ptr;
    if (wrapper->sock) {
        usrsctp_close(wrapper->sock);
    }
    xfree(wrapper);
}

static VALUE sctp_socket_alloc(VALUE klass) {
    sctp_socket_wrapper *wrapper = ALLOC(sctp_socket_wrapper);
    wrapper->sock = NULL;
    return Data_Wrap_Struct(klass, NULL, sctp_socket_free, wrapper);
}

static VALUE sctp_socket_initialize(VALUE self, VALUE port) {
    sctp_socket_wrapper *wrapper;
    Data_Get_Struct(self, sctp_socket_wrapper, wrapper);

    int c_port = NUM2INT(port);
    usrsctp_init(c_port, NULL, NULL);

    wrapper->sock = usrsctp_socket(AF_INET, SOCK_SEQPACKET, IPPROTO_SCTP, NULL, NULL, 0, NULL);
    if (!wrapper->sock) rb_sys_fail("usrsctp_socket");

    return self;
}

static VALUE sctp_socket_bind(VALUE self, VALUE port) {
    sctp_socket_wrapper *wrapper;
    Data_Get_Struct(self, sctp_socket_wrapper, wrapper);

    int c_port = NUM2INT(port);
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(c_port);
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
#ifdef __APPLE__
    addr.sin_len = sizeof(addr);
#endif
    if (usrsctp_bind(wrapper->sock, (struct sockaddr *)&addr, sizeof(addr)) < 0)
        rb_sys_fail("usrsctp_bind");

    return Qtrue;
}

static VALUE sctp_socket_connect(VALUE self, VALUE host, VALUE port) {
    sctp_socket_wrapper *wrapper;
    Data_Get_Struct(self, sctp_socket_wrapper, wrapper);

    const char *c_host = StringValueCStr(host);
    int c_port = NUM2INT(port);
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(c_port);
    addr.sin_addr.s_addr = inet_addr(c_host);
#ifdef __APPLE__
    addr.sin_len = sizeof(addr);
#endif
    if (usrsctp_connect(wrapper->sock, (struct sockaddr *)&addr, sizeof(addr)) < 0)
        rb_sys_fail("usrsctp_connect");

    return Qtrue;
}

static VALUE sctp_socket_send(VALUE self, VALUE data) {
    sctp_socket_wrapper *wrapper;
    Data_Get_Struct(self, sctp_socket_wrapper, wrapper);

    Check_Type(data, T_STRING);
    const char *buf = StringValueCStr(data);
    size_t len = RSTRING_LEN(data);
    int flags = 0;
    ssize_t sent = usrsctp_sendv(wrapper->sock, buf, len, NULL, 0, NULL, 0, SCTP_SENDV_NOINFO, 0);
    if (sent < 0) rb_sys_fail("usrsctp_sendv");
    return INT2NUM(sent);
}

static VALUE sctp_socket_recv(VALUE self, VALUE maxlen) {
    sctp_socket_wrapper *wrapper;
    Data_Get_Struct(self, sctp_socket_wrapper, wrapper);

    long len = NUM2LONG(maxlen);
    char *buf = ALLOC_N(char, len);
    ssize_t recvd = usrsctp_recvv(wrapper->sock, buf, len, NULL, NULL, NULL, NULL, SCTP_RECVV_NOINFO, 0);
    if (recvd < 0) {
        xfree(buf);
        rb_sys_fail("usrsctp_recvv");
    }
    VALUE str = rb_str_new(buf, recvd);
    xfree(buf);
    return str;
}

static VALUE sctp_socket_close(VALUE self) {
    sctp_socket_wrapper *wrapper;
    Data_Get_Struct(self, sctp_socket_wrapper, wrapper);

    if (wrapper->sock) {
        usrsctp_close(wrapper->sock);
        wrapper->sock = NULL;
    }
    usrsctp_finish();
    return Qtrue;
}

static VALUE sctp_socket_setsockopt(VALUE self, VALUE level, VALUE optname, VALUE optval) {
    sctp_socket_wrapper *wrapper;
    Data_Get_Struct(self, sctp_socket_wrapper, wrapper);
    int c_level = NUM2INT(level);
    int c_optname = NUM2INT(optname);
    Check_Type(optval, T_STRING);
    const char *buf = StringValueCStr(optval);
    socklen_t optlen = RSTRING_LEN(optval);
    if (usrsctp_setsockopt(wrapper->sock, c_level, c_optname, buf, optlen) < 0)
        rb_sys_fail("usrsctp_setsockopt");
    return Qtrue;
}

static VALUE sctp_socket_getsockopt(VALUE self, VALUE level, VALUE optname, VALUE optlen) {
    sctp_socket_wrapper *wrapper;
    Data_Get_Struct(self, sctp_socket_wrapper, wrapper);
    int c_level = NUM2INT(level);
    int c_optname = NUM2INT(optname);
    socklen_t c_optlen = NUM2INT(optlen);
    char *buf = ALLOC_N(char, c_optlen);
    socklen_t len = c_optlen;
    if (usrsctp_getsockopt(wrapper->sock, c_level, c_optname, buf, &len) < 0) {
        xfree(buf);
        rb_sys_fail("usrsctp_getsockopt");
    }
    VALUE str = rb_str_new(buf, len);
    xfree(buf);
    return str;
}

static VALUE sctp_socket_shutdown(VALUE self, VALUE how) {
    sctp_socket_wrapper *wrapper;
    Data_Get_Struct(self, sctp_socket_wrapper, wrapper);
    int c_how = NUM2INT(how);
    if (usrsctp_shutdown(wrapper->sock, c_how) < 0)
        rb_sys_fail("usrsctp_shutdown");
    return Qtrue;
}

static VALUE sctp_socket_status(VALUE self) {
    sctp_socket_wrapper *wrapper;
    Data_Get_Struct(self, sctp_socket_wrapper, wrapper);
    struct sctp_status status;
    socklen_t len = sizeof(status);
    if (usrsctp_getsockopt(wrapper->sock, IPPROTO_SCTP, SCTP_STATUS, &status, &len) < 0)
        rb_sys_fail("usrsctp_getsockopt (SCTP_STATUS)");
    VALUE hash = rb_hash_new();
    rb_hash_aset(hash, ID2SYM(rb_intern("assoc_id")), INT2NUM(status.sstat_assoc_id));
    rb_hash_aset(hash, ID2SYM(rb_intern("state")), INT2NUM(status.sstat_state));
    rb_hash_aset(hash, ID2SYM(rb_intern("instrms")), INT2NUM(status.sstat_instrms));
    rb_hash_aset(hash, ID2SYM(rb_intern("outstrms")), INT2NUM(status.sstat_outstrms));
    rb_hash_aset(hash, ID2SYM(rb_intern("rwnd")), INT2NUM(status.sstat_rwnd));
    rb_hash_aset(hash, ID2SYM(rb_intern("unackdata")), INT2NUM(status.sstat_unackdata));
    rb_hash_aset(hash, ID2SYM(rb_intern("penddata")), INT2NUM(status.sstat_penddata));
    rb_hash_aset(hash, ID2SYM(rb_intern("fragmentation_point")), INT2NUM(status.sstat_fragmentation_point));
    return hash;
}

void Init_socket(void) {
    VALUE mSCTP = rb_define_module("SCTP");
    cSCTPSocket = rb_define_class_under(mSCTP, "Socket", rb_cObject);
    rb_define_alloc_func(cSCTPSocket, sctp_socket_alloc);
    rb_define_method(cSCTPSocket, "initialize", sctp_socket_initialize, 1);
    rb_define_method(cSCTPSocket, "bind", sctp_socket_bind, 1);
    rb_define_method(cSCTPSocket, "connect", sctp_socket_connect, 2);
    rb_define_method(cSCTPSocket, "send", sctp_socket_send, 1);
    rb_define_method(cSCTPSocket, "recv", sctp_socket_recv, 1);
    rb_define_method(cSCTPSocket, "close", sctp_socket_close, 0);
    rb_define_method(cSCTPSocket, "setsockopt", sctp_socket_setsockopt, 3);
    rb_define_method(cSCTPSocket, "getsockopt", sctp_socket_getsockopt, 3);
    rb_define_method(cSCTPSocket, "shutdown", sctp_socket_shutdown, 1);
    rb_define_method(cSCTPSocket, "status", sctp_socket_status, 0);
}
