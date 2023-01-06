use Object::Pad;

package Frame::Routes::Pattern;

use v5.36;
use autodie;

use Data::Dumper;

class Frame::Routes::Pattern :does(Frame::Base) {
  field $pattern :param :reader;
  field $filters :reader;

  ADJUSTPARAMS ( $params ) { $filters = $$params{filters} // {} }
}