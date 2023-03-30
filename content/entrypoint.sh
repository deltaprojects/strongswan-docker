#!/bin/sh -e
#
# entrypoint for strongswan
#

INTERFACE=${IPTABLES_INTERFACE:+-i ${IPTABLES_INTERFACE}} # will be empty if not set
ENDPOINTS=${IPTABLES_ENDPOINTS:+-s ${IPTABLES_ENDPOINTS}} # will be empty if not set
RIGHTSUBNETS=$(grep rightsubnet /etc/ipsec.docker/ipsec.*.conf | cut -d"=" -f2 | sort | uniq)

# add iptables rules if IPTABLES=true
if [[ x${IPTABLES} == 'xtrue' ]]; then
  iptables -I INPUT ${INTERFACE} -p esp -j ACCEPT
  iptables -I INPUT ${ENDPOINTS} ${INTERFACE} -p udp -m udp --sport 500 --dport 500 -j ACCEPT
  iptables -I INPUT ${ENDPOINTS} ${INTERFACE} -p udp -m udp --sport 4500 --dport 4500 -j ACCEPT
  iptables -t nat -I POSTROUTING -m policy --dir out --pol ipsec -j ACCEPT
  for RIGHTSUBNET in ${RIGHTSUBNETS}; do
    iptables -t nat -I POSTROUTING -s ${RIGHTSUBNET} -j ACCEPT
  done
fi

_revipt() {
  if [[ x${IPTABLES} == 'xtrue' ]]; then
    echo "Removing iptables rules..."
    iptables -D INPUT ${INTERFACE} -p esp -j ACCEPT
    iptables -D INPUT ${ENDPOINTS} ${INTERFACE} -p udp -m udp --sport 500 --dport 500 -j ACCEPT
    iptables -D INPUT ${ENDPOINTS} ${INTERFACE} -p udp -m udp --sport 4500 --dport 4500 -j ACCEPT
    iptables -t nat -D POSTROUTING -m policy --dir out --pol ipsec -j ACCEPT
    for RIGHTSUBNET in ${RIGHTSUBNETS}; do
      iptables -t nat -D POSTROUTING -s ${RIGHTSUBNET} -j ACCEPT
    done
  fi
}

# enable ip forward
sysctl -w net.ipv4.ip_forward=1

# function to use when this script recieves a SIGTERM.
_term() {
  echo "Caught SIGTERM signal! Stopping ipsec..."
  ipsec stop
  # remove iptable rules
  _revipt
}

# catch the SIGTERM
trap _term SIGTERM

echo "Starting strongSwan/ipsec..."
ipsec start --nofork "$@" &

# wait for child process to exit
wait $!

# remove iptable rules
_revipt
