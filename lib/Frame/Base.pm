use Object::Pad ':experimental(:all)';

package Frame::Base;
role Frame::Base;

use utf8;
use v5.40;

use meta;
use Carp;
use Const::Fast;
use Const::Fast::Exporter;
use Devel::StackTrace::WithLexicals;
use PadWalker      qw(peek_my peek_our);
use List::AllUtils qw(singleton any);
use JSON::MaybeXS;
use Data::Dumper;
use Time::Piece;
use Time::HiRes;
use Plack::Util;
use Module::Metadata;
use Syntax::Keyword::Dynamically;
use Syntax::Keyword::Try;

use parent 'Exporter';

our @EXPORT      = qw(dmsg json __pkgfn__ callstack);
our @EXPORT_DOES = @EXPORT;

BEGIN {
    require Exporter;
    our @ISA    = qw(Exporter);
    our @EXPORT = qw(dmsg json __pkgfn__ callstack);
    use subs @EXPORT;
    $^H{ __PACKAGE__ . '/user' } = 1;
}

$^H{ __PACKAGE__ . '/user' } = 1;

const our $DEV_MODE   => $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development';
const our $DEBUG_MODE => any { $_ } @ENV{qw'FRAME_DEBUG DEBUG'};

const our $json_default =>
  JSON::MaybeXS->new( utf8 => 1, $DEV_MODE ? ( pretty => 1 ) : () );

const our $package => __PACKAGE__;

field $app : weak : param : accessor = undef;
field $json;
field $debug_mode : param : accessor = $DEBUG_MODE;
field $dev_mode   : param : accessor = $DEV_MODE;

APPLY($mop) {
    use utf8;
    use v5.40;

    use Exporter 'import';
    our @EXPORT = @{__PACKAGE__::EXPORT};
    $^H{ __PACKAGE__ . '/user' } = 1;

};

ADJUSTPARAMS($params) {
    use utf8;
    use v5.40;

    use Exporter 'import';
    our @EXPORT = @{__PACKAGE__::EXPORT};
    $^H{ __PACKAGE__ . '/user' } = 1;
};

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

sub dmsg : prototype(@) (@msgs) {
    $DEV_MODE || return '';

    my @caller = caller 0;

    my $out = "*** " . localtime->datetime . " - DEBUG MESSAGE ***\n\n";

    {
        local $Data::Dumper::Pad    = "  ";
        local $Data::Dumper::Indent = 1;

        $out .=
            scalar @msgs > 1 ? Dumper(@msgs)
          : ref $msgs[0]     ? Dumper(@msgs)
          :                    eval { my $s = $msgs[0] // 'undef'; "  $s\n" };

        $out .= "\n"
    }

    $out .=
      $ENV{FRAME_DEBUG} && $ENV{FRAME_DEBUG} == 2
      ? join "\n", map { ( my $line = $_ ) =~ s/^\t/  /; "  $line" } split /\R/,
      Devel::StackTrace::WithLexicals->new(
        indent      => 1,
        skip_frames => 1
      )->as_string
      : "at $caller[1]:$caller[2]";

    say STDERR "$out\n";
    $out;
}

const our $S_UNKNOWNERR => 'Internal Server Error';

sub err : prototype($;$%) (
    $msg  = ( $! // $S_UNKNOWNERR ),
    $exit = ( $? ? $? >> 8 : 255 ), %opts
  )
{
    dmsg( { exit => $exit, msg => $msg, opts => \%opts } );

    my $errstr = $msg isa 'ARRAY'
      ? join "\n", map {
        my $str = $_ isa 'HASH' ? $$_{msg} : $_;
        $str = $S_UNKNOWNERR if $str =~ /^[0-9]+$/ && $str == 0;
        $str
      } @$msg
      : $msg;

    die "ERROR: $errstr ($exit)";
}
