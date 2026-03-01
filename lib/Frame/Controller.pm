use Object::Pad ':experimental(:all)';

package Frame::Controller;
role Frame::Controller : does(Frame::Base);

use utf8;
use v5.40;

use Carp;
use Encode;
use Text::Xslate;
use JSON::MaybeXS;
use Syntax::Keyword::Try;
use Syntax::Keyword::Dynamically;
use Const::Fast;

use Frame::Request;

our @EXPORT_DOES = qw(template);
our @EXPORT      = @EXPORT_DOES;

BEGIN {
    require Exporter;
    our @ISA    = qw(Exporter);
    our @EXPORT = qw(dmsg epoch err);
}

const our $tx_default => Text::Xslate->new(
    cache => $ENV{'PLACK_ENV'} && $ENV{'PLACK_ENV'} eq 'development' ? 0 : 1,
    path  => ['view']
);

# method $import : common {
#     $^H{ __PACKAGE__ . '/user' } = 1;
#     $^H{"$class/user"} = 1;
# };

APPLY {
    my $mop = shift;

    use utf8;
    use v5.40;

    use Exporter 'import';
    our @EXPORT = @{__PACKAGE__::EXPORT}
}

field $config ADJUST { $self->config };
field $req   : param : reader : weak;
field $route : param : reader = undef;
field $res   : reader;    # :weak;

ADJUSTPARAMS($params) {
    $res = $req->new_response
}

class Frame::Template::Response : isa(Plack::Response) {
    field $tx : param = $tx_default;

    method render ( $template, $status = 200, %opts ) {
        my $content = $tx->render( $template, delete $opts{template} );

        $self->app->render(
            $content, $status,
            delete $opts{content_type} // 'text/html',
            map { $_ // {} } @opts{qw(headers cookies)}, %opts
        );
    }
};

method template : common ($name, $vars = {}, %opts) {
    $tx_default->render( $name, {%$vars} );
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
    #my $class = __CLASS__;
    my $class = __PACKAGE__;
    carp "An existing response was overwritten by a call to $class->render()."
      . "To disable this warning or change response precedence configure"
      . "'template.default_res' as needed."
      if ( $res && $self->res )
      && ( !$opts{noop} || $config->{'template'}{default_res} );

    #my $res = $opts{noop} ? $req->new_response : $self->res;

    dynamically $res =
      ( $opts{noop} || $config->{template}{default_res} eq 'lifecycle' )
      ? $self->res
      : $res->new_response;

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
