use Object::Pad ':experimental(:all)';

package Frame::Middleware::Auth::Basic;
class Frame::Middleware::Auth::Basic :does(Frame::Middleware);

use utf8;
use v5.40;

method call ($env, %opts) {
  ...
}

sub auth_user {

}
