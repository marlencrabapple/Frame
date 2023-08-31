use Object::Pad;

package Frame::Routes::Route::Factory;
role Frame::Routes::Route::Factory :does(Frame::Base);

use utf8;
use v5.36;

field $eol :param :accessor = undef;
field $inline :param :accessor = undef;
field $prev_stop :param :accessor :weak = undef;
field $has_stops :param :accessor = undef;
field $stops :reader :param = undef;
field $patterns :accessor;
field $tree :accessor;
field $routes :reader;

ADJUST {
  $routes //= [];
  $stops //= [];
  $patterns //= {};
  $tree //= {}
}

method add :required;

method any ($pattern, @args) {
  $self->add([], $pattern, @args)
}

method get ($pattern, @args) {
  $self->add(['GET'], $pattern, @args)
}

method post ($pattern, @args) {
  $self->add(['POST'], $pattern, @args)
}

method put ($pattern, @args) {
  $self->add(['PUT'], $pattern, @args)
}

method patch ($pattern, @args) {
  $self->add(['PATCH'], $pattern, @args)
}

method delete ($pattern, @args) {
  $self->add(['DELETE'], $pattern, @args)
}

method update ($pattern, @args) {
  $self->add(['UPDATE'], $pattern, @args)
}

method options ($pattern, @args) {
  $self->add(['OPTIONS'], $pattern, @args)
}

method ws ($pattern, @args) {
  ...
}

method websocket { $self->ws(@_) }

method under ($pattern, @args) {
  my $opts = ref $args[$#args] eq 'HASH' ? pop @args : {};
  $self->any($pattern, @args, { has_stops => 1, inline => 1, %$opts })
}

1