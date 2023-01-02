use Object::Pad;

package Frame;

use v5.36;
use utf8;
use autodie;

use Plack;
use Data::Dumper;

use Frame::Request;
use Frame::Routes;
use Frame::Controller;

role Frame :does(Frame::Controller) {
  field $routes :reader;
  field $req :reader;
  field $res :reader;

  ADJUSTPARAMS ( $params ) {
    $self->app($self);
    $routes = Frame::Routes->new(app => $self);
    $self->startup
  }

  method to_psgi { sub { $self->handler(shift) } }

  method handler ($env) {
    $req = Frame::Request->new($env);
    $res = $req->new_response;
    $self->dbh;
    $self->dispatch;
    $res->finalize
  }

  method dispatch {
    my $route = $routes->match($req);
    $route->route($req, $res)
  }

  method fatal {
    die Dumper(@_);
  }

  method startup;
}
