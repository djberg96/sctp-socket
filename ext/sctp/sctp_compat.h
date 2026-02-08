/*
 * sctp_compat.h - Compatibility layer for native kernel SCTP vs usrsctp.
 *
 * This header abstracts the API differences between the native Linux
 * kernel SCTP stack (via netinet/sctp.h) and the userspace SCTP library
 * (usrsctp) so the same C code can work with both backends.
 *
 * Key differences handled:
 *   - Socket descriptor type: int (native) vs struct socket* (usrsctp)
 *   - Ruby VALUE conversion: INT2NUM/NUM2INT vs LONG2NUM/NUM2LONG (64-bit safe)
 *   - All sctp_* and POSIX socket calls mapped to sctp_sys_* wrappers
 *   - Scatter/gather (iov) vs flat buffer (usrsctp_sendv/recvv)
 *   - sctp_sendmsg/sctp_sendmsgx unified into sctp_sys_sendmsg
 *   - sctp_recvmsg wrapped to use usrsctp_recvv
 */
#ifndef SCTP_COMPAT_H
#define SCTP_COMPAT_H

#ifdef HAVE_USRSCTP_H

/* =========================================================================
 * usrsctp backend (primarily for macOS)
 * ========================================================================= */

#include <usrsctp.h>

/*
 * usrsctp removed the deprecated sctp_sndrcvinfo struct; provide a compat
 * definition so the rest of the code can use a single struct throughout.
 * The sctp_sys_send / sctp_sys_recvmsg wrappers translate between this
 * struct and the usrsctp-native sctp_sndinfo / sctp_rcvinfo.
 */
struct sctp_sndrcvinfo {
  uint16_t       sinfo_stream;
  uint16_t       sinfo_ssn;
  uint16_t       sinfo_flags;
  uint32_t       sinfo_ppid;
  uint32_t       sinfo_context;
  uint32_t       sinfo_timetolive;
  uint32_t       sinfo_tsn;
  uint32_t       sinfo_cumtsn;
  sctp_assoc_t   sinfo_assoc_id;
};

/*
 * usrsctp removed the deprecated SCTP_DEFAULT_SEND_PARAM sockopt (0x0b).
 * We define a compat constant that our wrappers will translate into the
 * appropriate SCTP_DEFAULT_SNDINFO call.  The value must not collide with
 * any real usrsctp sockopt, so pick something far away.
 */
#define SCTP_DEFAULT_SEND_PARAM  0xF00D

/*
 * Socket descriptor type: struct socket* for usrsctp
 */
typedef struct socket* sctp_sock_t;

/* Convert between Ruby VALUE and socket descriptor (64-bit pointer safe) */
#define SCTP_FD_TO_NUM(fd)   LONG2NUM((intptr_t)(fd))
#define NUM_TO_SCTP_FD(v)    ((sctp_sock_t)(uintptr_t)NUM2LONG(v))
#define SCTP_FD_INVALID(fd)  ((fd) == NULL)

/* --- Global usrsctp lifecycle --- */

static int _usrsctp_initialized = 0;

static inline void sctp_sys_global_init(void){
  if(!_usrsctp_initialized){
    usrsctp_init(0, NULL, NULL);
    _usrsctp_initialized = 1;
  }
}

/* --- Socket operations --- */

static inline sctp_sock_t sctp_sys_socket(int domain, int type, int protocol){
  sctp_sys_global_init();
  return usrsctp_socket(domain, type, protocol, NULL, NULL, 0, NULL);
}

/* usrsctp_close returns void, wrap to return int for uniform error handling */
static inline int sctp_sys_close(sctp_sock_t fd){
  usrsctp_close(fd);
  return 0;
}

#define sctp_sys_listen(fd, bl)   usrsctp_listen(fd, bl)
#define sctp_sys_shutdown(fd, h)  usrsctp_shutdown(fd, h)

/* --- Socket options --- */

#define sctp_sys_setsockopt(fd, level, name, val, len) \
    usrsctp_setsockopt(fd, level, name, val, len)
#define sctp_sys_getsockopt(fd, level, name, val, len) \
    usrsctp_getsockopt(fd, level, name, val, len)

/* --- SCTP-specific operations (1:1 mappings) --- */

#define sctp_sys_bindx(fd, addrs, num, flags)       usrsctp_bindx(fd, addrs, num, flags)
#define sctp_sys_connectx(fd, addrs, num, assoc)    usrsctp_connectx(fd, addrs, num, assoc)
#define sctp_sys_peeloff(fd, assoc)                 usrsctp_peeloff(fd, assoc)
#define sctp_sys_getpaddrs(fd, assoc, addrs)        usrsctp_getpaddrs(fd, assoc, addrs)
#define sctp_sys_getladdrs(fd, assoc, addrs)        usrsctp_getladdrs(fd, assoc, addrs)
#define sctp_sys_freepaddrs(addrs)                  usrsctp_freepaddrs(addrs)
#define sctp_sys_freeladdrs(addrs)                  usrsctp_freeladdrs(addrs)
#define sctp_sys_opt_info(fd, assoc, opt, arg, sz)  usrsctp_opt_info(fd, assoc, opt, arg, sz)

