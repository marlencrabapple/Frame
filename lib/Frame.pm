use Object::Pad;

package Frame;
role Frame :does(Frame::Controller);

use v5.36;
use utf8;
use autodie;

use Plack;
use Data::Dumper;
use Carp;

use Frame::Request;
use Frame::Routes;
use Frame::Controller;

field $routes :reader;
field $req :reader;
field $res :reader;
field $request_class :mutator = 'Frame::Request';

ADJUSTPARAMS ( $params ) {
  $self->app($self);
  $routes = Frame::Routes->new(app => $self);
  $self->startup
}

method to_psgi { sub { $self->handler(shift) } }

method handler ($env) {
  # $req = $request_class->new($env);
  # $req->app($self);
  
  $req = Frame::Request->new($env);
  $req->stash = {};
  $res = $req->new_response;
  $self->dispatch;
  $res->finalize
}

method dispatch {
  my $route = $routes->match($req);
  $route ? $route->route($req, $res) : $self->render_404
}

method fatal {
  die Dumper(@_);
}

method startup;

1