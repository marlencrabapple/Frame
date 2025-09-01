use Object::Pad qw(:experimental(:all));

package Frame::Example;

class Frame::Example : does(Frame);

use utf8;
use v5.40;

use TOML::Tiny;
use Data::Dumper;
use Path::Tiny;

#field $config_file : param(config);
#field $config;

ADJUST {
    #$config_file = $ENV{FRAME_CONFIG_FILE} // 'config.toml';
    #$config      = from_toml( path($config_file) );

    $self->init_db
}

method startup {
    my $r = $self->routes;

    $r->get( '/',         sub { $self->self(@_) } );
    $r->get( '/items',    'default#list_items' );
    $r->get( '/item/:id', { id => qr/^[0-9]+$/ }, 'default#view_item' );

    $r->post( '/item/add', 'default#add_item' );

    $r->get(
        '/asdf/:foo/fdsa/:bar/:baz',
        { foo => qr/^[a-z]+$/i },
        sub ( $foo, $bar, $baz ) {
            $self->render(
                {
                    foo => $foo,
                    bar => $bar,
                    baz => $baz
                }
            );
        }
    );

    $r->get(
        '/redirect',
        sub {
            $self->redirect( $self->req->parameters->{url} );
        }
    );
}

method self {
    $self->render( '<pre>' . Dumper($self) . '</pre>' );
}