/* --- sendv wrapper ---
 * Native sctp_sendv uses iov+iovlen; usrsctp_sendv uses buf+len.
 * This wrapper concatenates iov entries if needed.
 */
static inline ssize_t sctp_sys_sendv(sctp_sock_t fd, const struct iovec* iov, int iovcnt,
    struct sockaddr* addrs, int addrcnt, void* info, socklen_t infolen,
    unsigned int infotype, int flags)
{
  if(iovcnt == 1){
    return usrsctp_sendv(fd, iov[0].iov_base, iov[0].iov_len,
        addrs, addrcnt, info, infolen, infotype, flags);
  }

  /* Multiple iov entries: concatenate into a single buffer */
  size_t total = 0;
  int i;
  ssize_t result;
  char* buf;

  for(i = 0; i < iovcnt; i++)
    total += iov[i].iov_len;

  buf = (char*)malloc(total);

  if(!buf){
    errno = ENOMEM;
    return -1;
  }

  {
    size_t offset = 0;
    for(i = 0; i < iovcnt; i++){
      memcpy(buf + offset, iov[i].iov_base, iov[i].iov_len);
      offset += iov[i].iov_len;
    }
  }

  result = usrsctp_sendv(fd, buf, total,
      addrs, addrcnt, info, infolen, infotype, flags);
  free(buf);
  return result;
}

/* --- recvv wrapper ---
 * Native sctp_recvv uses iov; usrsctp_recvv uses buf+len.
 * Assumes iovcnt == 1 (which is how this library uses it).
 */
static inline ssize_t sctp_sys_recvv(sctp_sock_t fd, const struct iovec* iov, int iovcnt,
    struct sockaddr* from, socklen_t* fromlen,
    void* info, socklen_t* infolen, unsigned int* infotype, int* flags)
{
  (void)iovcnt;
  return usrsctp_recvv(fd, iov[0].iov_base, iov[0].iov_len,
      from, fromlen, info, infolen, infotype, flags);
}

/* --- getsockname wrapper ---
 * usrsctp doesn't have getsockname(); use usrsctp_getladdrs() instead.
 */
static inline int sctp_sys_getsockname(sctp_sock_t fd, struct sockaddr* addr, socklen_t* addrlen){
  struct sockaddr* addrs = NULL;
  int n = usrsctp_getladdrs(fd, 0, &addrs);
  socklen_t copy_len;

  if(n <= 0)
    return -1;

  if(addrs->sa_family == AF_INET6)
    copy_len = sizeof(struct sockaddr_in6);
  else
    copy_len = sizeof(struct sockaddr_in);

  if(copy_len > *addrlen)
    copy_len = *addrlen;

  memcpy(addr, addrs, copy_len);
  *addrlen = copy_len;
  usrsctp_freeladdrs(addrs);

  return 0;
}

/* --- sctp_send wrapper ---
 * usrsctp doesn't have sctp_send(); map to usrsctp_sendv with SCTP_SENDV_SNDINFO.
 */
static inline ssize_t sctp_sys_send(sctp_sock_t fd, const void* msg, size_t len,
    const struct sctp_sndrcvinfo* sinfo, int flags)
{
  struct sctp_sndinfo sndinfo;
  memset(&sndinfo, 0, sizeof(sndinfo));

  if(sinfo){
    sndinfo.snd_sid = sinfo->sinfo_stream;
    sndinfo.snd_flags = sinfo->sinfo_flags;
    sndinfo.snd_ppid = sinfo->sinfo_ppid;
    sndinfo.snd_context = sinfo->sinfo_context;
    sndinfo.snd_assoc_id = sinfo->sinfo_assoc_id;
  }

  return usrsctp_sendv(fd, msg, len, NULL, 0,
      &sndinfo, sizeof(sndinfo), SCTP_SENDV_SNDINFO, flags);
}

/* --- sctp_sendmsg wrapper ---
 * Unified interface: takes addrcnt (count of addresses), not byte length.
 * usrsctp doesn't have sctp_sendmsg(); map to usrsctp_sendv with SCTP_SENDV_SPA.
 */
static inline ssize_t sctp_sys_sendmsg(sctp_sock_t fd, const void* msg, size_t len,
    struct sockaddr* to, int addrcnt,
    uint32_t ppid, uint32_t flags, uint16_t stream, uint32_t ttl, uint32_t context)
{
  struct sctp_sendv_spa spa;
  memset(&spa, 0, sizeof(spa));

  spa.sendv_sndinfo.snd_sid = stream;
  spa.sendv_sndinfo.snd_flags = flags;
  spa.sendv_sndinfo.snd_ppid = ppid;
  spa.sendv_sndinfo.snd_context = context;
  spa.sendv_flags = SCTP_SEND_SNDINFO_VALID;

  if(ttl > 0){
    spa.sendv_prinfo.pr_policy = SCTP_PR_SCTP_TTL;
    spa.sendv_prinfo.pr_value = ttl;
    spa.sendv_flags |= SCTP_SEND_PRINFO_VALID;
  }

  return usrsctp_sendv(fd, msg, len, to, addrcnt,
      &spa, sizeof(spa), SCTP_SENDV_SPA, 0);
}

