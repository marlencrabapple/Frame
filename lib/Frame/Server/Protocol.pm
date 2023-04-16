use Object::Pad;

package Frame::Server::Protocol;
class Frame::Server::Protocol :isa(Net::Async::HTTP::Server::Protocol) :does(Frame::Base);

use utf8;
use v5.36;

use Carp;
use Plack::Util;
use List::Util 'any';
use Scalar::Util 'weaken';
use IO::Async::Timer::Countdown;
use HTTP::Parser::XS 'parse_http_request';

use constant MAX_REQUEST_SIZE => 131072;
use constant CHUNK_SIZE => 64 * 1024;
use constant HEADRE => qr/^(.*?\r\n)/s;
# use constant PIPELINERE => qr/^(?:GET|HEAD)/;

use constant CHUNKRE => (
  qr/^(([0-9a-fA-F]+).*\r\n)/,
  qr/^\r\n/
);

field $read_timeout :accessor :weak;
field $req_header_timeout :accessor :weak;
field $keep_alive_timeout :accessor :weak;
field $inactivity_timeout :accessor :weak;
field $reset_req_header_timeout = 0; # Gotta think of a better name for this

method on_read ($buffref, $eof) {
  return 0 if $eof
    || $$buffref !~ HEADRE; # TODO: See if this is faster than letting it hit parse_http_request
  
  if($reset_req_header_timeout) {
    $self->restart_timeout(qw/req_header read/);
    $reset_req_header_timeout = 0;
  }

  $inactivity_timeout->reset;
  
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
    'psgix.harakiri'    => Plack::Util::TRUE,
    'psgix.input.buffered' => Plack::Util::TRUE,
    'psgix.io'          => $readh
  );

  my $reqlen = parse_http_request($$buffref, \%env);
  
  if($reqlen < 0) {
    $self->close_now if $reqlen == -1;
    return 0
  }

  $req_header_timeout->stop; $reset_req_header_timeout = 1;
  $keep_alive_timeout->stop;
  
  $$buffref = substr $$buffref, $reqlen;

  my $req = $self->parent->make_request($self, \%env);

  $self->write("HTTP/1.1 100 Continue\r\n\r\n", on_write => sub { $$req{bytes_written} += $_[1] })
    if $env{HTTP_EXPECT} && lc $env{HTTP_EXPECT} eq '100-continue';
  
  if($env{HTTP_TRANSFER_ENCODING} && lc delete $env{HTTP_TRANSFER_ENCODING} eq 'chunked') {
    my $chunkbuff = '';
    $env{CONTENT_LENGTH} = 0;

    return sub ($, $buffref, $eof) {
      $inactivity_timeout->reset;

      return 0 unless $$buffref =~ s/@{[CHUNKRE]}[0]//;
      my ($trailer, $chunklen) = ($1, hex $2);

      return $self->handle_request($req, \$chunkbuff, \%env, $env{CONTENT_LENGTH}) if $chunklen == 0;

      if(length $$buffref < $chunklen + 2) {
        $$buffref = "$trailer$$buffref";
        return 0
      }

      $chunkbuff .= substr $$buffref, 0, $chunklen, '';
      $$buffref =~ s/@{[CHUNKRE]}[1]//;
      $env{CONTENT_LENGTH} += $chunklen;

      1
    }
  }

  my $cl = $env{CONTENT_LENGTH} // 0;

  sub ($, $buffref, $eof) {
    $inactivity_timeout->reset;
    length $$buffref >= $cl ? $self->handle_request($req, $buffref, \%env, $cl) : 0
  }
}

method handle_request ($req, $buffref, $env, $length) {
  open my $stdin, '<', \substr $$buffref, 0, $length, '';
  $$env{'psgi.input'} = $stdin;

  push $self->{requests}->@*, $req;
  weaken $self->{requests}[-1];

  $self->parent->_received_request($req);

  undef
}

method write :override ($data, %params) {
  $inactivity_timeout->reset;
  $self->SUPER::write($data, %params)
}

method on_closed :override {
  foreach my $name (qw/req_header keep_alive read inactivity/) {
    my $field = "$name\_timeout";
    $self->$field->remove_from_parent
  }

  $self->SUPER::on_closed
}

method restart_timeout (@names) {
  foreach my $name (scalar @names ? @names : qw/req_header keep_alive read inactivity/) {
    my $field = "$name\_timeout";
    $self->$field->is_running ? $self->$field->reset : $self->$field->start
  }
}

1
