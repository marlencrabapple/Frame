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
use subs qw'dmsg json __pkgfn__ callstack refstr';

@EXPORT     = qw(dmsg json __pkgfn__ callstack refstr);
@EXPORT_SUB = qw(@EXPORT);

const our $DEV_MODE   => $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development';
const our $DEBUG_MODE => any { $_ } @ENV{qw'FRAME_DEBUG DEBUG'};

const our %json_default_param =>
  ( utf8 => 1, $DEV_MODE ? ( pretty => 1 ) : () );
const our $json_default => JSON::MaybeXS->new( {%json_default_param} );

const our $package => __PACKAGE__;

# field $loop;
field $app : weak : param : accessor = undef;
field $json : accessor { $Frame::Base::json_default };
field $debug_mode : param : accessor = $DEBUG_MODE;
field $dev_mode   : param : accessor = $DEV_MODE;

field $debug : reader = $ENV{DEBUG} || 1;

field $ddn_uplvl    : param : accessor = 3;
field $trace_indent : param : accessor = $ENV{DEBUG_INDENT}     // 1;
field $skip_frames  : param : accessor = $ENV{DEBUG_SKIPFRAMES} // 1;

ADJUST {
    # $loop = $self->loop;
    $self->import;
};

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

# method loop {
#     $loop //= IO::Async::Loop->new;
#     $loop;
# }

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
