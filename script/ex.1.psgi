use Object::Pad ':experimental(:all)';

package Example::One;

class Example::One : does(Frame);

use utf8;
use v5.40;

use Path::Tiny;
use TOML::Tiny;

field $root   : param //= path('.');
field $config : param //= {};

method startup {
    my $r = $self->routes;
    $r->get( '/media/:id/:slug', 'view_media_item' );
}

method view_media_item ( $id, $slug ) {
    { id => $id, slug => $slug, controller => $controller }
}

