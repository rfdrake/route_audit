package RouteAudit::Model::routeros;

use strict;
use warnings;

use RouteAudit::RouteObject;
use Regexp::Common qw /net/;
use v5.24;

my $IP_regex = qr/$RE{net}{IPv4}|$RE{net}{IPv6}/;
my $v4 = $RE{net}{IPv4};

my $connected_regex = qr{
^
    add\ address=($IP_regex(?:\/\d+)?)
    (?:\ disabled=(?<disabled>\S+))?
    (?:\ comment=(?:"(?<name>[^"]+)"|(?<name>\S+)))?
    (?:\ interface=(?:"(?<intf>[^"]+)"|(?<intf>\S+)))?
    (?:\ network=(?<network>$IP_regex))?
$
}ox;
my $route_regex = qr{
^
    add
    (?:\ disabled=(?<disabled>\S+))?
    (?:\ comment=(?:"(?<name>[^"]+)"|(?<name>\S+)))?
    (?:\ distance=(?<pref>\d+))?
    (?:\ dst-address=(?<addr>$IP_regex\/\d+))?
    (?:\ gateway=(?<nh>$IP_regex))?
    (?:\ routing-mark=(?<mark>\S+))?
$
}ox;


sub parse_config {
    my ($fh, $rtr) = @_;

    my @return;
    my $inaddress=0;
    my $inroute=0;
    while (<$fh>) {
        if (/\/ip address/) {
           $inaddress=1;
        } elsif (/\/ip route/) {
           $inroute=1;
        } elsif (/^\//) {
           $inaddress=0;
           $inroute=0;
        } elsif ($inaddress && /$connected_regex/) {
           my $r = RouteAudit::RouteObject->new( { 'type' => 'CONNECTED', 'device' => $rtr } );
           my $addr = $1;
           my $int = $+{intf};
           my $name = $+{name};
           my $network = $+{network};
           my $shut = $+{disabled};
           # mikrotik always shows cidr unless it's a /32 or /31.  To distinguish between the
           # two you need to look at the network.
           if ($addr !~ qr{/}) {
                if ($network ne $addr) {
                    $addr = "$addr/31";
                }
           }
           $r->addr($addr);
           $r->interface($int);
           $r->description($name);
           $r->shutdown(1) if ($shut);
           push(@return, $r);
        } elsif ($inroute && /$route_regex/) {
            my $r = RouteAudit::RouteObject->new( { 'type' => 'STATIC', 'device' => $rtr } );
            if (!($+{addr})) {
                $r->addr('0.0.0.0/0');
            } else {
                $r->addr($+{addr});
            }
            $r->nexthop($+{nh}) if ($+{nh});
            $r->description($+{name}) if ($+{name});
            $r->preference($+{pref}) if ($+{pref});
            $r->shutdown(1) if ($+{disabled});
            push(@return, $r);
        }

    }
    return @return;
}

1;
