use Object::Pad;

package Frame::Routes;

use v5.36;
use autodie;

use Frame::Routes::Route;

use Data::Dumper;
use Scalar::Util 'blessed';

# This can (and maybe should?) be done with AUTO instead of roles
class Frame::Routes :does(Frame::Routes::Route::Factory) {
  #field $app :param :weak :accessor; # This is temporary hopefully
  field $routes;
  field $patterns;

  ADJUSTPARAMS ( $params ) {
    $routes = {};
    $patterns = {};

    $self->app($$params{app}) # THIS is temporary hopefully
                              # Because I'm gonna have to redo a lot of things otherwise potentially...
  }

  method _add_route($route) {
    my @pattern = $route->pattern->pattern =~ /([^\/]+)(?:\/)?/g;
    my $curr = $$routes{$route->method} //= {};
    my $prev;
    my $last_key;
    
    foreach my $part (@pattern) {
      $prev = $curr;

      if($part =~ /^\:(.+)$/) {
        my $placeholder_key = $1;
        my $filter = $route->pattern->filters->{$placeholder_key};
        
        $$patterns{\$filter} = { key => $placeholder_key, filter => $filter };
        $last_key = \$filter
      }
      else {
        $last_key = $part
      }

      $$prev{$last_key} = {};
      $curr = $$prev{$last_key}
    }

    $route->pattern->pattern eq '/'
      ? $$curr{'/'} = $route
      : $$prev{$last_key} = $route
  }

  method match($req) {
    my @path = $req->path eq '/' ? '/' : grep { $_ } split '/', $req->path;
    
    my $routes = $$routes{$req->method};
    my $last_hit = $routes;
    my %placeholders;

    foreach my $part (@path) {
      $self->app->fatal($self->app->render_404)
        if blessed $last_hit eq 'Frame::Routes::Route';

      if($$last_hit{$part}) {
        $last_hit = $$last_hit{$part}
      }
      else {
        foreach my $key (keys %$last_hit) {
          if($$patterns{$key}) {
            my $part_matches = 0;

            if(ref $$patterns{$key}{filter} eq 'CODE') {
              $part_matches = 1 if $$patterns{$key}{filter}($part)
            }
            elsif(ref($$patterns{$key}{filter}) =~ /^regexp$/i) {
              $part_matches = 1 if $part =~ $$patterns{$key}{filter}
            }
            elsif(!$$patterns{$key}{filter}) {
              $part_matches = 1
            }

            if($part_matches) {
              $req->placeholder($$patterns{$key}{key}, $part);
              $last_hit = $$last_hit{$key};
              last
            }
          }
        }
      }
    }
    
    return $last_hit if blessed $last_hit eq 'Frame::Routes::Route';
    $self->app->fatal($self->app->render_404)
  }

  method under {

  }
}