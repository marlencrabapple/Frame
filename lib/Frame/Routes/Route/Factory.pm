use Object::Pad;

package Frame::Routes::Route::Factory;
role Frame::Routes::Route::Factory :does(Frame::Base);

use utf8;
use v5.36;

field $prev_stop :param :accessor :weak = undef;
field $has_stops :param :accessor = undef;
field $patterns :accessor;
field $tree :accessor;

field $routes :reader;
field $stops :reader :param = undef;

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

method under ($pattern, @args) {
  $self->any($pattern, @args, { has_stops => 1 })
}

1