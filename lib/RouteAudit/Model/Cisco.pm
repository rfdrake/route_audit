package RouteAudit::Model::Cisco;

use strict;
use warnings;

use RouteAudit::RouteObject;
use Regexp::Common qw /net/;
use v5.24;

my $IP_regex = qr/$RE{net}{IPv4}|$RE{net}{IPv6}/;
my $v4 = $RE{net}{IPv4};

my $route_regex = qr{
^
    \s{0,2}
    ip(?:v[64])?\ route\ ($IP_regex/\d+|$v4\ $v4)   # match x.x.x.x/24, 1234::1234/64, or x.x.x.x x.x.x.x
        (?:\ (?<intf>[A-Za-z][\w\.\/\-]+))?   # interface
        (?:\ (?<nh>$IP_regex))?             # nexthop
        (?:\ vrf\ (?<vrf>\S+))?
        (?:\ track\ (?<track>\d{1,3}))?
        (?:\ tag\ (?<tag>\d{1,10}))?
        (?:\ name\ (?:"(?<name>[^"]+)"|(?<name>\S+)))?
        (?:\ distance)?                       # on foundry/brocade/ruckus
        (?:\ (?<pref>\d{1,3}))?               # distance
$
}ox;

sub parse_config {
    my ($fh, $rtr) = @_;

    my @return;
    my $context = '';
    my $cdata   = undef;
    my $ips     = undef;
    while (<$fh>) {
        if (/$route_regex/) {
            my $r = RouteAudit::RouteObject->new( 'type' => 'STATIC', 'device' => $rtr );
            $r->addr($1);
            $r->interface($+{intf});
            $r->description($+{name});
            $r->nexthop($+{nh});
            $r->vrf($context) if ($context);
            $r->raw($_);
            push(@return, $r);
        }
        elsif (/^vrf context (\S+)/) {
            $context = $1;
        }
        elsif (/^interface ([A-Za-z][\w\.\/\-]+(?: [\d\/]+)?)/) {
            $ips   = [];
            $cdata = {'shutdown' => 0, 'desc' => '', 'vrf' => '', 'vlan' => '', 'router' => $rtr, 'interface' => $1};
        }
        elsif ($cdata) {
            if (/^\s+?ip(?:v[64])? address ($IP_regex\/\d+|$v4 $v4)/) {
                push(@$ips, $1);
            }
            elsif (/^\s+shutdown/) {
                $cdata->{shutdown} = 1;
            }
            elsif (/^\s+disable/) {
                $cdata->{shutdown} = 1;
            }
            elsif (/^\s+nameif (.*?)$/) {
                $cdata->{desc} = $1;
            }
            elsif (/^\s+description (.*?)$/) {
                $cdata->{desc} = $1;
            }
            elsif (/^\s+vrf member (\S+)/) {
                $cdata->{vrf} = $1;
            }
            elsif (/^\s+vlan (\d+)/) {
                $cdata->{vlan} = $1;
            }
        }

        # this isn't quite accurate.  Context doesn't clear with a blank
        # line, but it should catch context switches and switching to
        # other config statements.  It also catches us leaving an interface
        if (/^!?$/o) {
            if (defined($cdata)) {
                for (@$ips) {
                    my $r = RouteAudit::RouteObject->new( { 'type' => 'CONNECTED', 'device' => $rtr } );
                    $r->addr($_);
                    $r->description($cdata->{desc}) if ($cdata->{desc});
                    $r->vrf($cdata->{vrf}) if ($cdata->{vrf});
                    $r->interface($cdata->{interface}) if ($cdata->{interface});
                    $r->shutdown($cdata->{shutdown}) if ($cdata->{shutdown});
                    push(@return, $r);
                }
                $cdata = undef;
                $ips   = [];
            }
            $context = '';
        }
    }
    return @return;
}

1;
