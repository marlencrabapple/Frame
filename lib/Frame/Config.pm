use Object::Pad qw(:experimental(:all));

package Frame::Config;
role Frame::Config : does(Frame::Base);

use utf8;
use v5.40;

use TOML::Tiny qw(from_toml to_toml);
use Path::Tiny;
use Const::Fast;

#const our $default_config = { charset => 'utf-8' };

our $_config_default;

try {
    my $error;

    ( $_config_default, $error ) = from_toml(
        path( $ENV{FRAME_DEFAULT_CONFIG_FILE} // 'config-default.toml' )
          ->slurp_utf8 );

    if ($error) {
        die $error;
    }
}
catch ($e) {
    $_config_default = { charset => 'utf8' };
    Frame::Base::dmsg($e)
}

const our $config_default => {%$_config_default};

field $config_in : param(config) = [ 'config-default.toml', 'config.toml' ];
field $config = {%$config_default};

APPLY {

  }

  ADJUST {
    my $_config = {};

    foreach my $in (@$config_in) {
        my $_config_in = from_toml( path($in)->slurp_utf8 );
        $_config = { %$_config, %$_config_in };
    }

    const our $run_config = {%$_config};
    $config = $run_config
}
