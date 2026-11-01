use Object::Pad ':experimental(:all)';

package Frame::Base;
role Frame::Base : does(Adjust::Params);

use utf8;
use v5.44;

use Const::Fast;
use Const::Fast::Exporter;
use PadWalker      qw(peek_my peek_our);
use List::AllUtils qw(singleton any);
use JSON::MaybeXS;
use Time::Piece;
use Time::HiRes;
use Module::Metadata;
use Devel::StackTrace::WithLexicals;
use IO::Handle::Common;
use builtin;

use parent 'Exporter';

use vars qw'@EXPORT @EXPORT_OK @EXPORT_SUB @EXPORT_COMMON';
@EXPORT = qw(dmsg json __pkgfn__ callstack refstr);

const our $isnum        => qr/^[0-9]+$/;
const our %json_default => ( utf8 => 1 );

field $json = JSON::MaybeXS->new( \%json_default );

# field $json {
#     JSON::MaybeXS->new(
#         {
#             $self->is_utf8 ? ( utf8   => 1 ) : (),
#             $self->devmode ? ( pretty => 1 ) : ()
#         }
#     )
# };

field $app : weak : param : accessor = undef;

field $debug : accessor //= 0;
ADJUST : params (%param) {
    $self->import;
    $debug = IO->debug( $param{debug} )
};

*debug = \&IO::Handle::Common::debug;

field $dev_mode : accessor //= $ENV{PLACK_ENV};

ADJUST : params (:$dev_mode //= $ENV{PLACK_ENV}, %param) {
    if ( $dev_mode eq 'development' ) {
        $self->dev_mode = 1;
        $json->pretty(1);
    }
};

field $imported : reader;

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

sub epoch( $join = '', %opt ) {
    my ( $sec, $ms ) = Time::HiRes::gettimeofday;
    $ms = '0' x ( 6 - length $ms ) . $ms if $opt{uniform} // 1;
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
