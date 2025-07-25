use Object::Pad;

package Frame::App;

class Frame::App : does(Frame::Base);

use utf8;
use v5.36;

use Frame;
use Frame::Example;

use Path::Tiny;

field $app;
field $tx;
field $psgi;

ADJUST {
    $app = Frame::Example->new;
    $tx  = $Frame::Controller::tx_default;

    #$psgi = $app->to_psgi;
}

state %dispatch = (
    new   => \&new_app,
    synth => \&synth
);

method cmd(@argv) {
    my $dest = $dispatch{ shift @argv };
    $self->$dest(@argv);
}

method new_app (@args) {

    # our $tx;
    # my $dir = path($package)->mkdir;
}

method synth (@args) {

}

1
