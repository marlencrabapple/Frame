use Object::Pad;

package Frame::Routes::Route;

use v5.36;
use autodie;

use Frame::Routes::Pattern;
use Frame::Routes::Match;

class Frame::Routes::Route :does(Frame::Base) {
  field $method :param :reader;
  field $pattern :param :reader;
  field $filters :param :reader = undef;
  field $dest :reader :param;

  method route($req, $res) {
    my ($c, $sub) = @$dest{qw(c sub)};
    $c->$sub($req->placeholder_values_ord)
  }
}

package Frame::Routes::Route::Factory;

use Frame::Routes::Pattern;
use Frame::Routes::Match;

use Data::Dumper;
use Scalar::Util 'blessed';

role Frame::Routes::Route::Factory :does(Frame::Base) {
  method _add_route ($route);

  method any ($methods, $pattern, @args) {
    my %route_args;

    my $dest = pop @args;

    if(ref $dest eq 'HASH' && scalar @$dest{qw(c sub)}) {
      $route_args{dest} = { %$dest }
    }
    elsif(ref $dest eq 'CODE') {
      $route_args{dest}->{sub} = $dest
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

    if($route_args{dest}->{c}) {
      my $c = blessed($self->app) . '::Controller::' . $route_args{dest}->{c};
      eval "require $c; 1";
      $route_args{dest}->{c} = $c->new(app => $self->app);
      $route_args{dest}->{c}->app($self->app)
    }
    else {
      $route_args{dest}->{c} = $self->app
    }

    die "Invalid route destination '$dest'" unless $route_args{dest}->{sub};

    foreach my $arg (@args) {
      if(ref $arg eq 'CODE') {
        $route_args{filter} = $arg
      }
      elsif(ref $arg eq 'HASH') {
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
}