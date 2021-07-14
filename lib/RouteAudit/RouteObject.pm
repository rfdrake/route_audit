package RouteAudit::RouteObject;

use strict;
use warnings;
use NetAddr::IP;
use parent 'Clone';

=head1 NAME

RouteAudit::RouteObject - generic object to contain static or connected routes

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $opts = ref($_[0]) eq 'HASH' ? $_[0] : { @_ };
    my $self  = {
        'type'        => 'UNKNOWN',    # connected or static or unknown
        'vrf'         => undef,
        'addr'        => undef,
        'interface'   => undef,
        'device'      => undef,        # this may need to be a required field
        'description' => undef,        # description or route name
        'preference'  => undef,        # route distance or preference
        'shutdown'    => 0,

        # on some devices an interface can have a vlan assigned.
        # Like juniper family inet under unit with vlan-id.
        # Or ASA with vlan \d+, or cisco IOS with encapsulation dot1q \d+
        'vlan'    => undef,
        'nexthop' => undef,
        'raw'     => undef,             # optional, holds raw config line
        %{$opts},
    };

    die "device argument required." if (!defined($self->{device}));

    bless($self, $class);
    return $self;
}

sub type {
    my ($self, $type) = @_;
    return warn "Unknown type: $type" if ($type && $type !~ /^(CONNECTED|STATIC)$/);
    $self->{type} = $type             if ($type);
    return $self->{type};
}

sub shutdown {
    my ($self, $shut) = @_;
    return warn "Unknown shutdown status: $shut" if ($shut && $shut !~ /^[01]$/);
    $self->{shutdown} = $shut                        if ($shut);
    return $self->{shutdown};
}

sub addr {
    my ($self, $addr) = @_;
    $self->{addr} = NetAddr::IP->new($addr) if ($addr);
    return $self->{addr};
}

sub csv {
    my $self = shift;
    return sprintf("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
            $self->device,
            $self->interface ? $self->interface : '',
            $self->addr->network(),
            $self->addr->canon(),
            $self->type,
            $self->description ? $self->description : '',
            $self->nexthop ? $self->nexthop : '',
            $self->vrf ? $self->vrf : '',
            defined($self->vlan) ? $self->vlan : '',
            $self->shutdown eq '1' ? 'TRUE' : 'FALSE');
}

sub TO_JSON {
    my $r = { %{ shift() } };
    # cleanup internal debugging stuff
    delete $r->{raw};
    if (defined($r->{addr})) {
        $r->{network}=$r->{addr}->network()->cidr();
        $r->{addr}=$r->{addr}->cidr();
    }
    return $r;
}

# generate methods for anything that doesn't require validation
for my $method (qw(vrf description interface vlan nexthop preference raw device))
{
    eval <<"HERE" or die $@;
    sub $method {
      my (\$self, \$arg) = (shift, shift);
      \$self->{$method} = \$arg if (\$arg);
      return \$self->{$method};
    }
    1;
HERE
}

1;
