package RouteAudit::Model::Casa;

use strict;
use warnings;

use RouteAudit::RouteObject;
use RouteAudit::NetRE qw ( $IP_regex $v4 );
use v5.24;

# technically routes to interface look like this:
# ip route 10.0.0.0/24 ip-bundle 1 1
# where the first one is the interface number and the second is the distance.
# they also have some interfaces like null0 which do not have a number.
# I'm not capturing real casa interface routes because I don't use them.
my $route_regex = qr{
^
    ip(?:v[64])?\ route
        (?:\ vrf\ (?<vrf>\S+))?
        \ ($IP_regex/\d+|$v4\ $v4)   # match x.x.x.x/24, 1234::1234/64, or x.x.x.x x.x.x.x
        (?:\ (?<intf>null0))?     # interface
        (?:\ (?<nh>$IP_regex))?   # nexthop
        (?:\ \d{1,3})               # distance (i think is always required on casa)
        (?:\ tag\ (?<tag>\d{1,10}))?
        (?:\ description\ (?:"(?<name>[^"]+)"|(?<name>\S+)))?
}ox;

sub parse_config {
    my ($fh, $rtr) = @_;

    my @return;
    while (<$fh>) {
        if (/$route_regex/) {
            # if the previous entry doesn't have an IP address then throw it away.
            if ($return[-1] && !$return[-1]->addr()) {
                pop(@return);
            }
            my $r = RouteAudit::RouteObject->new( 'type' => 'STATIC', 'device' => $rtr );
            $r->addr($2);
            $r->interface($+{intf});
            $r->description($+{name});
            $r->nexthop($+{nh});
            $r->vrf($+{vrf}) if ($+{vrf});
            $r->raw($_);
            push(@return, $r);
        }
        elsif (/^interface (\S+) ([\d\/]+)(?: switched)?/) {
            # if the previous entry doesn't have an IP address then throw it away.
            if ($return[-1] && !$return[-1]->addr()) {
                pop(@return);
            }
            push(@return, RouteAudit::RouteObject->new(
                    'type' => 'CONNECTED',
                    'device' => $rtr,
                    'interface' => "$1 $2")
                );
        }
        elsif (/^  shutdown/) {
            $return[-1]->shutdown(1);
        }
        elsif (/^  description (?:"(?<desc>[^"]+)"|(?<desc>\S+))/) {
            $return[-1]->description($+{desc});
        }
        elsif (/^  ip address ($IP_regex) ($IP_regex)/) {
            if ($return[-1]->addr()) {
                push(@return, $return[-1]->clone());
            }
            $return[-1]->addr("$1/$2");
        }
    }
    # if the previous entry doesn't have an IP address then throw it away.
    if ($return[-1] && !$return[-1]->addr()) {
        pop(@return);
    }
    return @return;
}

1;
