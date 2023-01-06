use Object::Pad;

package Frame::Controller;
role Frame::Controller :does(Frame::Base);

use utf8;
use v5.36;
use autodie;

use Carp;
use Encode;
use Text::Xslate;
use JSON::MaybeXS;
use Data::Dumper;

state $tx_default = Text::Xslate->new(
  cache => $ENV{'PLACK_ENV'} && $ENV{'PLACK_ENV'} eq 'development' ? 0 : 1,
  path => ['view']
);

# field $req :reader;
# field $res :reader;
# field $tx :accessor;

# BUILD {
#   $tx = $tx_default
# }

method template :common {
  my @args = @_;
  $tx_default->render($class, @args)
}

method stash {
  $self->app->req ? $self->app->req->stash : croak 'Stash not available until route dispatch.'
}

method render ($content, $status = 200, $content_type = 'text/html; charset=utf-8', $headers = [], $cookies = {}) {
  my $app = $self->app;
  my $res = $app->res;
  my $res_headers = $res->headers;

  $res->status($status);

  foreach my $header (@$headers) {
    $res_headers->push_header(%$header)
  }

  $res->cookies->@{keys %$cookies} = values %$cookies;

  if(ref $content eq 'HASH') {
    $res->content_type('application/json; charset=utf-8');
    $res->body(encode_json($content))
  }
  else {
    $res->content_type($content_type);
    $res->body($content)
  }
}

method render_404 {
  $self->render('Page not found', 404)
}

method redirect ($url, $status = 302) {
  $self->app->res->redirect($url, $status)
}

1