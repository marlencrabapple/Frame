use Object::Pad ':experimental(:all)';

package Frame::Base;
role Frame::Base;

use utf8;
use v5.40;

use parent 'Exporter';

use Carp;
use Const::Fast;
use Const::Fast::Exporter;
use Devel::StackTrace::WithLexicals;
use PadWalker qw(peek_my peek_our);
use List::AllUtils qw(singleton any);
use JSON::MaybeXS;
use Data::Dumper;
use Time::Piece;
use Plack::Util;
use Module::Metadata;
use Syntax::Keyword::Dynamically;
use Syntax::Keyword::Try;

our @EXPORT         = qw(dmsg json __pkgfn__ callstack);
our @EXPORT_DOES    = @EXPORT;

const our $DEV_MODE   => $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development';
const our $DEBUG_MODE => any { $_ } @ENV{qw'FRAME_DEBUG DEBUG'};

#sub _json_default {
#    JSON::MaybeXS->new( utf8 => 1, $dev_mode ? ( pretty => 1 ) : () );
#}

const our $json_default => JSON::MaybeXS->new( utf8 => 1, $DEV_MODE ? ( pretty => 1 ) : () );

const our $package => __PACKAGE__;

state %seen_users  = (
    $package => {
        fn  => { $package->__pkgfn__    => 1 },
        pkg => { $package               => 1 }
    }
);

use subs @EXPORT_DOES;

$^H{ __PACKAGE__ . '/user' } = 1;

field $app : weak : param : accessor = undef;
field $json;
field $debug_mode :param :accessor = $DEBUG_MODE;
field $dev_mode :param :accessor = $DEV_MODE;


APPLY ($mop) {
    my ( $package, $class, $callstack ) =
      ( __PACKAGE__, $mop->name, [ [caller], [ caller 1 ] ] );

    $^H{ $class . '/user' } = 1;

    __PACKAGE__->exports(
        __PACKAGE__,
        sub ( $export, $realsub, @vars ) {
            $package->monkey_patch( $$callstack[0], $export );
        }
    );
};

ADJUSTPARAMS ($params) {

    # $^H{ __CLASS__ . '/user' } = 1;

    my ( $package, $callstack ) =
      ( __PACKAGE__, [ [caller], [ caller 1 ] ] );

    #  $^H{ $class . '/user' } = 1;

    __PACKAGE__->exports(
        __PACKAGE__,
        sub ( $export, $realsub, @vars ) {
            $package->monkey_patch( $$callstack[0], $export );
        }
    );
};

method patch_self : common ($src, $plain_subs) {
    my $meta     = $src->META();
    my $old_hook = ${^HOOK}{require__after};

    $seen_users{$src}{pkg}{$src} = 1;
    $seen_users{$src}{fn}{ __pkgfn__($src) } = 1;

    ${^HOOK}{require__after} = sub ($name) {
        $old_hook->($name) if $old_hook;

        if ( any { $name eq $_ } keys $seen_users{$src}{fn}->%* ) {
            use feature ':5.40';

            $^H{"$src/user"} = 1;

            my $caller = [ caller 1 ];
            $caller->[10]{"$src/user"} = 1;

            __PACKAGE__->compose( $src, $caller );
        }
    };

    $class->exports(
        $src,
        sub ( $export, $realsub, @vars ) {
            use strict 'refs';
            my $og_sub = eval { no strict 'refs'; \&{"$src\::$export"} };
            my $wrapper;

            try {
                my $method_meta = $meta->get_method($export);

                if ( $method_meta->is_common ) {
                    $wrapper = sub {
                        unshift @_, $src;
                        goto $og_sub;
                    }
                }
                else {
                    $wrapper = sub {
                        my @caller      = caller 0;
                        my $caller_vars = peek_my(1);
                        my $_self       = $$caller_vars{'$self'}->$*;
                        my $_class      = ref $_self;
                        my $_meta       = $_self->META();

                        $og_sub = eval {
                            no strict 'refs';
                            \&{"$caller[0]\::$export"};
                        };

                        unshift @_, $_self;
                        goto $og_sub;
                    }
                }

                $class->monkey_patch(
                    $src, $wrapper,
                    name       => $export,
                    patch_self => 1
                )
            }
            catch ($e) {
                $$plain_subs{$export} = 1
            }
        }
    );
}

method json : common {
    $json_default;
}

method exports : common ($src, $cb, @vars) {
    {
        no strict 'refs';
        foreach my $export ( @{"$src\::EXPORT_DOES"} ) {
            use strict 'refs';
            return 0 unless $cb->( $export, $export, @vars );
        }
    }

    1;
}

method monkey_patch : common ($package, $sub, %args) {
    {
        no strict 'refs';
        no warnings 'redefine';

        if ( ref $sub eq 'CODE' ) {
            return -1 unless $args{name};
            return -1 if ${"$package\::"}{ $args{name} } && !$args{patch_self};
            *{"$package\::$args{name}"} = $sub;
        }
        else {
            return -1 if ${"$package\::"}{$sub} && !$args{patch_self};
            *{"$package\::$sub"} = \&{ $class . "::$sub" };
        }
    }

    $args{on_patch}( $args{on_patch_args} )
      if ref $args{on_patch} eq 'CODE';

    1;
}

method __pkgfn__ : common ($pkgname = undef) {
    $pkgname //= $class;
    "$pkgname.pm" =~ s/::/\//rg;
}

method callstack : common {
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

method dmsg : common (@msgs) {
    return '' unless $DEV_MODE;

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

1
