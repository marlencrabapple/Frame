use Object::Pad;

package Frame::Base;
role Frame::Base;

use utf8;
use v5.36;

field $app :mutator :weak;

ADJUSTPARAMS ($params) {
  $app //= $$params{app} if $$params{app}
}

1