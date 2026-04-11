use Object::Pad ':experimental(:all)';

package Example::One;

use lib 'lib';

class Example::One : isa(Frame);

use utf8;
use v5.40;

use Path::Tiny;
use TOML::Tiny;
use IPC::Nosh::Common;

field $root : param //= path('.');

#field $config : param //= {};

method startup {
    my $r = $self->routes;

    $r->get(
        '/',
        sub {
            { asf => 'asfd' }
        }
    );

    # $r->get(
    #     '/:sadf',
    #     {
    #         sadf => sub ( $self, $req, $val ) {
    #             dmsg( { self => $self, '%ENV' => \%ENV, val => $val } );
    #         }
    #     },
    #     sub ( $self, $sadf ) {
    #         my $req = $self->req;
    #         dmsg $self, $sadf;
    #     }
    # );

    # $r->get(
    #     '/media/:id/:slug',
    #     sub ( $self, $req, $id, $slug ) {
    #         { id => $id, slug => $slug, controller => $self }
    #     }
    # );

    dmsg $self;    #dmsg( { self => $self } );

    $self;
}

method view_media_item ( $id, $slug ) {

}

package main;

Example::One->new->to_psgi;
