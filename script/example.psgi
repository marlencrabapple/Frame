use v5.40;
use utf8;

use lib 'lib';
use Frame::Example;

Frame::Example->new(
  config => [ 'config-default.toml', 'config.toml' ]
)->to_psgi
