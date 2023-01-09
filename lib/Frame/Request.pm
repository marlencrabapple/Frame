use Object::Pad;

package Frame::Request;
class Frame::Request :isa(Plack::Request) :does(Frame::Base);

use utf8;
use v5.36;
use autodie;

use Data::Dumper;
use List::Util 'any';

state @ajax_headers_state = ('X-Robo-Req');
our $ajax_headers = \@ajax_headers_state;

# field $env :param;
# field $app :param;
field @placeholders_ord :reader;
field $placeholders :reader;
field @placeholder_values_ord :reader;
field $stash :mutator;
field @ajax_headers;

# sub BUILDARGS {
#   my ($class, $env) = @_;
#   $class->SUPER::new($env)
# }

# ADJUSTPARAMS ( $params ) {
#   $stash //= {};
#   @ajax_headers = @ajax_headers_state
# }

method placeholder ($key, $value = undef) {
  if($value && !$$placeholders{$key}) {
    push @placeholders_ord, { $key => $value };
    push @placeholder_values_ord, $value;
    $$placeholders{$key} = $value
  }

  $$placeholders{$key}
}

method set_placeholders (@placeholders) {
  foreach my $placeholder (@placeholders) {
    $self->placeholder(%$placeholder)
  }
}

method maybe_ajax (@headers) {
  $self->is_xhr
    || $self->env->{HTTP_ACCEPT} =~ /application\/json/
    || any { $self->header($_) } (@ajax_headers_state, @ajax_headers, @headers)
}

method is_xhr {
  ($self->header('X-Requested-With') // '') =~ /^XMLHttpRequest$/i;
}

method is_websocket {
  ...
}

1