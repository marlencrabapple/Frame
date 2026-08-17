use Object::Pad ':experimental(:all)';

package Frame::Util::IP;

class Frame::Util::IP;

use utf8;
use v5.40;

# use Exporter;
use Syntax::Keyword::Dynamically;
use IO::Handle::Common;
use Net::IP;

#use vars '@EXPORT';
use parent 'Exporter';
our @EXPORT = qw'ip';

field $netip : param : accessor = undef;

# method BUILDARGS : common (@arg) {
#     unshift @arg, 'ip', 1;
#     dmsg \@arg;
#     @arg;
# }

sub AUTOLOAD ( $invoke = undef, @arg ) {
    our $AUTOLOAD;

    my $meth = ( $AUTOLOAD =~ s/^.*:://r );
    dmsg $AUTOLOAD, $meth, $invoke, \@arg;

    # $invoke->$meth(@arg);
    die;

    # if ( $invoke->isa($class) && $invoke->can($meth) ) {
    #
    # }
    # elsif ( !$invoke ) {

    #     #   NetAddr::IP
    # }

    # fatal "Cannot use $meth on $invoke";
}

sub ip ( $ip, %opt ) {

    dmsg $ip, \%opt;

    # $ip //= inet_to_ntoa( scalar getbyhostname( $opt{host} ) )
    if ( $opt{host} ) {
        fatal "Parameters \$ip and \$opt{host} are mutually exclusive" if $ip;
        $ip = inet_to_ntoa( scalar getbyhostname( $opt{host} ) );
    }
    my $self = Frame::Util::IP->new( ip => $ip );
    # dmsg $self;
    $self;
}

# method rdns ( $ip = $self->ip, %opt ) {
#     dynamically $self = __PACKAGE__->new($ip) if $ip ne $self->ip;
#     $self->reverse;
# }

# method to_rdns : common ($ip, %opt) {
#     $class->ip( $ip, %opt )->rdns;
# }
