# CoreDNS

The [CoreDNS](https://coredns.io) image provides a DNS service with multiple aspects enabled through plugins. This image builds [CoreDNS from source](https://github.com/coredns/coredns) and provides the basic configuration stubs that are useful deployed in a cluster and as a complete home DNS service. CoreDNS uses a plug-in architecture:
[Zonw Files Explained](http://www.steves-internet-guide.com/dns-zones-explained/)
**Plugins**

- **[kubernetes](https://coredns.io/plugins/kubernetes/)** - cluster dynamic name resolution
- **[file](https://coredns.io/plugins/file/)** - system name resolution using a zone file insidedescribing a private LAN
- **[hosts](https://coredns.io/plugins/hosts/)** - Serving zones from a `/etc/hosts` file.
- **[forward](https://coredns.io/plugins/forward/)** - local dns access for internet name resolution

## Notes

### Blacklist
CoreDNS could be used to provide a blacklist to block domains (i.e. advertising and tracking sites). This is intended to dynamically pull from publicly maintained black lists.

**Blacklists**
- [The Big Blocklist Collection](https://firebog.net)
- [Steven Black's Hosts File](https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts)
- [AdAway](https://adaway.org/hosts.txt)
-

### Corefile
CoreDNS is generally configured using the `Corefile`. For example:
```
.:53 {
...
        kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
        }
        file /etc/coredns/zone.example.local example.local
        hosts /etc/coredns/hosts {
          no_reverse
          fallthrough
        }
        forward . tls://1.1.1.1 tls://1.0.0.1 {
          tls_servername tls.cloudflare-dns.com
        }
...
```

### Plugins

#### kubernetes
The **kubernetes** plug-in provides an automatic dns lookup for services in a kubernetes cluster.  Services can be accessed via the name pattern `[SERVICE].[NAMESAPCE].svc.cluster.local`.

This service is intended to run inside of a microk8s kubernetes cluster; as such the environment variables (`KUBERNETES_SERVICE_HOST` and `KUBERNETES_SERVICE_PORT`) must be set to get the plugin working properly when running inside a non-k8s environment.

**Error Message**
```
plugin/kubernetes: unable to load in-cluster configuration, KUBERNETES_SERVICE
_HOST and KUBERNETES_SERVICE_PORT must be defined
```

**Example**
```
docker run --env KUBERNETES_SERVICE_HOST=192.168.4.200 \
           --env KUBERNETES_SERVICE_PORT=16443 -it --rm \
           --name coredns coredns:build
```

#### file
The **file** plug-in provides a mechanism to provide for a [DNS Zone](https://help.dyn.com/how-to-format-a-zone-file/). A DNS Zone is defined as text based zone file.

This is used to provide the **.local zone** for a local network. This is provided as configuration file `/etc/container/zone.[DOMAIN].local`.

**Example**
```
$ORIGIN [DOMAIN].local.
@                      3600 SOA ns.domain.tld. (
                                zone-admin.dyndns.com.     ; address of responsible party
                                2016072701                 ; serial number
                                3600                       ; refresh period
                                600                        ; retry period
                                604800                     ; expire time
                                1800                     ) ; minimum ttl
                       60 A     192.168.0.2
                       3600 TXT   "zone for [DOMAIN].local"
printer                60 A     192.168.0.10
mackbookpro1           60 A     192.168.0.10
```

#### hosts
The [hosts plug-in](https://coredns.io/plugins/hosts/) serves zone information from a flat [hosts file](https://www.man7.org/linux/man-pages/man5/hosts.5.html). This file should follow the format `IP_address canonical_hostname [aliases...]`

This is used to provide the **blacklist** domains that should override and direct the traffic into a **blackhole**.

**Example**
```
# The following lines are desirable for IPv4 capable hosts
127.0.0.1       localhost
192.168.1.10    example.com            example

# The following lines are desirable for IPv6 capable hosts
::1                     localhost ip6-localhost ip6-loopback
fdfc:a744:27b5:3b0e::1  example.com example
```

#### forward
The [forward plugin](https://coredns.io/plugins/forward/) re-uses already opened sockets to the upstreams. It supports UDP, TCP and DNS-over-TLS and uses in band health checking.

**Upstream Servers**
- [Cloudflare](https://www.cloudflare.com): 1.1.1.1,1.0.0.1,tls.cloudflare-dns.com
- [Google](https://www.google.com): 8.8.8.8,4.4.4.4
- [OpenDNS](https://www.opendns.com): 208.67.222.123,208.67.220.123
- [DNSWatch](https://www.dnswatch.info): 84.200.69.80,84.200.70.40
- [quad9](https://www.quad9.net): 9.9.9.9,149.112.112.112

### Testing
For [manual testing](https://www.a2hosting.com/kb/getting-started-guide/internet-and-networking/troubleshooting-dns-with-dig-and-nslookup) use the CLI tool `dig`.
```
dig @172.0.0.1 test1.example.local
```
**Response**
```
; <<>> DiG 9.10.6 <<>> @127.0.0.1 kubernetes01.gautier.local
; (1 server found)
;; global options: +cmd
;; Got answer:
;; WARNING: .local is reserved for Multicast DNS
;; You are currently testing what happens when an mDNS query is leaked to DNS
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 11619
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;test1.example.local.    IN      A

;; ANSWER SECTION:
test1.example.local. 30  IN      A       192.168.0.1

;; Query time: 20 msec
;; SERVER: 127.0.0.1#53(127.0.0.1)
;; WHEN: Fri Sep 09 14:26:38 EDT 2022
;; MSG SIZE  rcvd: 97
```

## References
- [How to disable systemd-resolved in Ubuntu?](https://askubuntu.com/questions/907246/how-to-disable-systemd-resolved-in-ubuntu)
- [Deploying a DNS Server Using Docker](http://www.damagehead.com/blog/2015/04/28/deploying-a-dns-server-using-docker/)
- [Beginner's Guide to BIND](https://linuxtechlab.com/configuring-dns-server-using-bind/)
- [named Manual Page](https://linux.die.net/man/8/named)
- https://www.dns-reverse.net/testing-reverse-dns-with-dig-command/


ff
