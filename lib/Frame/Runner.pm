use Object::Pad ':experimental(:all)';

package Frame::Runner::PSGI;
class Frame::Runner::PSGI :does(Frame::Base);

field $app;

my class Example = {
  apply 'Frame';
  apply 'Frame::Controller';

  field $asdf;

  method startup {
    my $r = $self->routes
  }
}
 