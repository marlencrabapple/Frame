use Object::Pad;

package Frame;
role Frame :does(Frame::Controller);

our $VERSION  = '0.01';

use utf8;
use v5.36;

use YAML::Tiny;
use Data::Dumper;

use Frame::Routes;
use Frame::Request;

field $req :reader;
field $res :reader;
field $routes :reader;
field $config :mutator;
field $config_defaults :reader;
field $charset :mutator = 'utf-8';
# field $request_class_prefix
field $request_class :mutator = 'Frame::Request';
# field $controller_class_prefix
# field $controller_class :mutator = 'Frame::Controller';

ADJUSTPARAMS ( $params ) {
  $self->app($self);
  
  $config_defaults = YAML::Tiny->read('config-defaults.yml')->[0] // { charset => 'utf-8' };
  $config = YAML::Tiny->read($ENV{FRAME_CONFIG_FILE} || 'config.yml')->[0] // {};
  $config = {%$config_defaults, %$config};

  $charset = $$config{charset} // 'utf-8';
  $routes = Frame::Routes->new(app => $self);

  $self->startup
}

method to_psgi { sub { $self->handler(shift) } }

method handler ($env) {
  # $req = $request_class->new($env);
  $req = Frame::Request->new($env);
  $req->app($self->app);
  $req->stash = {};

  $res = $req->new_response;
  $self->dispatch;
  
  $res->finalize
}

method dispatch {
  my $route = $routes->match($req);
  $route ? $route->route($req, $res) : $self->render_404
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
