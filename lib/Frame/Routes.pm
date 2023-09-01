use Object::Pad;

package Frame::Routes;
class Frame::Routes :does(Frame::Routes::Common);

use utf8;
use v5.36;

use Frame::Routes::Route;
use Frame::Routes::Pattern;
use Frame::Request::Placeholder::Dummy;

use List::Util 'uniq';
use Scalar::Util qw/blessed refaddr/;

my $ptn = join '|', Frame::Routes::Common::METHODS;
use constant METHRE => qr/^ptn$/i;
use constant RERE => qr/^regexp$/i;

method add ($methods, $pattern, @args) {
  my %route_args = ( factory => $self->app );
  my $opts = ref $args[$#args] eq 'HASH' ? pop @args : {};

  my $dest = $args[$#args];

  # if (ref $dest eq 'HASH' && scalar @$dest{qw(c sub)}) {
  #   $route_args{dest} = { %$dest }
  # }
  if (ref $dest eq 'CODE') {
    $route_args{dest}{sub} = $dest
  }
  elsif ($dest && !ref($dest)) {
    use constant DESTRE => qr/^(?:([\w\-]+)(?:#))?([\w]+)$/;
    my ($c, $sub) = $dest =~ DESTRE;
    
    if ($c) {
      $route_args{dest} = {
        sub => $sub,
        c => join '::', map { ucfirst $_ } split '-', $c
      } if $sub
    }
  }

  if ($route_args{dest}{c}) {
    my $c = $self->app->controller_namespace . '::' . $route_args{dest}{c};

    eval "require $c; 1" or die $@;

    my $sub = $route_args{dest}{sub};
    $c->can($route_args{dest}{sub}) || $c->$sub;

    $route_args{dest}{c} = $c
  }

  my $has_args;
  $route_args{eol} = $route_args{dest}{sub} && !$$opts{inline} ? 1 : 0;

  foreach my $arg (@args) {
    if (ref $arg eq 'CODE') {
      $route_args{filter} = $arg;
      $has_args = 1
    }
    elsif (ref $arg eq 'HASH') {
      $self->patterns->@{(values %$arg)} = (values %$arg);
      $route_args{pattern} = Frame::Routes::Pattern->new(
        pattern => $pattern,
        filters => $arg
      );
      $has_args = 1;
    }
    elsif (ref $arg eq 'ARRAY' && scalar @$methods == 0) {
      next unless $$arg[0] =~ METHRE;
      $route_args{methods} = $arg;
      $has_args = 1
    }
  }

  die "Invalid route destination '$dest'"
    if !$has_args && !$route_args{eol} && scalar @args == 1;
  
  $route_args{pattern} //= Frame::Routes::Pattern->new(pattern => $pattern);
  $methods = [ Frame::Routes::Common::METHODS ] unless scalar @$methods;

  if ($$opts{prev_stop}) {
    my @stops;
    my $prev_stop = $$opts{prev_stop};
    while ($prev_stop) {
      unshift @stops, $prev_stop;
      $prev_stop = $prev_stop->prev_stop
    }
    $route_args{stops} = \@stops
  }
  
  my $route = Frame::Routes::Route->new(
    %route_args, %$opts,
    methods => $methods,
    root => $self
  );
  
  foreach my $method (@$methods) {
    my $branch = $route->tree->{$method}[scalar $route->pattern_arr - 1];
    $self->tree->{$method}[scalar $route->pattern_arr - 1]->@{keys %$branch} = (values %$branch);
    push $self->routes->@*, $route
  }

  $route
}

method match ($req) {
  my @path = $req->path eq '/'
    ? '/'
    : split '/', substr($req->path, 1), -1;
  
  pop @path if $path[-1] eq '';

  my $branches = $self->tree->{$req->method}[scalar @path - 1]
    || return undef;
  
  my $i = 0;
  my $prev = {};
  my $barren = {};
  my @placeholder_matches;

  BRANCH: while (my $curr = $$prev{branch} // $branches) {
    $prev = {};

    PATH_PART: foreach my $part (@path) {
      my ($match, $wildcard_ne, $has_placeholder);

      if ($part ne '' && $$curr{$part} && !$$barren{$i}{$part} && !$self->patterns->{$part}) {
        $match = $part;
        $has_placeholder = undef
      }
      else {
        PLACEHOLDER_RESTRICTION: foreach my $key (keys %$curr) {
          next if $$barren{$i}{$key};

          $match = ref $self->patterns->{$key} eq 'CODE'
            ? $self->patterns->{$key}->($self->app, $req, $part) ? 1 : 0
            : ref($self->patterns->{$key}) =~ RERE
              ? $part =~ $self->patterns->{$key} ? 1 : 0
              : defined $self->patterns->{$key} ? 0
                : $part ne '' && $key eq $self->app ? 2 : 0;

          if ($match == 2) {
            $wildcard_ne = 1;
            $match = undef;
            next PLACEHOLDER_RESTRICTION
          }
          elsif ($match == 1) {
            $match = $key;
            last PLACEHOLDER_RESTRICTION
          }
        }

        if($has_placeholder = ($match || $wildcard_ne)) {
          $match = $self->app unless $match;
          push @placeholder_matches, $part
        }
      }

      if ($match) {
        $$prev{i} = $i;
        $$prev{key} = $match;
        $$prev{branch} = $curr;
        $$prev{has_placeholder} = $has_placeholder;

        $curr = $$curr{$match};

        next PATH_PART
      }
      else {
        last unless $$prev{branch};
        $$barren{$$prev{i}}{$$prev{key}} = 1;
        next BRANCH
      }
    }
    continue {
      $i++
    }
  }
  continue {
    if ($curr isa 'Frame::Routes::Route' && $i == scalar @path) {
      if ($curr->has_stops) {
        foreach my $stop (grep { $_->dest } $curr->stops->@*) {
          my @dummies = ((undef) x scalar $stop->placeholders);
          my @placeholder_matches = $self->prep_placeholders($req, $stop, @dummies);

          map { tie $_, 'Frame::Request::Placeholder::Dummy' } @dummies;

          my $res = $self->app->route($stop, $req);
          return $res unless $res == 1
        }
      }

      $self->prep_placeholders($req, $curr, @placeholder_matches);
      return $curr if $curr->eol;

      $$barren{$$prev{i}}{$$prev{key}} = 1
    }

    last BRANCH unless uniq (keys $$prev{branch}->%*, keys $$barren{$i}->%*);

    pop @placeholder_matches if $$prev{has_placeholder};
    $i--
  }
  
  undef
}

method prep_placeholders ($req, $route, @placeholders) {
  for (my $i = 0; $i < scalar @placeholders; $i++) {
    $placeholders[$i] = { ($route->placeholders)[$i] => $placeholders[$i] }
  }
  
  $req->set_placeholders(@placeholders)
}

1