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
    ssize_t sent = usrsctp_sendv(wrapper->sock, buf, len, NULL, 0, NULL, 0, SCTP_SENDV_NOINFO, 0, flags);
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
}
