use Object::Pad;

package Frame::Base;

use v5.36;
use autodie;

#use Data::Dumper ();

role Frame::Base {
  field $app :accessor :weak;

  # method Dumper :common { Data::Dumper::Dumper(@_) }
}