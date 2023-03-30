strongSwan
==========

This docker container runs [strongSwan](https://strongswan.org/) on [alpine Linux](https://alpinelinux.org/).

### Configuration
This cookbook uses two volumes `/etc/ipsec.docker` and `/etc/strongswan.docker`.

* `/etc/ipsec.conf` includes `/etc/ipsec.docker/ipsec.*.conf`
* `/etc/ipsec.secrets` includes `/etc/ipsec.docker/ipsec.*.secrets`
* `/etc/strongswan.conf` includes `/etc/strongswan.docker/*.conf`

So put your configuration files accordingly and mount the needed volumes.

##### iptables
If you need to open up vpn access using iptables INPUT rules add following environment variable **IPTABLES=true** and it will add the following rules:

```
-A INPUT -p esp -j ACCEPT
-A INPUT -p udp -m udp --sport 500 --dport 500 -j ACCEPT
-A INPUT -p udp -m udp --sport 4500 --dport 4500 -j ACCEPT
```

If you want to limit specific hosts or subnets allowed to send data to port 500 and 4500 add the following environment variable **IPTABLES_ENDPOINTS=172.16.10.30/32,172.16.9.35/32**.
If you want to put the rules on specific interface add the following environment variable **IPTABLES_INTERFACE=bond0**.
These two variables will add *-s XXX* and/or *-i XXX* to the iptables rules.


##### ipsec.conf: leftfirewall
If you intend to use `leftfirewall=yes` in your configuration, you should use `leftupdown=sudo -E ipsec _updown iptables` instead. Reason being that *strongSwan* runs *charon* daemon as a non-privileged user. sudo have been setup to allow ipsec group to run the ipsec command.

### Usage

##### download
```bash
docker pull deltaprojects/strongswan
```

##### run
```bash
docker run -d --privileged --net=host \
  -e IPTABLES=true \
  -e IPTABLES_INTERFACE=bond0 \
  -e IPTABLES_ENDPOINTS=169.254.0.10/32 \
  -v '/lib/modules:/lib/modules:ro' \
  -v '/etc/localtime:/etc/localtime:ro' \
  -v '/etc/ipsec.docker:/etc/ipsec.docker:ro' \
  -v '/etc/strongswan.docker:/etc/strongswan.docker:ro' \
  --name strongswan strongswan
```

##### example
This examaple shows a full working example of how to setup a site-to-site vpn against [Google Cloud VPN](https://cloud.google.com/compute/docs/vpn/overview).
On their side I followed their [*Simple setup*](https://cloud.google.com/compute/docs/vpn/creating-vpns#simple_setup) example.

```bash
# cat /etc/ipsec.docker/ipsec.gc.conf
conn googe-cloud-base
  compress=no
  esp=aes128gcm16-aes128gcm12-aes128gcm8-sha1-modp3072-modp2048!
  ike=aes128gcm16-aes128gcm12-aes128gcm8-sha256-modp3072-modp2048,aes128gcm16-aes128gcm12-aes128gcm8-sha1-modp3072-modp2048!
  # automatically inserts iptables-based firewall rules that let pass the tunneled traffic
  leftupdown=sudo -E ipsec _updown iptables
  ikelifetime=10h
  lifetime=3h
  left=%any
  leftid=[LOCAL PUBLIC IP]
  leftsubnet=0.0.0.0/0
  leftauth=psk
  leftikeport=4500

conn vpn01-europe-west1
  auto=start
  right=[GOOGLE VPN IP]
  rightsubnet=10.132.0.0/20,10.133.0.0/20,[COMMA-SEPARATED-LIST-OF-YOUR-GOOGLE-SUBNETS]
  rightauth=psk
  rightikeport=4500
  also=googe-cloud-base
```

```bash
# cat /etc/ipsec.docker/ipsec.gc.secrets
[GOOGLE VPN IP] : PSK "PRE-SHARED-KEY-HERE"
```

```bash
docker run -d --privileged --net=host \
  -e IPTABLES=true \
  -e IPTABLES_INTERFACE=bond0 \
  -e IPTABLES_ENDPOINTS=[GOOGLE VPN IP]/32 \
  -v '/lib/modules:/lib/modules:ro' \
  -v '/etc/localtime:/etc/localtime:ro' \
  -v '/etc/ipsec.docker:/etc/ipsec.docker:ro' \
  --name strongswan strongswan
```

### Contributing

Submit a pull request to https://github.com/deltaprojects/strongswan-docker
