use Object::Pad;

package Frame::Example;
class Frame::Example :does(Frame) :does(Frame::Example::Db);

use utf8;
use v5.36;
use autodie;

use YAML::Tiny;
use Data::Dumper;

field $config :reader;

ADJUST {
  $config = YAML::Tiny->read('share/example/config.yml')->[0];
  $self->init_db
}

method startup {
  my $r = $self->routes;

  $r->get('/', 'self');
  $r->get('/items', 'default#list_items');
  $r->get('/item/:id', { id => qr/^[0-9]+$/ }, 'default#view_item');

  $r->post('/item/add', 'default#add_item');

  $r->get('/asdf/:foo/fdsa/:bar/:baz', { foo => qr/^[a-z]+$/i }, sub ($foo, $bar, $baz) {
    $self->render({
      foo => $foo,
      bar => $bar,
      baz => $baz
    })
  });

  $r->get('/redirect', sub {
    $self->redirect($self->req->parameters->{url})
  })
}

method self {
  $self->render('<pre>' . Dumper($self) . '</pre>')
}

1