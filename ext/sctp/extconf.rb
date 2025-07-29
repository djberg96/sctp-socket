require 'mkmf'

dir_config('sctp')

unless have_header('usrsctp.h')
  os = IO.readlines('/etc/os-release').first.split('=').last
  msg = "\nSCTP HEADERS NOT FOUND. PLEASE INSTALL THEM FIRST LIKE SO:\n\n"

  if os =~ /red|fedora|centos/i
    msg << "#####################################################################################\n"
    msg << "# dnf install lksctp-tools                                                          #\n"
    msg << "# dnf install kernel-modules-extra                                                  #\n"
    msg << "#                                                                                   #\n"
    msg << "# sed -e '/blacklist sctp/s/^b/#b/g' -i /etc/modprobe.d/sctp-blacklist.conf         #\n"
    msg << "# sed -e '/blacklist sctp/s/^b/#b/g' -i /etc/modprobe.d/sctp_diag-blacklist.conf    #\n"
    msg << "#                                                                                   #\n"
    msg << "# sudo systemctl restart systemd-modules-load.service                               #\n"
    msg << "#####################################################################################\n"
  else
    msg << "sudo apt-get install libsctp-dev lksctp-tools\n\n"
  end

  warn msg
  exit
end

header = 'usrsctp.h'

have_library('usrsctp')

have_header('sys/param.h')

have_func('sctp_sendv', header)
have_func('sctp_recvv', header)

have_struct_member('struct sctp_event_subscribe', 'sctp_send_failure_event', header)
have_struct_member('struct sctp_event_subscribe', 'sctp_stream_reset_event', header)
have_struct_member('struct sctp_event_subscribe', 'sctp_assoc_reset_event', header)
have_struct_member('struct sctp_event_subscribe', 'sctp_stream_change_event', header)
have_struct_member('struct sctp_event_subscribe', 'sctp_send_failure_event_event', header)

have_struct_member('struct sctp_send_failed_event', 'ssfe_length', header)

have_struct_member('union sctp_notification', 'sn_auth_event', header)

have_const('SCTP_EMPTY', header)

create_makefile('sctp/socket')
