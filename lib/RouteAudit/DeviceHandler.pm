package RouteAudit::DeviceHandler;

use strict;
use warnings;
use Module::Runtime qw ( use_module );
use Carp;

my $aliases = {
    'edgerouter' => 'null',
    'edgemax' => 'null',
    'airos' => 'null',
    'zynos' => 'null',
    'foundry' => 'cisco',
    'asa' => 'cisco',
    'nxos' => 'cisco',
};

=head1 NAME

RouteAudit::DeviceHandler - Module for loading device modules

=head1 SYNOPSIS

  use RouteAudit::DeviceHandler;
  my $ios = RouteAudit::DeviceHandler::load_model('ios');

=head1 METHODS

=head2 load_model

    my $ios = RouteAudit::DeviceHandler::load_model('ios');

Loads the module for the specified device model.

=cut

sub load_model {
    my $model = shift;
    croak if (!defined($model));
    $model = $aliases->{$model} if (defined($aliases->{$model}));

    my $m = 'RouteAudit::Model::' . $model;
    eval { use_module($m); };
    croak "Something went wrong with our load of model $m: $@" if ($@);
    return $m;
}

# handles all the weird perl bullshit to run RouteAudit::Model::ios::parse_config (or whatever)
# returns whatever the command output

sub run {
    my $command = shift;
    &{\&{$command}}(@_);
}

1;