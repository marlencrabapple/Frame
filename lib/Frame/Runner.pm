use Object::Pad ':experimental(:all)';

package Frame::Runner;
class Frame::Runner :does(Frame::Base);

use utf8;
use v5.40;

field $app;

my class Example {
  apply Frame;
  apply Frame::Controller;

  method startup {
    my $r =  $self->routes
  }
}

method sdfsadf {
  Example->new;
}