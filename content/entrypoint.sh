#!/bin/sh -e
#
# entrypoint for strongswan
#
# sysctl -w net.ipv4.ip_forward=1
# env |grep vpn_ | while read line; do echo $line| cut -d= -f2- >> /etc/ipsec.d/secrets.local.conf ; done
# exec ipsec start --nofork --conf /etc/ipsec.d/ipsec.conf "$@"

INTERFACE=${IPTABLES_INTERFACE:+-i ${IPTABLES_INTERFACE}}
ENDPOINTS=${IPTABLES_ENDPOINTS:+-s ${IPTABLES_ENDPOINTS}}
if [[ x${IPTABLES} == 'xtrue' ]]; then
  iptables -I INPUT ${INTERFACE} -p esp -j ACCEPT
  iptables -I INPUT ${ENDPOINTS} ${INTERFACE} -p udp -m udp --sport 500 --dport 500 -j ACCEPT
  iptables -I INPUT ${ENDPOINTS} ${INTERFACE} -p udp -m udp --sport 4500 --dport 4500 -j ACCEPT
fi

exec ipsec start --nofork "$@"

if [[ x${IPTABLES} == 'xtrue' ]]; then
  iptables -D INPUT ${INTERFACE} -p esp -j ACCEPT
  iptables -D INPUT ${ENDPOINTS} ${INTERFACE} -p udp -m udp --sport 500 --dport 500 -j ACCEPT
  iptables -D INPUT ${ENDPOINTS} ${INTERFACE} -p udp -m udp --sport 4500 --dport 4500 -j ACCEPT
fi
