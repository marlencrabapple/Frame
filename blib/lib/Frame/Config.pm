use Object::Pad;

package Frame::Config;
# role Frame::Config;
class Frame::Config :does(Frame::Base);

use utf8;
use v5.36;

use Carp;
use Struct::Dumb;
use Scalar::Util 'blessed';

struct Prev => [qw/Ref Field/];
struct Curr => [qw/Struct Field/];

field $config_struct :reader(config);
field $config :param;
# field $level;
field $curr;
field $prev;
# field $val;

ADJUST {
  struct Config => [keys %$config];
  $config_struct = Config(values %$config);
  $self->structify($config)
}

method structify ($ref) {
  if (ref $ref eq 'ARRAY') {
    $curr = $ref;
    $self->aref2struct($ref)
  }
  elsif (ref $ref eq 'HASH') {
    $curr = $ref;
    $self->href2struct($ref)
  }
  elsif ((!(ref($ref) || blessed $ref)) && $curr) {
    # ($curr->Struct)->($curr->Field) = $ref;
    my $st = $curr->Struct;
    my $field = $curr->Field;
    $st->$field = $ref;
    return
  }
}

method href2struct ($href) {
  foreach my $key (keys %$href) {
    $self->structify($$href{$key})
  }
}

method aref2struct ($aref) {
  foreach my $item (@$aref) {
    $self->structify($item)
  }
}

# method $to_struct () {

# }

1