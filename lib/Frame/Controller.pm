use Object::Pad ':experimental(:all)';

package Frame::Controller;
role Frame::Controller : does(Frame::Base);

use utf8;
use v5.40;

use Carp;
use Encode;
use Text::Xslate;
use JSON::MaybeXS;
use Feature::Compat::Try;
use Frame::Request;

our @EXPORT_DOES = qw(template);

our $template_vars = {};

our $tx_default = Text::Xslate->new(
    cache => $ENV{'PLACK_ENV'} && $ENV{'PLACK_ENV'} eq 'development' ? 0 : 1,
    path  => ['view']
);

$^H{ __PACKAGE__ . '/user' } = 1;

APPLY {
    $^H{ __PACKAGE__ . '/user' } = 1;
}

field $req : param : reader : weak;
field $route : param : reader = undef;
field $res : reader;    # :weak;

# field $tx :reader;

ADJUSTPARAMS($params) {
    $res = $req->new_response
}

method template : common ($name, $vars = {}, @args) {
    $tx_default->render( $name, { %$template_vars, %$vars } );
}

method stash { $req->stash }

method render (
    $content,
    $status       = 200,
    $content_type = undef,
    $headers      = [],
    $cookies      = {}, %opts
  )
{
    my $res = $opts{noop} ? $req->new_response : $self->res;
    $content_type = $res->content_type;
    $opts{charset} //= $self->app->charset;

    foreach my $header (@$headers) {
        $res->headers->push_header(%$header);
    }

    $res->cookies->@{ keys %$cookies } = values %$cookies;

    if ( ref $content ) {
        $content_type ||= "application/json; charset=$opts{charset}";

        try {
            $res->content_type($content_type);
            $res->body( json->encode($content) )
        }
        catch ($e) {
            $self->render_500( undef, $content_type, $headers, $cookies, %opts )
        }
    }
    else {
        $res->content_type( $content_type
              // "text/html; charset=$opts{charset}" );
        $res->body($content);
    }

    $res->status($status);
    $res;
}

method render_error ( $content, $status, $content_type = undef, @args ) {
    $content = { status => $status, msg => $content }
      if ( $content_type // $req->maybe_ajax ) =~ Frame::Request::JSONRE;

    $self->render( $content, $status, $content_type, @args );
}

method render_500 ( $content = '500 - Internal server error', @args ) {
    $self->render_error( $content, 500, @args );
}

method render_404 ( $content = '404 - Page not found', @args ) {
    $self->render_error( $content, 404, @args );
}

method render_403 ( $content = '403 - Forbidden', @args ) {
    $self->render_error( $content, 403, @args );
}

method redirect ( $url, $status = 302 ) {
    $res->redirect( $url, $status );
    $res;
}

method url_for ( $name = undef, %vals ) {
    my @path_arr;

    foreach my $path_var ( $route->pattern_arr ) {
        if ( my $key = $route->is_placeholder($path_var) ) {
            croak unless $vals{$key};
            push @path_arr, $vals{$key};
        }
        else {
            push @path_arr, $path_var;
        }
    }

    join '/', @path_arr;
}
