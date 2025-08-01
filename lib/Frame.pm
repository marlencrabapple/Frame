use Object::Pad qw/:experimental(:all)/;

package Frame;
role Frame : does(Frame::Base);

our $VERSION = '0.01.5';

use utf8;
use v5.40;

use Encode;
use TOML::Tiny qw(from_toml to_toml);
use Path::Tiny;
use Const::Fast;
use Data::Dumper;
use IO::Async::Loop;
use Net::Async::HTTP;
use Syntax::Keyword::Try;

use Frame::Config;
use Frame::Routes;
use Frame::Request;
use Frame::Controller::Default;

const our $config_default => $Frame::Config::config_default;

field $loop : reader;
field $ua : reader;
field $routes : reader;
field $config : reader : inheritable;
field $charset : reader                      = 'utf-8';
field $request_class : param                 = 'Frame::Request';
field $controller_namespace : param : reader = undef;
field $default_controller_class              = 'Frame::Controller::Default';
field $default_controller_meta;

ADJUSTPARAMS ($params) {
    unshift @INC, $INC[1];
    $self->app($self);

    #my $class = __CLASS__;

    $loop = IO::Async::Loop->new;    # This grabs the existing loop
    $ua   = Net::Async::HTTP->new;
    $loop->add($ua);

    Frame::Base->dmsg(
        { config => $config, config_default => $config_default } );

    $charset       = $$config{charset}       if $$config{charset};
    $request_class = $$config{request_class} if exists $$config{request_class};

    $controller_namespace //=
      exists $$config{controller_namespace}
      ? $$config{controller_namespace}
      : __CLASS__ . '::Controller';

    try {
        my $fn = __CLASS__ . '/Controller.pm';
        require "$fn";

        my $meta = Object::Pad::MOP::Class->create_class(
            __CLASS__ . "::Controller::$self",
            isa => $default_controller_class
        );

        $meta->add_role( __CLASS__ . '::Controller' );
        $meta->seal;

        $default_controller_meta  = $meta;
        $default_controller_class = $meta->name
    }
    catch ($e) {
        Frame::Base->dmsg( e => $e )
    }

    $routes = Frame::Routes->new( app => $self );

    my %startup_opts = ( params => $params,
                         app    => $self
                         routes => $routes );

    my $ret = $self->startup(%startup_opts);

    warn __CLASS__ . "$\::startup did not return a valid value: '$ret'."
      . " Valid values"
      . "are 1 or the instance of the class its called on."
          unless $ret == 1 || ( ref $ret && $ret == $self )

    $ret
}

method to_psgi {
    sub { $self->handler(shift) }
}

method to_app {
    &to_psgi
}

method handler ($env) {
    my $req = $request_class->new( app => $self, env => $env );
    my $res = $self->dispatch($req);

    utf8::encode( $res->[2][0] )
      if $res->[2][0] =~ /[^\x00-\xff]/g;

    $res;
}

method dispatch ($req) {
    my $res;

    if ( my $match = $routes->match($req) ) {
        if ( $match isa 'Plack::Response' ) {
            $res = $match->finalize;
        }
        elsif ( $match isa 'Frame::Routes::Route' ) {
            $res = $self->route( $match, $req )->finalize;
        }
    }
    else {
        $res = $default_controller_class
          ->new( app => $self, req => $req )
          ->render_404->finalize;
    }

    $res;
}

method route ( $route, $req ) {
    my ( $c, $sub ) = $route->dest->@{qw(c sub)};

    #if ( blessed $sub ) {
    #  die ... if $c
    #}

    Frame::Base->dmsg({ c => $c, sub => $sub, route => $route, req => $self });

    if(blessed $c) {
      my $res = $c->$sub( route => $route, req => $req, c => $c, sub => $sub)
    }
    else {
        $c = ( $c || $default_controller_class )
              ->new( app   => $self
                   , req   => $req
                   , route => $route );

        my $res = $c->$sub( $req->placeholder_values_ord )
            // $c->res;
    ]



    $res = $res->get if $res isa 'Future';

    $res;
}

method startup;

__END__

=encoding utf-8

=head1 NAME

Frame - Bare-bones, real-time web framework (WIP)

=head1 SYNOPSIS

  use Object::Pad;

  use utf8;
  use v5.36;

  class FrameApp :does(Frame);

  method startup {
    $self->routes->get('/', sub ($c) {
      $c->render('Frame works!')
    })
  }

  FrameApp->new->to_psgi

=head1 DESCRIPTION

Frame is

=head1 AUTHOR

Ian P Bradley E<lt>ian.bradley@studiocrabapple.comE<gt>

=head1 COPYRIGHT

Copyright 2023- Ian P Bradley

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
