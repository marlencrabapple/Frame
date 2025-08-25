use Object::Pad ':experimental(:all)';

package Example::One;

use lib 'lib';

class Example::One : does(Frame); #:does(Frame::Base);

use utf8;
use v5.40;

use Path::Tiny;
use TOML::Tiny;

use Frame::Base;

field $root   : param //= path('.');
#field $config : param //= {};

method startup {
    my $r = $self->routes;
    $r->get( '/media/:id/:slug', 'view_media_item' );
    dmsg { self => $self };
    $self
}

method view_media_item ( $id, $slug ) {
    { id => $id, slug => $slug, controller => $self }
}

