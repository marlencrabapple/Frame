use Object::Pad;

package Frame::Routes::Route;
class Frame::Routes::Route :does(Frame::Routes::Route::Factory);

use utf8;
use v5.36;

use constant PLACEHOLDER_RE => qr/^\:(.+)$/;

# field $method :param :reader;
field $methods :param :reader;
field $pattern :param :reader;
field $dest :param :reader = undef;
field $root :param :reader :weak;
field $limb :reader;
field @pattern_arr :reader;
field @placeholders: reader;

ADJUSTPARAMS ($params) {
  @pattern_arr = $pattern->pattern eq '/'
    ? '/'
    : $pattern->pattern =~ /([^\/]+)(?:\/)?/g;

  my $depth = scalar @pattern_arr;
  my $i = 0; 

  foreach my $method (@$methods) {
    my $branches = $$limb{$method}{$depth} //= {};
    my $curr = $branches;

    my $prev;
    my $last_key;
    
    foreach my $part (@pattern_arr) {
      $prev = $curr;

      if (my $placeholder = $self->is_placeholder($part)) {
        my $filter = $pattern->filters->{$placeholder};
        $last_key = $filter ? $filter : $$params{factory}->app;
        push @placeholders, $placeholder unless $i
      }
      else {
        $last_key = $part
      }

      $$prev{$last_key} = {};
      $curr = $$prev{$last_key}
    }

    $$prev{$last_key} = $self
  }
  continue { $i++ }
}

method add ($methods, $pattern, @args) {
  $root->add($methods, $self->pattern->pattern . $pattern, @args, { prev_stop => $self, has_stops => $self->has_stops })
}

method is_placeholder ($pathstr) {
  ($pathstr =~ PLACEHOLDER_RE)[0]
}

1