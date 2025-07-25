use Object::Pad qw(:experimental(:all));

package Frame::Config;
role Frame::Config : does(Frame::Base);

use utf8;
use v5.40;

use TOML::Tiny qw(from_toml to_toml);
use Path::Tiny;
use Const::Fast;
use Syntax::Keyword::Try;

our $_config_default = { charset => 'utf8' };

BEGIN {
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
        our $_config_default = { charset => 'utf8' };
        Frame::Base->dmsg($e)
    }
}

const our $config_default      => {%$_config_default};
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
