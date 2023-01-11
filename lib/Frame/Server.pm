use Object::Pad;

package Frame::Server;
class Frame::Server
  # :isa(IO::Async::Listener)
  :isa(Net::Async::HTTP::Server::PSGI)
  :does(Frame::Base);

use utf8;
use v5.36;

use Plack;
use Plack::Util;
use HTTP::Parser::XS qw(parse_http_request);
use IO::Async::Loop;
use Parallel::Prefork;
use Data::Dumper;
use Carp;

use Frame::Server::Protocol;

# field $threads;
# field $workers;
# field $queue;

# field $reverse_proxy :accessor = 0;
# field @trusted_proxies :reader :writer;

# method listen {

# }

method _init ($params) {
  $$params{handle_class} = 'Frame::Server::Protocol';
  $$params{request_class} = 'Frame::Server::Request';
  $self->SUPER::_init($params)
}

method configure (%params) {
  foreach (qw(on_request request_class app)) {
    $self->{$_} = delete $params{$_} if exists $params{$_};
  }

  $self->SUPER::configure(%params)
}

method add_to_loop {
  $self->can_event("on_request")
    or croak "Expected either an on_request callback or an ->on_request method";

  $self->SUPER::_add_to_loop(@_)
}

method on_accept ($conn) {
  $conn->configure(
    on_closed => sub ($conn) {
      $conn->on_closed;
      $conn->remove_from_parent;
    }
  );

  $self->add_child($conn);
  $conn
}

method make_request {
  $$self{request_class}->new(@_)
}

method on_request ($request) {

}

method _received_request ($request) {
  $self->invoke_event( on_request => $request )
}

method _done_request ($request) {

}

1