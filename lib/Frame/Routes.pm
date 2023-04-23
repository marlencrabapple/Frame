use Object::Pad;

package Frame::Routes;
class Frame::Routes :does(Frame::Routes::Route::Factory);

use utf8;
use v5.36;

use List::Util 'uniq';
use Scalar::Util qw/blessed refaddr/;

use constant RERE => qr/^regexp$/i;

field @routes :reader;

method _add_route ($route) {
  my $branch = $route->tree->{$route->method}{scalar $route->pattern_arr};
  $self->tree->{$route->method}{scalar $route->pattern_arr}->@{keys %$branch} = (values %$branch);
  push @routes, $route
}

method match ($req) {
  my @path = $req->path eq '/'
    ? '/'
    : split '/', substr($req->path, 1), -1;
  
  pop @path if $path[-1] eq '';

  my $branches = $self->tree->{$req->method}{scalar @path}
    || return undef;
  
  my $i = 0;
  my $prev = {};
  my $barren = {};
  my @placeholder_matches;

  BRANCH: while(my $curr = $$prev{branch} // $branches) {
    $prev = {};

    PATH_PART: foreach my $part (@path) {
      my ($match, $wildcard_ne, $has_placeholder);

      dmsg $prev, $curr, $barren, $i, $part if $ENV{FRAME_DEBUG};

      if($part ne '' && $$curr{$part} && !$$barren{$i}{$part} && !$self->patterns->{$part}) {
        $match = $part;
        $has_placeholder = undef
      }
      else {
        PLACEHOLDER_RESTRICTION: foreach my $key (keys %$curr) {
          next if $$barren{$i}{$key};

          $match = ref $self->patterns->{$key} eq 'CODE'
            ? $self->patterns->{$key}->($req, $part) ? 1 : 0
            : ref($self->patterns->{$key}) =~ RERE
              ? $part =~ $self->patterns->{$key} ? 1 : 0
              : defined $self->patterns->{$key} ? 0
                : $part ne '' && $key eq $self->app ? 2 : 0;

          dmsg $part, $key, $self->patterns, $self->patterns->{$key}, $match, $prev, $barren
            if $ENV{FRAME_DEBUG};

          if($match == 2) {
            $wildcard_ne = 1;
            $match = undef;
            next PLACEHOLDER_RESTRICTION
          }
          elsif($match == 1) {
            $match = $key;
            last PLACEHOLDER_RESTRICTION
          }
        }

        dmsg $match, $wildcard_ne if $ENV{FRAME_DEBUG};

        if($has_placeholder = ($match || $wildcard_ne)) {
          $match = $self->app unless $match;
          push @placeholder_matches, $part
        }
      }

      if($match) {
        $$prev{i} = $i;
        $$prev{key} = $match;
        $$prev{branch} = $curr;
        $$prev{has_placeholder} = $has_placeholder;
        $curr = $$curr{$match};
        next PATH_PART
      }
      else {
        dmsg $prev, $barren if $ENV{FRAME_DEBUG};
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
    if($i == scalar @path && defined blessed $curr && blessed $curr eq 'Frame::Routes::Route') {
      for (my $i = 0; $i < scalar @placeholder_matches; $i++) {
        $placeholder_matches[$i] = { ($curr->placeholders)[$i] => $placeholder_matches[$i] }
      }

      $req->set_placeholders(@placeholder_matches);

      return $curr
    }

    dmsg $i, $prev, $barren, [keys $$prev{branch}->%*], [keys $$barren{$i}->%*]
      , [uniq (keys $$prev{branch}->%*, keys $$barren{$i}->%*)] if $ENV{FRAME_DEBUG};

    last BRANCH unless uniq (keys $$prev{branch}->%*, keys $$barren{$i}->%*);

    pop @placeholder_matches if $$prev{has_placeholder};
    $i--
  }
  
  undef
}

method under {
  ...
}

1