use Object::Pad ':experimental(:all)';

package Frame::Config;
use lib 'lib';

class Frame::Config;

use utf8;
use v5.40;

use Const::Fast;

const our $CONFIG_DEFAULT => <<'...'
[Frame]
 charset = "utf8"
 plack_env = "development"
...
  ;

field $config : reader : inheritable { $self->init_config };

method init_config {
    { %$CONFIG_DEFAULT }
}

method config_default : common {
    $CONFIG_DEFAULT;
}
