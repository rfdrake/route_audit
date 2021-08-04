package RouteAudit::Model::Vyos;

use strict;
use warnings;

use RouteAudit::RouteObject;
use Regexp::Common qw /net/;
use v5.24;

my $IP_regex = qr/$RE{net}{IPv4}|$RE{net}{IPv6}/;
my $v4 = $RE{net}{IPv4};

# problem: rancid's vyos commands dump both the commands output and the "config" output.  Meaning we need to ignore one or the other.

# Just like junos we will need to be opionionated.  Which means this module will probably need to be rewritten for other people to use it.

# we happen to not have any static routes in any of our vyos boxes yet.
# also none of them are running ipv6

sub parse_config {
    my ($fh, $rtr) = @_;

    my @return;
    while(<$fh>) {
        if (/^set interfaces (?:ethernet|loopback) (\S+) (.*?)$/) {
            my $data = $2;
            my $int = $1;
            $int =~ s/\'//g;  # remove single quotes
            # if the interfaces don't match the previous push it into our return stack
            if (!defined($return[-1]) || (defined($return[-1]) && !($return[-1]->interface() eq $int))) {
                # if the previous entry doesn't have an IP address then throw it away.
                if ($return[-1] && !$return[-1]->addr()) {
                    pop(@return);
                }
                push(@return, RouteAudit::RouteObject->new(
                    'type' => 'CONNECTED',
                    'device' => $rtr,
                    'interface' => $int)
                );
            }
            # parse descriptions and other things
            if ($data =~ /'disable'/) {
                $return[-1]->shutdown(1);
            } elsif ($data =~ /description (?:'(?<desc>[^']+)'|(?<desc>\S+))/) {
                $return[-1]->description($+{desc});
            } elsif ($data =~ /vif (\d+) address '($IP_regex\/\d+)'/) {
                if ($return[-1]->addr()) {
                    push(@return, $return[-1]->clone());
                }
                $return[-1]->vlan($1);
                $return[-1]->addr($2);
            }
        }
    }
    # if the previous entry doesn't have an IP address then throw it away.
    if ($return[-1] && !$return[-1]->addr()) {
        pop(@return);
    }
    return @return;
}

1;
