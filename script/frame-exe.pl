#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';
use lib 'lib';

package Frame::Runner::Example;

class Frame::Runner::Example : does(Frame);

use utf8;
use v5.40;

our $VERSION = 0.01;

field $r { $self->router };
field $c { $self->config }

method startup {
    $r->get(
        '/',
        sub ($c) {
            { hello => 'world!' };
        }
    );

    $r->get(
        '/:key/:value',
        sub ( $c, $key, $value ) {
            { $key => $value }
        }
    );
}

package Frame::Runner::Example::CLI;

use lib 'lib';
use v5.40;

use IPC::Nosh::IO;

our $frameapp = Frame::Runner::Example->new( argv => \@ARGV );
our $apppkg   = ref $frameapp;

unless (caller) {
    $frameapp->start;
    err "'$apppkg' exited with $?" unless $? == 0;
    exit $?;
}

$frameapp->to_app;
