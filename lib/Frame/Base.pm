use Object::Pad ':experimental(:all)';

package Frame::Base;
role Frame::Base;

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

use vars '@EXPORT';
@EXPORT = qw(dmsg json __pkgfn__ callstack refstr);

BEGIN {
    require Exporter;
    our @ISA    = qw(Exporter);
    our @EXPORT = qw(dmsg json __pkgfn__ callstack refstr);
    use vars '@EXPORT';
    $^H{ __PACKAGE__ . '/user' } = 1;
}

const our $DEV_MODE   => $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development';
const our $DEBUG_MODE => any { $_ } @ENV{qw'FRAME_DEBUG DEBUG'};

const our %json_default_param =>
  ( utf8 => 1, $DEV_MODE ? ( pretty => 1 ) : () );
const our $json_default => JSON::MaybeXS->new( {%json_default_param} );

const our $package => __PACKAGE__;

field $app : weak : param : accessor = undef;
field $json : accessor { $Frame::Base::json_default };
field $debug_mode : param : accessor = $DEBUG_MODE;
field $dev_mode   : param : accessor = $DEV_MODE;

APPLY($class_mop) {
    use utf8;
    use v5.44;

    use Exporter 'import';
    our @EXPORT = @{__PACKAGE__::EXPORT};
    $^H{ __PACKAGE__ . '/user' } = 1;

    # my @ret = __PACKAGE__->import;

    # dmsg $class_mop, \@ret;
    # @ret
};

ADJUSTPARAMS {
    use utf8;
    use v5.44;
    use Exporter 'import';
    our @EXPORT = @{__PACKAGE__::EXPORT};
    $^H{ __PACKAGE__ . '/user' } = 1;

    # my @ret = __PACKAGE__->import;

    # dmsg $self, \@ret;
    # @ret;
};

field $debug = $ENV{DEBUG} || 1;

field $ddn_uplvl    : param : accessor = 3;
field $trace_indent : param : accessor = $ENV{DEBUG_INDENT}     // 1;
field $skip_frames  : param : accessor = $ENV{DEBUG_SKIPFRAMES} // 1;

sub epoch( $join = '', %opts ) {
    join $join, Time::HiRes::gettimeofday;
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
