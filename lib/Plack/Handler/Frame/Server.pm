use Object::Pad;

package Plack::Handler::Frame::Server;
class Plack::Handler::Frame::Server;

use utf8;
use v5.36;

use Data::Dumper;
use IO::Async::Loop;
use Parallel::Prefork;
use Server::Starter ();

use Frame::Server;

field $host :param;
field $port :param;

field $max_workers = 10;
field $queue_size = 10;
field @listen;
field $ssl :reader;
field %ssl_args;
field %pm_args;
field $loop;
field $server_ready;

ADJUSTPARAMS ($params) {
  # TODO: Server::Starter stuff
  # ...

  $max_workers = $$params{max_workers} // $max_workers;
  $queue_size = $$params{queue_size} // $queue_size;
  
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

  if($ssl = $$params{ssl}) {
    require IO::Async::SSL;
    $ssl_args{extensions} = [qw(SSL)]
  }

  foreach my $key (grep { /^ssl_/ } keys %$params) {
    my $val = $$params{$key};
    $key =~ s/^ssl/SSL/;
    $ssl_args{$key} = $val
  }

  $loop = IO::Async::Loop->new
}

method run ($app) {
  $self->register_service($app);

  if($max_workers > 0) {
    my $pm = Parallel::Prefork->new(\%pm_args);

    state $sigrere = qr/^(TERM|USR1)$/;

    while($pm->signal_received !~ $sigrere) {
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

# Mostly copied from $self->SUPER::run
method register_service ($app) {
  foreach my $listen (@listen) {
    my $server = Frame::Server->new(app => $app);
    $loop->add($server);

    my ($host, $path);

    if($listen =~ s/^\[([0-9a-f:]+)\]://i) {
      $host = $1
    }
    elsif($listen =~ s/^([^:]+?)://) {
      $host = $1
    }
    elsif($listen =~ s/^://) {
      # OK
    }
    else {
      $path = $listen
    }

    if(defined $path) {
      require IO::Socket::UNIX;

      unlink $path if -e $path;

      my $socket = IO::Socket::UNIX->new(
        Local  => $path,
        Listen => $queue_size,
      ) or die "Cannot listen on $path - $!";

      $server->configure(handle => $socket);
    }
    else {
      my ($service, $ssl) = split m/:/, $listen;
      $ssl ||= $self->ssl;

      $server->listen(
        host     => $host,
        service  => $service,
        socktype => "stream",
        queuesize => $queue_size,

        %ssl_args,

        on_notifier => sub {
          $server_ready->({
            host            => $host,
            port            => $service,
            proto           => $ssl ? "https" : "http",
            server_software => ref $self
          }) if $server_ready;
        }
      )->get
    }
  }
}

1