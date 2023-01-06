use Object::Pad;

package Frame::Base;
role Frame::Base;

use utf8;
use v5.36;
use autodie;

# use Data::Dumper ();

field $app :accessor :weak;

# method Dumper :common { Data::Dumper::Dumper(@_) }

1