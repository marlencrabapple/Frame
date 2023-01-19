use Object::Pad;

package Frame::Db;
role Frame::Db :does(Frame::Base);

use utf8;
use v5.36;
use autodie;

method dbh :required;

1