use Object::Pad;

package Frame::Routes::Route::Factory;
role Frame::Routes::Route::Factory :does(Frame::Base);

use utf8;
use v5.36;

method _add_route :required ($route);

method any ($methods, $pattern, @args) {
  $self->_add_route($methods, $pattern, @args)
}

method get ($pattern, @args) {
  $self->any(['GET'], $pattern, @args)
}

method post ($pattern, @args) {
  $self->any(['POST'], $pattern, @args)
}

method put ($pattern, @args) {
  $self->any(['PUT'], $pattern, @args)
}

method patch ($pattern, @args) {
  $self->any(['PATCH'], $pattern, @args)
}

method delete ($pattern, @args) {
  $self->any(['DELETE'], $pattern, @args)
}

method update ($pattern, @args) {
  $self->any(['UPDATE'], $pattern, @args)
}

1