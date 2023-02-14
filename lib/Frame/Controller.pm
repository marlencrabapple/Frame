use Object::Pad;

package Frame::Controller;
role Frame::Controller :does(Frame::Base);

use utf8;
use v5.36;

use Encode;
use Text::Xslate;
use JSON::MaybeXS;
# use Exporter 'import';
use Feature::Compat::Try;

state $template_vars = {};

state $tx_default = Text::Xslate->new(
  cache => $ENV{'PLACK_ENV'} && $ENV{'PLACK_ENV'} eq 'development' ? 0 : 1,
  path => ['view']
);

field $app :param :weak;
field $req :param :reader :weak;
field $res :reader; # :weak;

ADJUSTPARAMS ($params) {
  $res = $req->new_response
}

method template :common { # Class is template filename
  my ($vars, @args) = @_;
  $tx_default->render($class, { %$template_vars, %$vars })
}

method stash { $req->stash }

method render ($content, $status = 200, $content_type = undef, $headers = [], $cookies = {}) {
  my $res_headers = $res->headers;
  my $charset = $app->charset;

  $res->status($status);

  foreach my $header (@$headers) {
    $res_headers->push_header(%$header)
  }

  $res->cookies->@{keys %$cookies} = values %$cookies;

  if(ref $content eq 'HASH') {
    $res->content_type($res->content_type || "application/json; charset=$charset");
    $res->body(encode_json($content))
  }
  else {
    $content_type //= $res->content_type || "text/html; charset=$charset";
    $res->content_type($content_type);
    $res->body($content)
  }

  $res
}

method render_404 {
  $self->render('Page not found', 404)
}

method redirect ($url, $status = 302) {
  $res->redirect($url, $status)
}

1
