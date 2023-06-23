use Object::Pad;

package Frame::Request;
class Frame::Request :isa(Plack::Request) :does(Frame::Base);

use utf8;
use v5.36;

use List::Util 'any';
use Hash::Util 'lock_hashref_recurse';

state @ajax_headers_default = qw(X-Robo-Req);

field @ajax_headers :reader;
field $placeholders :reader;
field @placeholders_ord :reader;
field @placeholder_values_ord :reader;
field $stash :reader;

method BUILDARGS :common (%args) {
  (delete $args{env}, 1, %args)
}

ADJUSTPARAMS ($params) {
  $stash = {};
  @ajax_headers = $$params{ajax_headers}->@* if ref $$params{ajax_headers} eq 'ARRAY';
}

method placeholder ($key, $value = undef) {
  if(defined $value && !$$placeholders{$key}) {
    push @placeholders_ord, { $key => $value };
    push @placeholder_values_ord, $value;
    $$placeholders{$key} = $value
  }

  $$placeholders{$key}
}

method set_placeholders (@placeholders) {
  foreach my $placeholder (@placeholders) {
    $self->placeholder(%$placeholder)
  }
  
  # TODO: Benchmark this against Struct::Dumb solution (defined in route, init'd here)
  # lock_hashref_recurse($placeholders)
}

method is_ajax ($fuzzy = 0) {
  $fuzzy ? $self->maybe_ajax : $self->header($ajax_headers_default[0]) ? 1 : 0
}

method maybe_ajax (@headers) {
  $self->is_xhr
    || $self->env->{HTTP_ACCEPT} =~ /application\/json/
    || any { $self->header($_) } (@ajax_headers_default, @ajax_headers, @headers)
}

method is_xhr { ($self->header('X-Requested-With') // '') =~ /^XMLHttpRequest$/i }

method is_websocket {
  ...
}

1