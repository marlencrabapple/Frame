use Object::Pad qw/:experimental(:all)/;

package Frame;
role Frame :does(Frame::Base);

our $VERSION  = '0.01.4';

use utf8;
use v5.40;

use Encode;
use TOML::Tiny qw(from_toml to_toml);
use Path::Tiny;
use Data::Dumper;
use IO::Async::Loop;
use Net::Async::HTTP;
use Feature::Compat::Try;
use Const::Fast::Exporter;
use Syntax::Keyword::Try;

# use Frame::Config;
use Frame::Routes;
use Frame::Request;
use Frame::Controller::Default;

our $_config_default;

try {
  my $error;
  
  ($_config_default, $error) = from_toml(
    path($ENV{FRAME_DEFAULT_CONFIG_FILE}
      // 'config-default.toml')
    ->slurp_utf8);

  if ($error) {
    die $error
  }
}
catch ($e) {
  $_config_default = { charset => 'utf8' };
  warn Dumper($e)
}

const our $config_default => { %$_config_default };

field $loop :reader;
field $ua :reader;
field $routes :reader;
field $config :reader;
field $charset :reader = 'utf-8';
field $request_class :param = 'Frame::Request';
field $controller_namespace :param :reader = undef;
field $default_controller_class = 'Frame::Controller::Default';
field $default_controller_meta;

ADJUSTPARAMS ($params) {
  unshift @INC, $INC[1];
  $self->app($self);

  $loop = IO::Async::Loop->new; # This grabs the existing loop
  $ua = Net::Async::HTTP->new;
  $loop->add($ua);

  my ($_config, $error) = from_toml(path($ENV{FRAME_CONFIG_FILE}
		// 'config.toml')->slurp_utf8);

  if($error) {
    $_config = { charset => 'utf8' }
  }
  
  const my $__config = { %$config_default, %$_config };
  $config //= $ENV{frame_config} = $__config;

  $charset = $$config{charset} if $$config{charset};
  $request_class = $$config{request_class} if $$config{request_class};
  
  $controller_namespace //= $$config{controller_namespace}
    || __CLASS__ . '::Controller';

  # lock_hashref_recurse($config);

  try {
    my $fn = __CLASS__ . '/Controller.pm';
    require "$fn";

    my $meta = Object::Pad::MOP::Class->create_class(__CLASS__ . "::Controller::$self"
      , isa => $default_controller_class);

    $meta->add_role(__CLASS__ . '::Controller');
    $meta->seal;

    $default_controller_meta = $meta;
    $default_controller_class = $meta->name
  }
  catch ($e) {
    # dmsg $e if $ENV{FRAME_DEBUG}
  }
  
  $routes = Frame::Routes->new(app => $self);
  $self->startup
}

method to_psgi { sub { $self->handler(shift) } }

method handler ($env) {
  my $req = $request_class->new(app => $self, env => $env);
  my $res = $self->dispatch($req);

  utf8::encode($res->[2][0])
    if $res->[2][0] =~ /[^\x00-\xff]/g;

  $res
}

method dispatch ($req) {
  my $res;

  if (my $match = $routes->match($req)) {
    if ($match isa 'Plack::Response') {
      $res = $match->finalize
    }
    elsif ($match isa 'Frame::Routes::Route') {
      $res = $self->route($match, $req)->finalize
    }
  }
  else {
    $res = $default_controller_class
      ->new(app => $self, req => $req)
      ->render_404->finalize
  }

  $res
}

method route ($route, $req) {
  my ($c, $sub) = $route->dest->@{qw(c sub)};
  $c = ($c || $default_controller_class)->new(app => $self, req => $req, route => $route);

  my $res = $c->$sub($req->placeholder_values_ord) // $c->res;
  $res = $res->get if $res isa 'Future';

  $res
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
