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
#use Exporter 'import';

#our @EXPORT = qw(template);

state $template_vars_state = {};
our $template_vars = $template_vars_state;

state $tx_default_state = Text::Xslate->new(
  cache => $ENV{'PLACK_ENV'} && $ENV{'PLACK_ENV'} eq 'development' ? 0 : 1,
  path => ['view']
);

our $tx_default = $tx_default_state;

# field $req :reader;
# field $res :reader;
# field $tx :accessor;
# field $charset;

# BUILD {
#   $tx = $tx_default
# }

method template :common { # Class is template filename
  my ($vars, @args) = @_;
  $tx_default->render($class, { %$template_vars, %$vars })
}

# sub template ($template, $vars, @args) {
#   $tx_default->render($template, { %$template_vars, %$vars })
# }

method stash {
  $self->app->req ? $self->app->req->stash : croak 'Stash not available until route dispatch'
}

method render ($content, $status = 200, $content_type = undef, $headers = [], $cookies = {}) {
  my $app = $self->app;
  my $res = $app->res;
  my $res_headers = $res->headers;

  my $charset = $app->charset;
  $content_type //= "text/html; charset=$charset";

  $res->status($status);

  foreach my $header (@$headers) {
    $res_headers->push_header(%$header)
  }

  $res->cookies->@{keys %$cookies} = values %$cookies;

  if(ref $content eq 'HASH') {
    $res->content_type("application/json; charset=$charset");
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