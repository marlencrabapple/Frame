use Object::Pad;

package Frame::Tx;
class Frame::Tx :does(Frame::Base);

use utf8;
use v5.36;

field $req;
field $res;

1