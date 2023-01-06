use Object::Pad;

package Frame::App;
class Frame::App :does(Frame::Base);

use utf8;
use v5.36;
use autodie;

use Frame;

use Path::Tiny;

my $app = Frame->new;
my $psgi = $app->to_psgi;

state %dispatch = (
  new => 'new_app',
);

method cmd(@argv) {
  my $dest = $dispatch{shift @argv};
  $self->$dest(@argv)
}

method new_app($package) {
  ...
}

1