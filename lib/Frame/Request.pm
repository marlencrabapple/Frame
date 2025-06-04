use Object::Pad;

package Frame::Request;
class Frame::Request :isa(Plack::Request) :does(Frame::Base);

use utf8;
use v5.40;

use List::Util 'any';
use Hash::Util 'lock_hashref_recurse';

use constant JSONSTR => 'application/json';
use constant JSONRE => qr/^${\JSONSTR}/;
use constant XHRRE => qr/^XMLHttpRequest$/i;

our @ajax_headers_default = qw(X-Robo-Req);

field @ajax_headers :reader :writer = @ajax_headers_default;
field $placeholders :reader;
field @placeholders_ord :reader;
field @placeholder_values_ord :reader;
field $stash :reader = {};

method BUILDARGS :common (%args) {
  ( delete $args{env}, 1, %args )
}

ADJUSTPARAMS ($params) {
  push @ajax_headers, $$params{ajax_headers}->@*
    if ref $$params{ajax_headers} eq 'ARRAY';
}

method placeholder ($key, $value = undef) {
  if (defined $value && !$$placeholders{$key}) {
    push @placeholders_ord, { $key => $value };
    push @placeholder_values_ord, $value;
    $$placeholders{$key} = $value
  }

  $$placeholders{$key}
}

method set_placeholders (@placeholders) {
  # untie $placeholders;
  # untie @placeholders_ord;
  # untie @placeholder_values_ord;

  foreach my $placeholder (@placeholders) {
    $self->placeholder(%$placeholder)
  }

  # TODO: Benchmark this against Struct::Dumb solution (defined in
  # route, init'd here)
  # lock_hashref_recurse($placeholders)
}

method is_ajax ($fuzzy = 0) {
  $fuzzy ? $self->maybe_ajax : $self->header($ajax_headers_default[0]) ? 1 : 0
}

method maybe_ajax (@headers) {
  $self->is_xhr
    || $self->env->{HTTP_ACCEPT} =~ JSONRE
    || any { $self->header($_) } (@ajax_headers, @headers)
}

method is_xhr { ($self->header('X-Requested-With') // '') =~ XHRRE }

method is_websocket {
  ...
}
