use Object::Pad;

package Frame::Controller;
role Frame::Controller :does(Frame::Base);

use utf8;
use v5.36;
use autodie;

use Encode;
use Text::Xslate;
use JSON::MaybeXS;
use Data::Dumper;

state $tx_default = Text::Xslate->new(
  cache => $ENV{'PLACK_ENV'} && $ENV{'PLACK_ENV'} eq 'development' ? 0 : 1,
  path => ['view']
);

# field $tx :accessor;

# BUILD {
#   $tx = $tx_default
# }

method template :common {
  my @args = @_;
  $tx_default->render($class, @args)
}

method render ($content, $status = 200, $content_type = 'text/html; charset=utf-8') {
  my $app = $self->app;
  $app->res->status($status);

  if(ref $content eq 'HASH') {
    $app->res->content_type('application/json; charset=utf-8');
    $app->res->body(encode_json($content))
  }
  else {
    $app->res->content_type($content_type);
    $app->res->body($content)
  }
}

method render_404 {
  $self->render('Page not found', 404)
}

1