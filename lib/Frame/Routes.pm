use Object::Pad;

package Frame::Routes;
use Frame::Routes::Route;
class Frame::Routes :does(Frame::Routes::Route::Factory);

use utf8;
use v5.36;
use autodie;

use Data::Dumper;
use Scalar::Util 'blessed';

state $rere = qr/^regexp$/i; Dumper(\$rere);

field @routes :reader;
field $tree :reader; # Not really a tree
field $patterns :reader;

ADJUSTPARAMS ( $params ) {
  $tree = {};
  $patterns = {};
  $self->app($$params{app}) # TODO: Remember why this worried me and fix it
}

method _add_route($route) {
  my @pattern = $route->pattern->pattern eq '/' ? '/' : $route->pattern->pattern =~ /([^\/]+)(?:\/)?/g;
  my $depth = scalar @pattern;
  my $branches = $$tree{$route->method}{$depth} //= {};
  my $curr = $branches;

  my $prev;
  my $last_key;
  
  foreach my $part (@pattern) {
    $prev = $curr;

    if($part =~ /^\:(.+)$/) {
      my $placeholder_key = $1;
      my $filter = $route->pattern->filters->{$placeholder_key};
      
      $$patterns{\$filter} = { $placeholder_key => $filter };
      $last_key = \$filter
    }
    else {
      $last_key = $part
    }

    $$prev{$last_key} = {};
    $curr = $$prev{$last_key}
  }

  $$prev{$last_key} = $route;
  push @routes, $route
}

method match ($req) {
  my @path = $req->path eq '/'
    ? '/'
    : split '/', substr($req->path, 1), -1;
  
  pop @path if $path[-1] eq '';

  my $branches = $$tree{$req->method}{scalar @path} || return 0;
  my $barren = {};

  NEXT_BRANCH:
  my $i = 0;
  my $curr = $branches;
  my $prev = undef;
  my $prev_key = undef; # Maybe $curr_key (or $prev_curr_key? $curr_prev_key? $prev__path_to_curr?) is a better name
  my @placeholder_matches = ();
  
  PATH_PART: foreach my $part (@path) {
    my $match;

    if($$curr{$part}) {
      last if $$barren{$i}{$part};
      $match = $part
    }
    else {
      PLACEHOLDER_RESTRICTION: foreach my $key (keys %$curr) {
        next unless $$patterns{$key} && !$$barren{$i}{$key};
        my ($placeholder_key, $placeholder_filter) = $$patterns{$key}->%*;

        $match = ref $placeholder_filter eq 'CODE'
          ? $placeholder_filter->($part) ? 1 : 0
          : ref($placeholder_filter) =~ $rere
            ? $part =~ $placeholder_filter ? 1 : 0
            : defined $placeholder_filter ? 0 : $part ne '';

        if($match) {
          $match = $key;
          push @placeholder_matches, { $placeholder_key => $part };
          last
        }
      }
    }

    if($match) {
      $prev = $curr;
      $prev_key = $match;
      $curr = $$curr{$match};
      next
    }
    else {
      if($prev) {
        $$barren{$i > 0 ? $i - 1 : 0}{$prev_key} = 1;
        goto NEXT_BRANCH
      }
      else {
        last
      }
    }
  }
  continue {
    $i++
  }

  if(defined blessed $curr && blessed $curr eq 'Frame::Routes::Route') {
    $req->set_placeholders(@placeholder_matches);
    return $curr
  }

  undef
}

method under {

}

1