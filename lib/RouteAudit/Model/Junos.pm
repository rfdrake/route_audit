package RouteAudit::Model::Junos;

use strict;
use warnings;

use RouteAudit::RouteObject;
use Regexp::Common qw /net/;
use v5.24;

my $IP_regex = qr/$RE{net}{IPv4}|$RE{net}{IPv6}/;
my $v4 = $RE{net}{IPv4};

my $route_regex = qr{
^
    routing-options(?:\ rib\ inet6.0)?\ static\ route\ (?<addr>$IP_regex\/\d+)
        (?:\ (?<intf>discard))?
        (?:\ next-hop\ (?<nh>$IP_regex))?
$
}ox;

sub parse_config {
    my ($fh, $rtr) = @_;

    # the trouble with junos is there is more than one way to do things, and more than one place
    # to put a description on an interface.  This will need to be opinionated.  In my case I'm ignoring
    # vlan tags and just using the unit number as a vlan tag

    # none of the junipers we use have annotated routes, so I didn't parse those.

    return parse_lines($rtr,flatten($fh));
}

# this takes the normal juniper config and makes it like "display set".
sub flatten {
    my $fh = shift;
    my @h;
    my $lines;
    while (<$fh>) {
        if (/^(?:\s+)?(.*) \{/) {
            push(@h, $1);
        } elsif (/^(?:\s+)?\}/) {
            pop(@h);
        } elsif (/^(?:\s+)?(.*);$/) {
            push(@$lines,join(' ', @h) . " $1");
        }
    }
    return $lines;
}

sub parse_lines {
    my ($rtr,$lines) = @_;

    my @return;
    foreach my $line (@$lines) {
        if ($line =~ /^interfaces (\S+) unit (\d+) (.*?)$/) {
            my $data = $3;
            my $int = $1;
            my $unit = $2;
            # if the interfaces don't match the previous push it into our return stack
            if (!defined($return[-1]) || (defined($return[-1]) && !($return[-1]->interface() eq $int && $return[-1]->vlan() eq $unit))) {
                # if the previous entry doesn't have an IP address then throw it away.
                if ($return[-1] && !$return[-1]->addr()) {
                    pop(@return);
                }
                push(@return, RouteAudit::RouteObject->new(
                    'type' => 'CONNECTED',
                    'device' => $rtr,
                    'interface' => $int,
                    'vlan' => $unit)
                );
            }
            # parse descriptions and other things
            if ($data =~ /disable/) {
                $return[-1]->shutdown(1);
            } elsif ($data =~ /description (?:"(?<desc>[^"]+)"|(?<desc>\S+))/) {
                $return[-1]->description($+{desc});
            } elsif ($data =~ /family inet(?:6)? address ($IP_regex\/\d+)/) {
                # this misses more than 1 IP on the same interface.  Luckily, the IPs seem to be last in juniper configs so we can clone the object and store the new one.
                if ($return[-1]->addr()) {
                    push(@return, $return[-1]->clone());
                }
                $return[-1]->addr($1);
            }
        } elsif ($line =~ /$route_regex/) {
            # if the previous entry doesn't have an IP address then throw it away.
            if ($return[-1] && !$return[-1]->addr()) {
                pop(@return);
            }
            push(@return, RouteAudit::RouteObject->new(
                'type' => 'STATIC',
                'device' => $rtr,
            ));

            $return[-1]->addr($+{addr}) if ($+{addr});
            $return[-1]->interface($+{intf}) if ($+{intf});
            $return[-1]->nexthop($+{nh}) if ($+{nh});
            $return[-1]->raw($line);
        }
    }
    # if the previous entry doesn't have an IP address then throw it away.
    if ($return[-1] && !$return[-1]->addr()) {
        pop(@return);
    }
    return @return;
}

1;
