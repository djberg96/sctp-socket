#!/usr/bin/env bash
set -euo pipefail

cd /app

# Install gems into an isolated path so host files are untouched
if ! bundle check >/dev/null 2>&1; then
  bundle install
fi

# Enable SCTP and auth support
modprobe sctp 2>/dev/null || true
sysctl -w net.sctp.auth_enable=1 >/dev/null 2>&1 || true

# Set up dummy interfaces for multihoming tests
if command -v ip >/dev/null 2>&1; then
  ip link show dummy1 >/dev/null 2>&1 || ip link add dummy1 type dummy
  ip link show dummy2 >/dev/null 2>&1 || ip link add dummy2 type dummy
  ip addr add 1.1.1.1/24 dev dummy1 2>/dev/null || true
  ip addr add 1.1.1.2/24 dev dummy2 2>/dev/null || true
  ip link set dummy1 up
  ip link set dummy2 up
  ip link show dummy1
  ip link show dummy2
else
  echo "ip utility not found; cannot configure dummy interfaces" >&2
  exit 1
fi

exec bundle exec rake spec
