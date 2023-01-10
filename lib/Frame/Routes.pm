use Object::Pad;

package Frame::Routes;
use Frame::Routes::Route;
class Frame::Routes :does(Frame::Routes::Route::Factory);

use utf8;
use v5.36;
use autodie;

use Data::Dumper;
use Scalar::Util qw/blessed refaddr/;

state $rere = qr/^regexp$/i;

field @routes :reader;

ADJUSTPARAMS ( $params ) {
  $self->app($$params{app}) # TODO: Remember why this worried me and fix it
}

method _add_route($route) {
  my $branch = $route->tree->{$route->method}{scalar $route->pattern_arr};
  $self->tree->{$route->method}{scalar $route->pattern_arr}->@{keys %$branch} = (values %$branch);

  push @routes, $route
}

method match ($req) {
  my @path = $req->path eq '/'
    ? '/'
    : split '/', substr($req->path, 1), -1;
  
  pop @path if $path[-1] eq '';

  my $branches = $self->tree->{$req->method}{scalar @path} || return undef;
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
        next unless $self->patterns->{$key} && !$$barren{$i}{$key};

        $match = ref $self->patterns->{$key} eq 'CODE'
          ? $self->patterns->{$key}->($self->app, $part) ? 1 : 0
          : ref($self->patterns->{$key}) =~ $rere
            ? $part =~ $self->patterns->{$key} ? 1 : 0
            : defined $self->patterns->{$key} ? 0 : $part ne '';

        if($match) {
          $match = $key;
          push @placeholder_matches, $part;
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
    for (my $i = 0; $i < scalar @placeholder_matches; $i++) {
      $placeholder_matches[$i] = { ($curr->placeholders)[$i] => $placeholder_matches[$i] }
    }

    $req->set_placeholders(@placeholder_matches);
    return $curr
  }

  undef
}

method under {

}

1