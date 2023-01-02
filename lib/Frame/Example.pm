use Object::Pad;

package Frame::Example;

use v5.36;
use utf8;
use autodie;

use YAML::Tiny;
use Data::Dumper;

use Frame::Example::Db;

class Frame::Example :does(Frame) :does(Frame::Example::Db) {
  field $config :reader;

  ADJUST {
    $config = YAML::Tiny->read('share/example/config.yml')->[0];
    $self->init_db
  }

  method startup {
    my $r = $self->routes;

    $r->get('/', 'default#list_items');
    $r->get('/:id', { id => qr/^[0-9]+$/ }, 'default#view_item');

    $r->get('/asdf/:asdf/asdf/:fdas/:ddd', { asdf => qr/^[a-z]+$/ }, sub ($self, $asdf, $fdas, $ddd) {
      $self->render({ asdf => $asdf, fdas => $fdas, ddd => $ddd })
    });

    $r->post('/add', 'default#add_item')
  }
}