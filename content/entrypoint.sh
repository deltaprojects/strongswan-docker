#!/bin/sh -e
#
# entrypoint for strongswan
#
# sysctl -w net.ipv4.ip_forward=1
# env |grep vpn_ | while read line; do echo $line| cut -d= -f2- >> /etc/ipsec.d/secrets.local.conf ; done
# exec ipsec start --nofork --conf /etc/ipsec.d/ipsec.conf "$@"


if [[ x${IPTABLES} == 'xtrue' ]]; then
  iptables -A INPUT -i vlan5 -p esp -j ACCEPT
  if [[ -n "${IPTABLES_ENDPOINTS}" ]]; then
    iptables -A INPUT -i vlan5 -p udp -m udp --sport 500 --dport 500 -s ${IPTABLES_ENDPOINTS} -j ACCEPT
    iptables -A INPUT -i vlan5 -p udp -m udp --sport 4500 --dport 4500 -s ${IPTABLES_ENDPOINTS} -j ACCEPT
  else
    iptables -A INPUT -i vlan5 -p udp -m udp --sport 500 --dport 500 -j ACCEPT
    iptables -A INPUT -i vlan5 -p udp -m udp --sport 4500 --dport 4500 -j ACCEPT
  fi
fi

exec ipsec start --nofork "$@"
