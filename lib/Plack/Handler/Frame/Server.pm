use Object::Pad ':experimental(:all)';

package Plack::Handler::Frame::Server;

class Plack::Handler::Frame::Server : does(Frame::Base);

use utf8;
use v5.40;

use IO::Async::Loop;
use List::Util qw'uniq any first all';
use Const::Fast;
use Parallel::Prefork;
use Server::Starter;
use Frame::Server;
use IO::Handle::Common;
use Path::Try;
use PadWalker qw'var_name';

const our $SIG_RE => qr/^(TERM|USR1)$/;
const our %MATCH_HOST => (
    ipv6     => qr/^\[([0-9a-f:]+)\]:/i,
    hostname => qr/^([^:]+?):/,
    listen   => qr/^:/
);

field $host               : reader;    #: param;
field $port               : reader;    #: param;
field $req_header_timeout : reader : param = 2;
field $keep_alive_timeout : reader : param = 2;
field $read_timeout       : reader : param = 300;
field $inactivity_timeout : reader : param = 30;

field $max_workers : reader = 10;
field $queue_size : param : reader = 10;

field $ssl           : param = undef;
field $ssl_server    : param = undef;
field $ssl_cert_file : param = undef;
field $ssl_key_file  : param = undef;

field $listen;
field $ssl_args;
field $pm_args = {
    trap_signals => {
        ( 'TERM' x 2 ), HUP => 'TERM'
    }
};

field $server_ready;

field $loop = IO::Async::Loop->new;
field $pm;
field $server;

my method adjust( $field, $newval //= $field ) {
    my $name = var_name( 0, $field );
    eval "$name = \$newval" if $name;
    $field;
}

ADJUST : params (:$server_ready) {
    $self->adjust($server_ready)
      if $server_ready && refstr($server_ready) eq 'CODE'
};

ADJUST : params (:$listen, :$port, :$host) {
    my @listen = ();

    if ( $ENV{SERVER_STARTER_PORT} ) {
        foreach my ( $hostport, $fd ) (Server::Starter::server_ports) {
            my %listen = ();
            if ( my ( $host, $port ) = split /:/, $hostport ) {
                @$listen{qw'host port'} = ( $host, $port );
            }
            else {
                $listen{port} = $hostport;
            }

            $listen{sock} = $self->new_inet_socket( protocol => 'tcp' );
        }
    }

};

ADJUST:
params(
    : $max_workers          = 10,
    : $spawn_interval       = undef,
    : $err_respawn_interval = undef
  )
{
    $$pm_args{trap_signals}{USR1}   = [ 'TERM', $spawn_interval ];
    $$pm_args{spawn_interval}       = $spawn_interval;
    $$pm_args{err_respawn_interval} = $err_respawn_interval;

    $pm = Parallel::Prefork->new($pm_args)
};

method register_service ($psgi) {
    foreach my $listen (@$listen) {
        my $server = Frame::Server->new( app => $psgi );
        $server->plack_handler = $self;
        $loop->add($server);
    }
}

method run($psgi) {
    $self->register_service($psgi);

}
