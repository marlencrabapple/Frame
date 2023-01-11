use Object::Pad;

package Plack::Handler::Net::Async::HTTP::Server::Prefork;
class Plack::Handler::Net::Async::HTTP::Server::Prefork
  # :isa(Frame::Server)
  :isa(Plack::Handler::Net::Async::HTTP::Server)
  :does(Frame::Base);

use utf8;
use v5.36;

# use Frame::Server;
use Net::Async::HTTP::Server::PSGI;
use IO::Async::Loop;
use Parallel::Prefork;
use Server::Starter ();
use Data::Dumper;

state $pm_sig_re = qr/^(TERM|USR1)$/; # Does this need capturing?

field $port :param;
field $host :param;

field $max_workers = 10;
field $spawn_interval;
field $err_respawn_interval;
field $ioloop;
field $pm;
field %pm_args;
field @children;

ADJUSTPARAMS ($params) {
  # $max_workers = ;
  # $spawn_interval = ;
  # $err_respawn_interval = 
  $ioloop = IO::Async::Loop->new;

  say Dumper($params, $self) if $ENV{FRAME_DEBUG};

  $self->{is_multiprocess} = 1;
  $self->{multiprocess} = 1;
  $self->{'psgi.multiprocess'} = 1;
  $self->{max_workers} = $max_workers
}

method register_service ($app) {
  my $queuesize = $self->{queuesize} || 10;

  foreach my $listen ($$self{listen}->@*) {
    my $httpserver = Net::Async::HTTP::Server::PSGI->new(
      app => $app
    );

    $ioloop->add($httpserver);

    my ($host, $path);

    if($listen =~ s/^\[([0-9a-f:]+)\]://i) {
      $host = $1;
    }
    elsif($listen =~ s/^([^:]+?)://) {
      $host = $1;
    }
    elsif($listen =~ s/^://) {
      # OK
    }
    else {
      $path = $listen;
    }
 
    if( defined $path ) {
      require IO::Socket::UNIX;

      unlink $path if -e $path;

      my $socket = IO::Socket::UNIX->new(
        Local  => $path,
        Listen => $queuesize,
      ) or die "Cannot listen on $path - $!";

      $httpserver->configure( handle => $socket );
    }
    else {
      my ($service, $ssl) = split m/:/, $listen;
      $ssl ||= $self->{ssl};

      my %SSL_args;
      if($ssl) {
        require IO::Async::SSL;
        %SSL_args = (
          extensions => [qw( SSL )],
        );

        foreach my $key ( grep m/^ssl_/, keys %$self ) {
          my $val = $self->{$key};
          $key =~ s/^ssl/SSL/;
          $SSL_args{$key} = $val
        };
      }

      $httpserver->listen(
        host     => $host,
        service  => $service,
        socktype => 'stream',
        queuesize => $queuesize,

        %SSL_args,

        on_notifier => sub {
          $self->{server_ready}->({
            host            => $host,
            port            => $service,
            proto           => $ssl ? "https" : "http",
            server_software => ref $self,
          }) if $self->{server_ready}
        },
      )->get;
    }
  }
  
  if($max_workers != 0) {
    %pm_args = (
      max_workers => $max_workers,
      trap_signals => {
        TERM => 'TERM',
        HUP  => 'TERM'
      }
    );

    if($spawn_interval) {
      $pm_args{trap_signals}{USR1} = [ 'TERM', $spawn_interval ];
      $pm_args{spawn_interval} = $spawn_interval
    }

    $pm_args{err_respawn_interval} = $err_respawn_interval
      if $err_respawn_interval;

    $pm = Parallel::Prefork->new(\%pm_args);

    while($pm->signal_received !~ $pm_sig_re) {
      $pm->start and next;
      srand((rand() * 2 ** 30) ^ $$ ^ time);

      my $loop = $ioloop;
      $loop->run;

      $pm->finish
    }

    my $timeout = $spawn_interval ? $spawn_interval * $max_workers : 1;

    while($pm->wait_all_children($timeout)) {
      $pm->signal_all_children('TERM')
    }
  }
  else {
    local $SIG{TERM} = sub { exit 0 };

    while (1) {
      $ioloop->run
    }
  }
}

1