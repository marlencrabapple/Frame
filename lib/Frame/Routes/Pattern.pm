use Object::Pad;

package Frame::Routes::Pattern;

use v5.36;
use autodie;

class Frame::Routes::Pattern :does(Frame::Base) {
  field $pattern :param :reader;
  field $filters :param :reader = undef;
}