use Object::Pad qw/:experimental(mop)/;

package Frame;
role Frame :does(Frame::Base);

our $VERSION  = '0.01';

use utf8;
use v5.36;

use YAML::Tiny;
use Feature::Compat::Try;

use Frame::Tx;
use Frame::Routes;
use Frame::Request;
use Frame::Controller::Default;

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
  $self->app = $self;
  
  $config_defaults = YAML::Tiny->read('config-defaults.yml')->[0] // { charset => 'utf-8' };
  $config = YAML::Tiny->read($ENV{FRAME_CONFIG_FILE} || 'config.yml')->[0] // {};
  $config = {%$config_defaults, %$config};

  $charset = $$config{charset} // 'utf-8';

  $controller_namespace = $$params{controller_namespace}
    // $$config{controller_namespace}
    // __CLASS__ . '::Controller';

  my $class = __CLASS__;

  # if(eval "require $class\::Controller; say 'asdf'; 1") {
  try {
    require "$class/Controller.pm";

    my $meta = Object::Pad::MOP::Class->create_class("Frame::Controller::For::$class"
      , isa => $default_controller_class);

    $meta->add_role(__CLASS__ . '::Controller');
    $meta->seal;

    $default_controller_meta = $meta;
    $default_controller_class = $meta->name
  }
  # else {
  catch ($e) {
    dmsg $e #$e
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
  $c->$sub($req->placeholder_values_ord);
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

Frame - Blah blah blah

=head1 SYNOPSIS

  use Frame;

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
