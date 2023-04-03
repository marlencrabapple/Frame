use Object::Pad;

package Frame::Server::Protocol;
class Frame::Server::Protocol :isa(Net::Async::HTTP::Server::Protocol) :does(Frame::Base);

use utf8;
use v5.36;

use Carp;
use Plack::Util;
use Stream::Buffered;
use Scalar::Util 'weaken';
use HTTP::Parser::XS 'parse_http_request';

state $CRLF = "\x0d\x0a";
state $headre = qr/^(.*?$CRLF$CRLF)/s;
state $protore = qr/^HTTP/;

# method on_read ($buffref, $eof) {
#   return 0 if $eof;
#   my $readh = $self->read_handle;

#   my %env = (
#     SERVER_PORT => $readh->sockport,
#     SERVER_NAME => $readh->sockhost,
#     SCRIPT_NAME => '',
#     REMOTE_ADDR => $readh->peerhost,
#     REMOTE_PORT => $readh->peerport || 0,
#     'psgi.version' => [ 1, 1 ],
#     'psgi.errors'  => \*STDERR,
#     'psgi.url_scheme' => $$self{ssl} ? 'https' : 'http',
#     'psgi.run_once'     => Plack::Util::FALSE,
#     'psgi.multithread'  => Plack::Util::FALSE,
#     'psgi.multiprocess' => Plack::Util::TRUE,
#     'psgi.streaming'    => Plack::Util::TRUE,
#     'psgi.nonblocking'  => Plack::Util::TRUE,
#     # 'psgix.harakiri'    => Plack::Util::TRUE,
#     'psgix.input.buffered' => Plack::Util::TRUE,
#     'psgix.io'          => $readh
#   );

#   my $on_read = sub ($, $buffref, $eof) {
#     dmsg 'on_read $eof:', $eof;
#     return 0 if $eof;
#     my $reqlen = parse_http_request($$buffref, \%env);

#     if($reqlen < 0) {
#       $self->close_now if $reqlen == -1;
#       return 0
#     }
#     elsif($reqlen >= 0) {
#       if(my $cl = $env{CONTENT_LENGTH}) {
#         my $buffer = Stream::Buffered->new($env{CONTENT_LEGNTH});
#         $$buffref = substr $$buffref, $reqlen;

#         my $read_chunked = sub ($, $buffref, $eof) {
#           dmsg 'read_chunked $eof:', $eof;
#           return 0 if $eof;
#           my $chunk;

#           if(length $$buffref) {
#             $chunk = $$buffref;
#             $$buffref = ''
#           }
#           else {
#             return undef
#           }

#           dmsg $cl, length $chunk;

#           $buffer->print($chunk);
#           $cl -= length $chunk;

#           dmsg $cl;

#           return 0 if $cl > 0;

#           dmsg 'asdf';

#           $env{'psgi.input'} = $buffer->rewind;
          
#           undef
#         };

#         my $rcret = $read_chunked->(undef, $buffref, $eof);
#         dmsg $rcret, defined $rcret, ref $rcret;

#         return $read_chunked if defined $rcret
#       }
#       else {
#         open my $stdin, '<', \substr $$buffref, 0, $reqlen, "";
#         $env{'psgi.input'} = $stdin
#       }
#     }

#     undef
#   };

#   my $orret = $on_read->(undef, $buffref, $eof);
#   dmsg $orret, defined $orret, ref $orret;

#   if(defined $orret) {
#     return $orret if ref $orret eq 'CODE';
#     return $on_read
#   }

#   my $req = $self->parent->make_request($self, \%env);

#   push $self->{requests}->@*, $req;
#   weaken($self->{requests}[-1]);

#   $self->parent->_received_request($req)
# }

method on_read ($buffref, $eof) {
  return 0 if $eof || $$buffref !~ $headre;

  my $readh = $self->read_handle;
  
  my %env = (
    SERVER_PORT => $readh->sockport,
    SERVER_NAME => $readh->sockhost,
    SCRIPT_NAME => '',
    REMOTE_ADDR => $readh->peerhost,
    REMOTE_PORT => $readh->peerport || 0,
    'psgi.version' => [ 1, 1 ],
    'psgi.errors'  => \*STDERR,
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

  my $reqlen = parse_http_request($$buffref, \%env);
  
  if($reqlen < 0) {
    $self->close_now if $reqlen == -1;
    return 0
  }

  my $cl = $env{CONTENT_LENGTH} // 0;
  $$buffref = substr $$buffref, $reqlen;

  sub ($, $buffref, $eof) {
    return 0 unless length $$buffref >= $cl;

    open my $stdin, '<', \substr $$buffref, 0, $cl, "";
    $env{'psgi.input'} = $stdin;

    my $req = $self->parent->make_request($self, \%env);

    push $self->{requests}->@*, $req;
    weaken($self->{requests}[-1]);

    $self->parent->_received_request($req);

    return undef
  }
}

1
