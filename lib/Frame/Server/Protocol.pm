use Object::Pad;

package Frame::Server::Protocol;
class Frame::Server::Protocol :isa(Net::Async::HTTP::Server::Protocol);

use utf8;
use v5.36;

use Carp;
use Plack::Util;
use Data::Dumper;
use Stream::Buffered;
use Scalar::Util 'weaken';
use HTTP::Parser::XS 'parse_http_request';

state $protore = qr/^HTTP/;

method on_read ($buffref, $eof) {
  return 0 if $eof;
  my $readh = $self->read_handle;

  my %env = (
    SERVER_PORT => $readh->sockport,
    SERVER_NAME => $readh->sockhost,
    SCRIPT_NAME => '',
    REMOTE_ADDR => $readh->peerhost,
    REMOTE_PORT => $readh->peerport || 0,
    'psgi.version' => [ 1, 1 ],
    'psgi.errors'  => *STDERR,
    'psgi.url_scheme' => $$self{ssl} ? 'https' : 'http',
    'psgi.run_once'     => Plack::Util::FALSE,
    'psgi.multithread'  => Plack::Util::FALSE,
    'psgi.multiprocess' => Plack::Util::TRUE,
    'psgi.streaming'    => Plack::Util::TRUE,
    'psgi.nonblocking'  => Plack::Util::TRUE,
    # 'psgix.harakiri'    => Plack::Util::TRUE,
    'psgix.input.buffered' => Plack::Util::TRUE,
    'psgix.io'          => $readh
  );

  my $on_read = sub ($, $buffref, $eof) {
    return 0 if $eof;
    my $reqlen = parse_http_request($$buffref, \%env);

    if($reqlen < 0) {
      $self->close_now if $reqlen == -1;
      return 0
    }
    elsif($reqlen >= 0) {
      return 0 unless length $$buffref >= ($env{CONTENT_LENGTH} // 0);

      # if(my $cl = $env{CONTENT_LENGTH}) {
      #   my $buffer = Stream::Buffered->new($env{CONTENT_LEGNTH});

      #   my $read_chunked = sub ($, $buffref, $eof) {
      #     return 0 if $eof;
      #     my $chunk;

      #     if(length $$buffref) {
      #       $chunk = $$buffref;
      #       $$buffref = ''
      #     }
      #     else {
      #       ...
      #     }

      #     $buffer->print($chunk);
      #     $cl -= length $chunk;

      #     return 0 if $cl > 0;

      #     $env{'psgi.input'} = $buffer->rewind;
      #     return undef
      #   };

      #   return $read_chunked if defined $read_chunked->(undef, $buffref, $eof)
      # }
      # else {
      #   open my $content, '<', \${substr $$buffref, 0, $reqlen, ""};
      #   $env{'psgi.input'} = $content;
      # }
    }

    open my $stdin, '<', \substr $$buffref, 0, $reqlen, "";
    $env{'psgi.input'} = $stdin;

    my $req = $self->parent->make_request($self, \%env);

    push $self->{requests}->@*, $req;
    weaken($self->{requests}[-1]);

    $self->parent->_received_request($req);

    undef
  };

  $on_read if defined $on_read->(undef, $buffref, $eof)
}

1
