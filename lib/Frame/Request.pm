use Object::Pad;

package Frame::Request;
class Frame::Request :isa(Plack::Request) :does(Frame::Base);

use utf8;
use v5.36;
use autodie;

use Data::Dumper;

# field $env :param;
# field $app :param;
field @placeholders_ord :reader;
field $placeholders :reader;
field @placeholder_values_ord :reader;

# sub BUILDARGS {
#   my ($class, $env) = @_;
#   $class->SUPER::new($env)
# }

method placeholder ($key, $value = undef) {
  if($value && !$$placeholders{$key}) {
    push @placeholders_ord, { $key => $value };
    push @placeholder_values_ord, $value;
    #$$placeholders{$key} = $placeholders_ord[-1]
    $$placeholders{$key} = $value
  }

  $$placeholders{$key}
}

method set_placeholders (@placeholders) {
  foreach my $placeholder (@placeholders) {
    say Dumper($placeholder);
    $self->placeholder(%$placeholder)
  }
}

1