use Object::Pad ':experimental(:all)';

package Frame::Component;
class Frame::Component :isa(Plack::Component) :does(Frame::Base);

use utf8;
use v5.42;
