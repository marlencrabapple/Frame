use Object::Pad;

package Frame::Routes::Match;

use v5.36;
use autodie;

class Frame::Routes::Match :does(Frame::Base) {
  field $placeholder_vals :param :reader; # { ':key' => val, ... }
}