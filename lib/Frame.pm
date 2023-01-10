use Object::Pad;

package Frame;
role Frame :does(Frame::Controller);

our $VERSION  = '0.01';

use utf8;
use v5.36;
use autodie;

use Carp;
use Plack;
use Data::Dumper;

use Frame::Routes;
use Frame::Request;
use Frame::Controller;

field $req :reader;
field $res :reader;
field $routes :reader;
field $charset :mutator = 'utf-8';
field $request_class :mutator = 'Frame::Request';

ADJUSTPARAMS ( $params ) {
  $self->app($self);
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
