use Object::Pad qw/:experimental(mop)/;

package Frame;
role Frame :does(Frame::Base);

our $VERSION  = '0.01';

use utf8;
use v5.36;

use Data::Dumper;
use YAML::Tiny;
use IO::Async::Loop;
use Net::Async::HTTP;
use Feature::Compat::Try;

use Frame::Routes;
use Frame::Request;
use Frame::Controller::Default;

field $loop :reader;
field $ua :reader;
field $routes :reader;
field $config :reader;
field $config_defaults :reader;
field $charset :mutator = 'utf-8';
field $request_class :mutator = 'Frame::Request';
field $controller_namespace :mutator;
field $default_controller_class = 'Frame::Controller::Default';
field $default_controller_meta;

ADJUSTPARAMS ($params) {
  unshift @INC, $INC[1];
  $self->app($self);

  $loop = IO::Async::Loop->new; # This grabs the existing loop
  $ua = Net::Async::HTTP->new;
  $loop->add($ua);

  $config_defaults = eval { YAML::Tiny->read('config-defaults.yml')->[0] } // { charset => 'utf-8' };
  $config = eval { YAML::Tiny->read($ENV{FRAME_CONFIG_FILE} || 'config.yml')->[0] } // {};
  $config = { %$config_defaults, %$config };

  $charset = $$config{charset} // 'utf-8';

  $controller_namespace = $$params{controller_namespace}
    // $$config{controller_namespace}
    // __CLASS__ . '::Controller';

  my $class = __CLASS__;

  try {
    require "$class/Controller.pm";

    my $meta = Object::Pad::MOP::Class->create_class("$class\::Controller::$self"
      , isa => $default_controller_class);

    $meta->add_role(__CLASS__ . '::Controller');
    $meta->seal;

    $default_controller_meta = $meta;
    $default_controller_class = $meta->name
  }
  catch ($e) {
    dmsg $e if $ENV{FRAME_DEBUG}
  }

  $request_class = $$params{request_class}
    // $$config{request_class}
    // $request_class;

  $routes = Frame::Routes->new(app => $self);

  $self->startup
}

method to_psgi { sub { $self->handler(shift) } }

method handler ($env) {
  my $req = $request_class->new(app => $self->app, env => $env);
  $self->dispatch($req)
}

method dispatch ($req) {
  my $route = $routes->match($req);
  $route ? $self->route($route, $req) : $self->render_404($req)
}

method route ($route, $req) {
  my ($c, $sub) = $route->dest->@{qw(c sub)};
  $c = ($c || $default_controller_class)->new(app => $self, req => $req);

  my $res = $c->$sub($req->placeholder_values_ord);
  $res = $res->get if $res isa 'Future';

  $c->res->finalize
}

method render_404 ($req) {
  $default_controller_class->new(app => $self, req => $req)->render_404->finalize
}

method startup;

1

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
