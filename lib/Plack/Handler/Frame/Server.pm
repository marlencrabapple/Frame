use Object::Pad;

package Plack::Handler::Frame::Server;
class Plack::Handler::Frame::Server :isa(Plack::Handler::Net::Async::HTTP::Server::Prefork);

use utf8;
use v5.36;

1