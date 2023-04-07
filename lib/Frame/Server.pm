use Object::Pad;

package Frame::Server;
class Frame::Server
  :isa(Net::Async::HTTP::Server::PSGI)
  :does(Frame::Base);

use utf8;
use v5.36;

use Carp;
use Data::Dumper;

use Frame::Server::Request;
use Frame::Server::Protocol;

use constant CRLF => "\r\n";

method _init :override ($params) {
  $$params{handle_class} = "Frame::Server::Protocol";
  $$params{request_class} = "Frame::Server::Request";
  $self->IO::Async::Listener::_init($params)
}

# Mostly copied from an anon sub in $self->SUPER::on_request
sub _responder ($req, $res) {
  my ($status, $headers, $body) = @$res;

  my $response = HTTP::Response->new( $status );
  $response->protocol( $req->protocol );

  my $has_content_length = 0;
  my $use_chunked_transfer;

  while( my ( $key, $value ) = splice @$headers, 0, 2 ) {
    $response->header( $key, $value );

    $has_content_length = 1 if $key eq "Content-Length";
    $use_chunked_transfer++ if $key eq "Transfer-Encoding" and $value eq "chunked";
  }

  if(!defined $body) {
    croak "Responder given no body in void context" unless defined wantarray;

    unless( $has_content_length ) {
      $response->header( "Transfer-Encoding" => "chunked" );
      $use_chunked_transfer++;
    }

    $req->write( $response->as_string( CRLF ) );

    return $use_chunked_transfer ?
      Net::Async::HTTP::Server::PSGI::ChunkWriterStream->new( $req ) :
      Net::Async::HTTP::Server::PSGI::WriterStream->new( $req );
  }
  elsif( ref $body eq "ARRAY" ) {
    unless( $has_content_length ) {
      my $len = 0;
      my $found_undef;
      $len += length( $_ // ( $found_undef++, "" ) ) for @$body;
      carp "Found undefined value in PSGI body" if $found_undef;

      $response->content_length( $len );
    }

    $req->write( $response->as_string( CRLF ) );

    $req->write( $_ ) for @$body;
    $req->done;
  }
  else {
    unless( $has_content_length ) {
      $response->header( "Transfer-Encoding" => "chunked" );
      $use_chunked_transfer++;
    }

    $req->write( $response->as_string( CRLF ) );

    if( $use_chunked_transfer ) {
      $req->write( sub {
        # We can't return the EOF chunk and set undef in one go
        # What we'll have to do is send the EOF chunk then clear $body,
        # which indicates end
        return unless defined $body;

        local $/ = \8192;
        my $buffer = $body->getline;

        # Form HTTP chunks out of it
        defined $buffer and
          return sprintf( "%X${\CRLF}%s${\CRLF}", length $buffer, $buffer );

        $body->close;
        undef $body;
        return "0${\CRLF}${\CRLF}";
      } );
    }
    else {
      $req->write( sub {
        local $/ = \8192;
        my $buffer = $body->getline;

        defined $buffer and return $buffer;

        $body->close;
        return undef;
      } );
    }

    $req->done;
  }
}

method on_request ($req) {
  my $env = $$req{req};

  $$env{'io.async.loop'} = $self->get_loop;

  my $res = Plack::Util::run_app $$self{app}, $env;
  my $responder = sub { _responder($req, $res) };

  ref $res eq 'ARRAY' ? $responder->()
    : ref $responder eq 'CODE' ? $res->($responder)
    : die "Bad response: $res";

  $$env{'io.async.loop'}->stop if $$env{'psgix.harakiri.commit'}
}

1