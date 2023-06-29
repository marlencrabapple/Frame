use Object::Pad;

package Frame::Controller;
role Frame::Controller :does(Frame::Base);

use utf8;
use v5.36;

# use parent 'Exporter';

use Carp;
use Encode;
use Text::Xslate;
use JSON::MaybeXS;
use Feature::Compat::Try;

our @EXPORT_DOES = qw(template);

our $template_vars = {};

our $tx_default = Text::Xslate->new(
  cache => $ENV{'PLACK_ENV'} && $ENV{'PLACK_ENV'} eq 'development' ? 0 : 1,
  path => ['view']
);

$^H{__PACKAGE__ . '/user'} = 1;

Frame::Base->compose(__PACKAGE__, [caller 0], patch_self => 1);

field $req :param :reader :weak;
field $route :param :reader = undef;
field $res :reader; # :weak;
# field $tx :reader;

ADJUSTPARAMS ($params) {
  $res = $req->new_response
}

method template :common ($name, $vars = {}, @args) {
  $tx_default->render($name, { %$template_vars, %$vars })
}

method stash { $req->stash }

method render ($content, $status = 200, $content_type = undef, $headers = [], $cookies = {}) {
  my $res_headers = $res->headers;
  my $charset = $self->app->charset;

  $res->status($status);

  foreach my $header (@$headers) {
    $res_headers->push_header(%$header)
  }

  $res->cookies->@{keys %$cookies} = values %$cookies;

  if(ref $content eq 'HASH') {
    $res->content_type($res->content_type || "application/json; charset=$charset");
    $res->body(json->encode($content))
  }
  else {
    $content_type //= $res->content_type || "text/html; charset=$charset";
    $res->content_type($content_type);
    $res->body($content)
  }

  $res
}

method render_404 ($content = '404 - Page not found') {
  $self->render($content, 404)
}

method render_403 ($content = '403 - Forbidden') {
  $self->render($content, 403)
}

method redirect ($url, $status = 302) {
  $res->redirect($url, $status);
  $res
}

method url_for ($name = undef, %vals) {
  my @path_arr;

  foreach my $path_var ($route->pattern_arr) {
    if (my $key = $route->is_placeholder($path_var)) {
      croak unless $vals{$key};
      push @path_arr, $vals{$key}
    }
    else {
      push @path_arr, $path_var
    }
  }

  join '/', @path_arr
}

1
