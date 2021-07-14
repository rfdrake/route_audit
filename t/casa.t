!RANCID-CONTENT-TYPE: casa
ip route 0.0.0.0/0 172.21.100.1 200
ip route 10.1.1.1/30 172.20.0.2 1
ip route 10.2.3.0/24 null0 2
ip route 10.2.4.0/24 10.1.1.1 2 description "test description"
ip route 10.2.5.0/24 10.1.1.1 5 tag 13
ip route 10.2.6.0/24 10.1.1.1 5 tag 13
ip route 10.2.7.0/24 10.1.1.1 5 tag 13 description test
ip route 10.2.8.0/24 10.1.1.1 5 tag 13 description "long description"
ip route vrf test 10.2.9.0/24 10.1.1.1 5 tag 13 description "long description"
ipv6 route fe80::0/64 fe80::1 7
ipv6 route vrf test fe80::0/64 fe80::1 8
ipv6 route fe80::0/64 null0 3