/* --- sctp_recvmsg wrapper ---
 * usrsctp doesn't have sctp_recvmsg(); map to usrsctp_recvv and translate
 * the rcvinfo back into an sctp_sndrcvinfo structure.
 */
static inline ssize_t sctp_sys_recvmsg(sctp_sock_t fd, void* buf, size_t len,
    struct sockaddr* from, socklen_t* fromlen,
    struct sctp_sndrcvinfo* sinfo, int* msg_flags)
{
  struct sctp_rcvinfo rcvinfo;
  socklen_t infolen = sizeof(rcvinfo);
  unsigned int infotype = 0;
  ssize_t n;

  /* Ensure rcvinfo is returned */
  int on = 1;
  usrsctp_setsockopt(fd, IPPROTO_SCTP, SCTP_RECVRCVINFO, &on, sizeof(on));

  memset(&rcvinfo, 0, sizeof(rcvinfo));

  n = usrsctp_recvv(fd, buf, len, from, fromlen,
      &rcvinfo, &infolen, &infotype, msg_flags);

  if(n >= 0 && sinfo != NULL){
    memset(sinfo, 0, sizeof(*sinfo));
    if(infotype == SCTP_RECVV_RCVINFO){
      sinfo->sinfo_stream = rcvinfo.rcv_sid;
      sinfo->sinfo_ssn = rcvinfo.rcv_ssn;
      sinfo->sinfo_flags = rcvinfo.rcv_flags;
      sinfo->sinfo_ppid = rcvinfo.rcv_ppid;
      sinfo->sinfo_tsn = rcvinfo.rcv_tsn;
      sinfo->sinfo_cumtsn = rcvinfo.rcv_cumtsn;
      sinfo->sinfo_context = rcvinfo.rcv_context;
      sinfo->sinfo_assoc_id = rcvinfo.rcv_assoc_id;
    }
  }

  return n;
}

#else

/* =========================================================================
 * Native kernel SCTP backend (Linux, FreeBSD, etc.)
 * ========================================================================= */

#include <netinet/sctp.h>

/*
 * Socket descriptor type: int file descriptor for native SCTP
 */
typedef int sctp_sock_t;

/* Convert between Ruby VALUE and socket descriptor */
#define SCTP_FD_TO_NUM(fd)   INT2NUM(fd)
#define NUM_TO_SCTP_FD(v)    NUM2INT(v)
#define SCTP_FD_INVALID(fd)  ((fd) < 0)

/* No-op for native SCTP */
static inline void sctp_sys_global_init(void){}

/* --- Socket operations: direct pass-through --- */

#define sctp_sys_socket(domain, type, proto)  socket(domain, type, proto)
#define sctp_sys_close(fd)        close(fd)
#define sctp_sys_listen(fd, bl)   listen(fd, bl)
#define sctp_sys_shutdown(fd, h)  shutdown(fd, h)

/* --- Socket options --- */

#define sctp_sys_setsockopt  setsockopt
#define sctp_sys_getsockopt  getsockopt
#define sctp_sys_getsockname getsockname

/* --- SCTP operations: direct pass-through --- */

#define sctp_sys_bindx       sctp_bindx
#define sctp_sys_connectx    sctp_connectx
#define sctp_sys_peeloff     sctp_peeloff
#define sctp_sys_getpaddrs   sctp_getpaddrs
#define sctp_sys_getladdrs   sctp_getladdrs
#define sctp_sys_freepaddrs  sctp_freepaddrs
#define sctp_sys_freeladdrs  sctp_freeladdrs
#define sctp_sys_opt_info    sctp_opt_info
#define sctp_sys_sendv       sctp_sendv
#define sctp_sys_recvv       sctp_recvv
#define sctp_sys_send        sctp_send
#define sctp_sys_recvmsg     sctp_recvmsg

/* --- sctp_sendmsg wrapper ---
 * Unified interface: always takes addrcnt (count), not byte length.
 * On BSD, maps to sctp_sendmsgx (which takes count).
 * On Linux, maps to sctp_sendmsg (which takes byte length), so we compute it.
 */
static inline ssize_t sctp_sys_sendmsg(sctp_sock_t fd, const void* msg, size_t len,
    struct sockaddr* to, int addrcnt,
    uint32_t ppid, uint32_t flags, uint16_t stream, uint32_t ttl, uint32_t context)
{
#ifdef BSD
  return sctp_sendmsgx(fd, msg, len, to, addrcnt, ppid, flags, stream, ttl, context);
#else
  socklen_t tolen = 0;

  if(to != NULL){
    if(to->sa_family == AF_INET6)
      tolen = addrcnt * sizeof(struct sockaddr_in6);
    else
      tolen = addrcnt * sizeof(struct sockaddr_in);
  }

  return sctp_sendmsg(fd, msg, len, to, tolen, ppid, flags, stream, ttl, context);
#endif
}

#endif /* HAVE_USRSCTP_H */
#endif /* SCTP_COMPAT_H */
