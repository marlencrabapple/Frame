use Object::Pad;

package Frame::App;

use utf8;
use v5.36;
use autodie;

use Path::Tiny;
use Text::Xslate;

state $tx = Text::Xslate->new(
  path => ['view']
);

state %dispatch = (
  new => 'new_app',
);

class Frame::App {
  method cmd(@argv) {
    my $dest = $dispatch{shift @argv};
    $self->$dest(@argv)
  }

  method new_app($package) {
    ...
  }
}