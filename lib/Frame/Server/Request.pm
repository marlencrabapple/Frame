use Object::Pad;

package Frame::Server::Request;
class Frame::Server::Request :isa(Net::Async::HTTP::Server::Request);

use utf8;
use v5.36;

method protocol :override {
  $self->{req}{SERVER_PROTOCOL}
}

method method :override {
  $self->{req}{REQUEST_METHOD}
}

1