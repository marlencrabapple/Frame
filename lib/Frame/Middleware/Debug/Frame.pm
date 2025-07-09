use Object::Pad ':experimental(:all)';

package Frame::Middleware::Debug::Frame;
class Frame::Middleware::Debug::Frame :isa(Plack::Middleware::Debug::Base);

use utf8;
use v5.40;

use Data::Printer;

method run ($env, $panel) {
  my $np = np $self, $env, $panel;

  $panel->content("<pre>"
    . dmsg( { self => $self, env => $env, paael => $panel}) 
    . "</pre>")
}
