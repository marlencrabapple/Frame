use Object::Pad;

package Frame::Routes::Route::Factory;
role Frame::Routes::Route::Factory :does(Frame::Base);

use utf8;
use v5.36;

use Frame::Routes::Route;
use Frame::Routes::Pattern;

use Carp;
use Scalar::Util 'blessed';

field $patterns :reader;
field $tree :reader;

ADJUSTPARAMS ($params) {
  $patterns //= {};
  $tree //= {}
}

method _add_route :required ($route);

method any ($methods, $pattern, @args) {
  my %route_args = ( factory => $self->app );
  my $dest = pop @args;

  if(ref $dest eq 'HASH' && scalar @$dest{qw(c sub)}) {
    $route_args{dest} = { %$dest }
  }
  elsif(ref $dest eq 'CODE') {
    $route_args{dest}{sub} = $dest
  }
  else {
    my ($c, $sub) = $dest =~ /^(?:([\w\-]+)(?:#))?([\w]+)$/;
    $c = join '::', map { ucfirst $_ } split '-', $c;

    if($sub) {
      $route_args{dest} = {
        sub => $sub,
        c => $c
      }
    }
  }

  if($route_args{dest}{c}) {
    my $c = $self->app->controller_namespace . '::' . $route_args{dest}{c};

    eval "require $c; 1" or die $@;

    my $sub = $route_args{dest}{sub};
    $c->can($route_args{dest}{sub}) || $c->$sub;

    $route_args{dest}{c} = $c
  }

  die "Invalid route destination '$dest'" unless $route_args{dest}{sub};

  foreach my $arg (@args) {
    if(ref $arg eq 'CODE') {
      $route_args{filter} = $arg
    }
    elsif(ref $arg eq 'HASH') {
      @$patterns{(values %$arg)} = (values %$arg);
      $route_args{pattern} = Frame::Routes::Pattern->new(
        pattern => $pattern,
        filters => $arg
      )
    }
  }

  $route_args{pattern} //= Frame::Routes::Pattern->new(pattern => $pattern);

  foreach my $method (@$methods) {
    my $route = Frame::Routes::Route->new(%route_args, method => $method);
    $self->_add_route($route)
  }
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