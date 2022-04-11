require 'mkmf'

unless have_header('netinet/sctp.h')
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

  $stderr.puts msg
  exit
end

have_library('sctp')
have_func('sctp_sendv', 'netinet/sctp.h')
have_struct_member('struct sctp_event_subscribe', 'sctp_send_failure_event', 'netinet/sctp.h')
create_makefile('sctp/socket')
