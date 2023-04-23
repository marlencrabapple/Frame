use Object::Pad;

package Frame::Routes::Route;
class Frame::Routes::Route :does(Frame::Base);

use utf8;
use v5.36;

use constant PLACEHOLDER_RE => qr/^\:(.+)$/;

field $method :param :reader;
field $pattern :param :reader;
field $dest :param :reader;

field $tree :reader;
field @pattern_arr :reader;
field @placeholders: reader;

ADJUSTPARAMS ($params) {
  @pattern_arr = $pattern->pattern eq '/'
    ? '/'
    : $pattern->pattern =~ /([^\/]+)(?:\/)?/g;

  my $depth = scalar @pattern_arr;
  my $branches = $$tree{$method}{$depth} //= {};
  my $curr = $branches;

  my $prev;
  my $last_key;
  
  foreach my $part (@pattern_arr) {
    $prev = $curr;

    if(my $placeholder = $self->is_placeholder($part)) {
      my $filter = $pattern->filters->{$placeholder};
      $last_key = $filter ? $filter : $$params{factory}->app;
      push @placeholders, $placeholder
    }
    else {
      $last_key = $part
    }

    $$prev{$last_key} = {};
    $curr = $$prev{$last_key}
  }

  $$prev{$last_key} = $self
}

method is_placeholder ($pathstr) {
  ($pathstr =~ PLACEHOLDER_RE)[0]
}

1