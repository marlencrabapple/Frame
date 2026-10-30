use Object::Pad ':experimental(:all)';

package Frame::App::perldoc::Source;
role Frame::App::perldoc::Source : does(Frame::App::perldoc::Base);

use utf8;
use v5.44;

method modlist : required;
