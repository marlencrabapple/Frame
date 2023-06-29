use Object::Pad;

package Frame::Routes::Pattern;
class Frame::Routes::Pattern :does(Frame::Base);

use utf8;
use v5.36;

field $pattern :param :reader;
field $filters :reader;

ADJUST { $filters //= {} }

1