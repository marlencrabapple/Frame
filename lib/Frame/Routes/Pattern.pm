use Object::Pad;

package Frame::Routes::Pattern;
class Frame::Routes::Pattern :does(Frame::Base);

use utf8;
use v5.36;
use autodie;

field $pattern :param :reader;
field $filters :reader;

ADJUSTPARAMS ( $params ) { $filters = $$params{filters} // {} }

1