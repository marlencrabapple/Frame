use Object::Pad ':experimental(:all)';

package Frame::Config;
use lib 'lib';
role Frame::Config;

use utf8;
use v5.40;

use TOML::Tiny;
use Const::Fast;

BEGIN {
    const our $CONFIG_DEFAULT_TOML => <<'...';
[Frame]
 charset = "utf8"
 plack_env = "development"
...

}

const our $CONFIG_DEFAULT =>
  ( from_toml($Frame::Config::CONFIG_DEFAULT_TOML) )[0];

field $config : reader : inheritable { $self->init_config };

method init_config {
    { %$CONFIG_DEFAULT }
}

method config_default : common {
    $CONFIG_DEFAULT;
}
