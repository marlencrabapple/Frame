use Object::Pad;

package Frame::Server::Request;
class Frame::Server::Request :isa(Net::Async::HTTP::Server::Request) :does(Frame::Base);

use utf8;
use v5.36;

method protocol :override {
  $self->{req}{SERVER_PROTOCOL}
}

method method :override {
  $self->{req}{REQUEST_METHOD}
}

method keep_alive {
  my $c = lc ($self->{req}{HTTP_CONNECTION} // '');
  return 0 if $c eq 'close';
  return 1 if $c eq 'keep-alive' && $self->protocol eq 'HTTP/1.0';
  1
}

method _write_to_stream :override ($stream) {
  while(defined(my $next = shift $self->{pending}->@*)) {
    $stream->write($next,
      on_write => sub {
        $self->{bytes_written} += $_[1];
      },
      $self->keep_alive
        ? ()
        : ( on_flush => sub { $stream->close } )
    );
  }

  # An empty ->write to ensure we capture the written byte count correctly
  $stream->write("",
    on_write => sub {
      $self->{conn}->parent->_done_request($self)
    }
  ) if $self->{is_done};

  $self->{is_done}
}

1