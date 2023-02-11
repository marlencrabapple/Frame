use Object::Pad;

package Frame::Request;
class Frame::Request :isa(Plack::Request) :does(Frame::Base);

use utf8;
use v5.36;

# use Plack::Request;
use List::Util 'any';

state @ajax_headers_default = ('X-Robo-Req');

field @ajax_headers :reader;
# field $req :reader;
field $placeholders :reader;
field @placeholders_ord :reader;
field @placeholder_values_ord :reader;
field $stash :reader;

method BUILDARGS :common (%args) {
  (delete $args{env}, 1, %args)
}

ADJUSTPARAMS ($params) {
  $stash = {};
  @ajax_headers = $$params{ajax_headers}->@* if ref $$params{ajax_headers} eq 'ARRAY';
}

# method AUTOLOAD {
#   (my $sub = our $AUTOLOAD) =~ s/.*:://;
#   return if $sub eq 'DESTROY';
#   $req->$sub(@_)
# }

# method refresh ($env = undef) {
#   $req = undef;
#   $stash = {};
#   $placeholders = {};
#   @placeholders_ord = ();
#   @placeholder_values_ord = ();

#   return unless $env;

#   $req = Plack::Request->new($env);
#   $req->new_response
# }

method placeholder ($key, $value = undef) {
  if(defined $value && !$$placeholders{$key}) {
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

method is_ajax { $self->header($ajax_headers_default[0]) ? 1 : 0 }

method maybe_ajax (@headers) {
  $self->is_xhr
    || $self->env->{HTTP_ACCEPT} =~ /application\/json/
    || any { $self->header($_) } (@ajax_headers_default, @ajax_headers, @headers)
}

method is_xhr { ($self->header('X-Requested-With') // '') =~ /^XMLHttpRequest$/i }

method is_websocket {
  ...
}

1