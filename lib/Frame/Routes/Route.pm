use Object::Pad;

package Frame::Routes::Route;

class Frame::Routes::Route : does(Frame::Routes::Common);

use utf8;
use v5.40;

use Const::Fast;

const our $PATTERN_RE     => qr/([^\/]+)(?:\/)?/;
const our $PLACEHOLDER_RE => qr/^\:(.+)$/;
const our $NAME_RE        => qr/[\W]/;

# field $method :param :reader;
field $methods : param : reader;
field $pattern : param : reader;
field $filter : param : reader = undef;
field $dest : param : reader   = undef;
field $name : param : accessor = undef;
field $root : param : reader : weak;

# field $limb :reader;
field @pattern_arr : reader;
field @placeholders : reader;

ADJUSTPARAMS($params) {
    @pattern_arr =
      $pattern->pattern eq '/'
      ? '/'
      : $pattern->pattern =~ /$PATTERN_RE/g;

    $name //= $pattern->pattern =~ s/$NAME_RE//gr;

    my $depth = scalar @pattern_arr - 1;
    my $i     = 0;

    foreach my $method (@$methods) {
        my $branches = $self->tree->{$method}[$depth] //= {};
        my $curr     = $branches;

        my $prev;
        my $last_key;

        foreach my $part (@pattern_arr) {
            $prev = $curr;

            if ( my $placeholder = $self->is_placeholder($part) ) {
                my $filter = $pattern->filters->{$placeholder};
                $last_key = $filter ? $filter : $$params{factory}->app;
                push @placeholders, $placeholder unless $i;
            }
            else {
                $last_key = $part;
            }

            $$prev{$last_key} = {};
            $curr = $$prev{$last_key};
        }

        $$prev{$last_key} = $self;
    }
    continue { $i++ }
}

method add ( $methods, $pattern, @args ) {
    $root->add( $methods, $self->pattern->pattern . $pattern,
        @args, { prev_stop => $self, has_stops => $self->has_stops } );
}

method is_placeholder ($pathstr) {
    ( $pathstr =~ $PLACEHOLDER_RE )[0];
}

1
