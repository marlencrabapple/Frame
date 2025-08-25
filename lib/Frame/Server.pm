use Object::Pad ':experimental(:all)';

package Frame::Server;

class Frame::Server
  : isa(Net::Async::HTTP::Server::PSGI);

use utf8;
use v5.40;

use Carp;
use Const::Fast;
use Hash::MultiValue;

use Frame::Server::Request;
use Frame::Server::Protocol;

const our $CRLF => "\r\n";

field $plack_handler : mutator;

method _init : override ($params) {
    $$params{handle_class}  = "Frame::Server::Protocol";
    $$params{request_class} = "Frame::Server::Request";
    $self->IO::Async::Listener::_init($params);
}

sub _write_headers ( $req, $lines, $c = 'close', %opts ) {

    if ( $req->keep_alive ) {
        $c = 'keep-alive';
        $req->{conn}->restart_timeout('keep_alive');
    }

    push @$lines, sprintf "Connection: $c"
      unless $req->protocol eq 'HTTP/1.1' && $c eq 'keep-alive';

    foreach my $key ( $opts{res_headers}->keys ) {
        push @$lines, "$key: " . join ',', $opts{res_headers}->get_all($key);
    }

    $req->write( join $CRLF, ( @$lines, $CRLF ) );
}

# Mostly copied from an anon sub in $self->SUPER::on_request
sub _responder ( $req, $res ) {
    my ( $status, $headers, $body ) = @$res;

    my @lines =
      ( $req->protocol . " $status " . HTTP::Status::status_message($status) );

    my $res_headers = Hash::MultiValue->new;

    my $has_content_length = 0;
    my $use_chunked_transfer;

    while ( my ( $key, $val ) = splice @$headers, 0, 2 ) {
        $res_headers->set( $key => $val );

        $has_content_length = 1 if $key eq "Content-Length";
        $use_chunked_transfer++
          if $key eq "Transfer-Encoding" and $val eq "chunked";
    }

    if ( !defined $body ) {
        croak 'Responder given no body in void context'
          unless defined wantarray;

        unless ($has_content_length) {
            push @lines, 'Transfer-Encoding: chunked';
            $use_chunked_transfer++;
        }

        _write_headers( $req, \@lines, 'close', res_headers => $res_headers );

        return $use_chunked_transfer
          ? Net::Async::HTTP::Server::PSGI::ChunkWriterStream->new($req)
          : Net::Async::HTTP::Server::PSGI::WriterStream->new($req);
    }
    elsif ( ref $body eq 'ARRAY' ) {
        unless ($has_content_length) {
            my $len = 0;
            my $found_undef;
            $len += length( $_ // ( $found_undef++, "" ) ) for @$body;
            carp "Found undefined value in PSGI body" if $found_undef;

            push @lines, "Content-Length: $len";
        }

        _write_headers( $req, \@lines, 'close', res_headers => $res_headers );

        $req->write($_) for @$body;
        $req->done;
    }
    else {
        unless ($has_content_length) {
            push @lines, 'Transfer-Encoding: chunked';
            $use_chunked_transfer++;
        }
        _write_headers( $req, \@lines, 'close', res_headers => $res_headers );

        if ($use_chunked_transfer) {
            $req->write(
                sub {
                 # We can't return the EOF chunk and set undef in one go
                 # What we'll have to do is send the EOF chunk then clear $body,
                 # which indicates end
                    return unless defined $body;

                    local $/ = \8192;
                    my $buffer = $body->getline;

                    # Form HTTP chunks out of it
                    defined $buffer
                      and return
                      sprintf( "%X$CRLF%s$CRLF", length $buffer, $buffer );

                    $body->close;
                    undef $body;
                    return "0$CRLF$CRLF";
                }
            );
        }
        else {
            $req->write(
                sub {
                    local $/ = \8192;
                    my $buffer = $body->getline;

                    defined $buffer and return $buffer;

                    $body->close;
                    return undef;
                }
            );
        }

        $req->done;
    }
}

method on_accept ($conn) {
    $self->SUPER::on_accept($conn);

    my %timer_args_base = (
        remove_on_expire => 1,
        on_expire        => sub ($self) {
            $conn->_flush_requests
              ; # TODO: See if this makes pipeline reqs work correctly or breaks things
            $conn->close;
        }
    );

    foreach my $key (qw/req_header read keep_alive inactivity/) {
        my $field = "$key\_timeout";

        $conn->$field(
            IO::Async::Timer::Countdown->new(
                %timer_args_base,
                delay         => $plack_handler->$field,
                notifier_name => $field
            )
        );

        $self->loop->add( $conn->$field );
        $conn->$field->start unless $key eq 'keep_alive';

        my $asdf = $conn->$field;
    }

    $conn;
}

method on_request ($req) {
    my $env = $$req{req};

    #Frame::Base->dmsg( { req => $req } );

    my $res       = Plack::Util::run_app $$self{app}, $env;
    my $responder = sub { _responder( $req, $res ) };

        ref $res eq 'ARRAY'      ? $responder->()
      : ref $responder eq 'CODE' ? $res->($responder)
      :                            die "Bad response: $res";

    $self->loop->stop if $$env{'psgix.harakiri.commit'};
}
