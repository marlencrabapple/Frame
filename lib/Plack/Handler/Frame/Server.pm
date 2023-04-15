use Object::Pad;

package Plack::Handler::Frame::Server;
class Plack::Handler::Frame::Server :does(Frame::Base);

use utf8;
use v5.36;

use Frame::Server;
use IO::Async::Loop;
use Parallel::Prefork;
use Server::Starter ();
use List::AllUtils qw(any first);

use constant SIGRERE => qr/^(TERM|USR1)$/;

field $host :param;
field $port :param;
field $req_header_timeout :reader :param = 2;
field $keep_alive_timeout :reader :param = 2;
field $read_timeout :reader :param = 300;
field $inactivity_timeout :reader :param = 30;
field $max_workers :param = 10;
field $queue_size :param = 10;
field $ssl :param = undef;

field @listen;
field %ssl_args;
field %pm_args;
field $loop;
field $server_ready;

ADJUSTPARAMS ($params) {
  # TODO: Server::Starter stuff
  # ...
  
  $server_ready = $$params{server_ready}
    if $$params{server_ready} && ref $$params{server_ready} eq 'CODE';

  @listen = $$params{listen}->@*
    if $$params{listen} && ref $$params{listen} eq 'ARRAY';

  %pm_args = (
    max_workers => $max_workers,
    trap_signals => {
      TERM => 'TERM',
      HUP => 'TERM'
    }
  );

  if($$params{spawn_interval}) {
    $pm_args{trap_signals}{USR1} = [ 'TERM', $$params{spawn_interval} ];
    $pm_args{spawn_interval} = $$params{spawn_interval}
  }

  $pm_args{err_respawn_interval} = $$params{err_respawn_interval}
    if $$params{err_respawn_interval};

  if($ssl || any { /^ssl_/ } keys %$params) {
    require IO::Async::SSL;
    $ssl_args{extensions} = ['SSL'];
    %ssl_args = map { $_ =~ s/^ssl/SSL/r, $$params{$_} } grep { /^ssl_/ } keys %$params
  }

  $loop = IO::Async::Loop->new
}

method run ($app) {
  $self->register_service($app);

  if($max_workers > 0) {
    my $pm = Parallel::Prefork->new(\%pm_args);

    while($pm->signal_received !~ SIGRERE) {
      $pm->start and next;
      srand((rand() * 2 ** 30) ^ $$ ^ time);
      $loop->run;
      $pm->finish
    }

    my $timeout = $pm_args{spawn_interval}
      ? $pm_args{spawn_interval} * $max_workers
      : 1;

    while($pm->wait_all_children($timeout)) {
      $pm->signal_all_children('TERM')
    }
  }
  else {
    $loop->run
  }
}

method register_service ($app) {
  foreach my $interface (@listen) {
    my $server = Frame::Server->new(app => $app);
    $server->plack_handler = $self;
    $loop->add($server);

    my @patterns = (qr/^\[([0-9a-f:]+)\]:/i, qr/^([^:]+?):/, qr/^:/);
    my $host;

    if(any { $interface =~ s/$_// ? eval { $host = $1; 1 } : 0 } @patterns) {
      my ($service, $is_ssl) = split m/:/, $interface;

      $server->listen(
        host => $host,
        service => $service,
        socktype => "stream",
        queuesize => $queue_size,

        %ssl_args,

        on_notifier => sub {
          $server_ready->({
            host => $host,
            port => $service,
            proto => $is_ssl || $ssl ? "https" : "http",
            server_software => ref $self
          }) if $server_ready;
        }
      )->get
    }
    elsif(my $path = $interface) {
      require IO::Socket::UNIX;

      unlink $path if -e $path;

      my $socket = IO::Socket::UNIX->new(
        Local  => $path,
        Listen => $queue_size,
      ) or die "Cannot listen on $path - $!";

      $server->configure(handle => $socket)
    }
  }
}

1