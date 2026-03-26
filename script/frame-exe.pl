#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';
use lib 'lib';

package Frame::Runner::Exec;

class Frame::Runner::Exec : does(Frame);

use utf8;
use v5.40;

our $VERSION = 0.01;

use IPC::Nosh::Common;
use Syntax::Keyword::Dynamically;

field $app;
field $router { $self->routes };
field $config { $self->config };

method cliopt : common ($argv) {
    my @spec = ('');

    my %clidest;
    GetOptionsFromArray( $argv, \%clidest, );
}

method startup {

    dynamically $router = $self->routes;
    dynamically $config = $self->config;

    $router->get(
        '/',
        sub ($c) {
            { hello => 'world!' };
        }
    );

    $router->get(
        '/:key/:value',
        sub ( $c, $key, $value ) {
            { $key => $value }
        }
    );

    dmsg $router, $config, $self;

    $self;
}

method run_psgi {
    use Plack::Runner;
    my $runner = Plack::Runner->new;
    $runner->run($app);

}

package Frame::Runner::Exec::CLI;

use lib 'lib';
use v5.40;

use IPC::Nosh::IO;

our $frameapp = Frame::Runner::Exec->new( argv => \@ARGV );
our $apppkg   = ref $frameapp;

unless (caller) {
    $frameapp->run_psgi;
    err "'$apppkg' exited with $?" unless $? == 0;
    exit $?;
}

$frameapp->to_app;
