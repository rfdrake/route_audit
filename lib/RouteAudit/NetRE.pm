package RouteAudit::NetRE;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw ( $IP_regex $v4 );

# super loose IPv6 and IPv4 match.  The matches in Regexp::Common are too slow for what we're doing.
# We can assume the starting config is valid and that there will not be unintentional matches
# in the event that something gets through this, it should fail NetAddr::IP validation
our $IP_regex = qr/\d+\.\d+\.\d+\.\d+|[A-Fa-f0-9]{1,4}:[A-Fa-f0-9:.]+|::/;
our $v4 = qr/\d+\.\d+\.\d+\.\d+/;
