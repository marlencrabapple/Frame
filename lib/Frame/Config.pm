use Object::Pad qw(:experimental(:all));

package Frame::Config;
role Frame::Config : does(Frame::Base);

use utf8;
use v5.40;

use TOML::Tiny qw(from_toml to_toml);
use Path::Tiny;
use Const::Fast;
use Syntax::Keyword::Try;
use IPC::Nosh::IO;

our $_default_config_init = { charset => 'utf8' };

BEGIN {

    const our $default_config_inline => q{
[default]
charset = "utf8"
environment = "devlopment"
};

    try {
        my $error;

        my $default_config_path =
          path( $ENV{FRAME_DEFAULT_CONFIG_FILE} // 'config-default.toml' );

        ( $_default_config_init, $error ) = from_toml(
              $default_config_path->exists
            ? $default_config_path->slurp_utf8
            : $default_config_inline
        );

        if ($error) {
            fatal $error;
        }
    }
    catch ($e) {
        our $_config_default = { charset => 'utf8' };
        err "$e"
    }
}

const our $config_default      => {%$_default_config_init};
const our $config_default_path => [ 'config-default.toml', 'config.toml' ];

field $config_in : param(config) = $config_default_path;
field $config;

ADJUST {
    my $_config = {};

    foreach my $in (@$config_in) {
        my ( $_config_curr, $error ) = from_toml( path($in)->slurp_utf8 );

        die $error
          if $error
          && $config_in != $Frame::Config::config_default_path;

        $_config = { %$_config, %$_config_curr };
    }

    const our $run_config = {%$_config};
    $config = $run_config
}
