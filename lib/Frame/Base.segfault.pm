use Object::Pad ':experimental(:all)';

package Frame::Base;
role Frame::Base : does(Adjust::Params);

use utf8;
use v5.44;

use Const::Fast;
use List::Util qw(any);
use JSON::MaybeXS;
use Time::HiRes;
use IO::Handle::Common;
use builtin;

use parent 'Exporter';

use vars qw'@EXPORT @EXPORT_OK @EXPORT_SUB @EXPORT_COMMON';
use subs qw'dmsg json __pkgfn__ callstack refstr debug';

@EXPORT     = qw(dmsg json __pkgfn__ callstack refstr);
@EXPORT_SUB = qw(@EXPORT);

const our $DEV_MODE => $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development';

const our $isnum        => qr/^[0-9]+$/;
const our %json_default => ( utf8 => 1 );

ADJUST {
    $self->import;
}

field $loop : reader;
field $app  : weak : param : accessor = undef;
field $json : reader //= JSON::MaybeXS->new( \%json_default );

field $debug //= 0;
ADJUST : params (%param) {
    $debug = IO->debug( $param{debug} );
};
*debug = \&IO::Handle::Common::debug;

field $dev_mode : accessor = $DEV_MODE;
ADJUST : params (:$dev_mode //= $ENV{PLACK_ENV}, %param) {
    if ( $dev_mode eq 'development' ) {
        $self->dev_mode = 1;
        $json->pretty(1);
    }
};

field $ddn_uplvl    : param : accessor = 3;
field $trace_indent : param : accessor = $ENV{DEBUG_INDENT}     // 1;
field $skip_frames  : param : accessor = $ENV{DEBUG_SKIPFRAMES} // 1;

APPLY($class_mop) {
    __PACKAGE__->apply($class_mop)
};

method apply : common ($class_mop) {
    $class->export_sub($class_mop);
    $class->export_common($class_mop);
}

method export_sub : common ($class_mop) {
    foreach my $common (@EXPORT_SUB) {
        $class_mop->add_method( $common, common => 1, \&$common );
    }
}

method export_common : common ($class_mop) {
    my $class = $class_mop->name;
    foreach my $common (@EXPORT_COMMON) {
        $class_mop->add_method( $common, common => 1, sub { $class->$common } );
    }
}

method export_instance {
    ...;
}

method get_loop {
    dmsg $self, $loop, ref $self, refstr($self), $self->isa('Frame');

    return $loop // ( $app ? $app->loop : undef )
      // fatal( "Event loop for " . __CLASS__ . " is not available yet" )
      unless $self->isa('Frame');

    $loop //= IO::Async::Loop->new;
    $loop;
}

sub epoch( $join = '', %opt ) {
    $opt{ms_pad} //= 6;
    my ( $sec, $ms ) = Time::HiRes::gettimeofday;

    $ms = '0' x ( $opt{ms_pad} - length $ms ) . $ms
      if $opt{ms_pad} && $opt{ms_pad} >= 1;

    join $join, $sec, $ms;
}

sub __pkgfn__ ( $class, $pkgname = undef ) {
    $pkgname //= $class;
    "$pkgname.pm" =~ s/::/\//rg;
}

sub callstack ( $class = undef ) {
    my @callstack;
    my $i = 0;

    while ( my @caller = caller $i ) {
        {
            no strict 'refs';
            push @caller, \%{"$caller[0]\::"};
            push @caller, $caller[0]->META() if ${"$caller[0]\::"}{META}
        }

        push @callstack, \@caller;
    }
    continue { $i++ }

    @callstack;
}

sub refstr ($var) {
    builtin::reftype($var) // '';
}

#const our $defaultconfig_inline => <<'...';
#charset = utf8
#...
