use Object::Pad;

package Frame::Request;

use v5.36;
use utf8;
use autodie;

use Plack::Request;

use Data::Dumper;

class Frame::Request :isa(Plack::Request) {
  field @placeholders_ord :reader;
  field $placeholders :reader;
  field @placeholder_values_ord :reader;
  
  method placeholder ($key, $value = undef) {
    if($value && !$$placeholders{$key}) {
      push @placeholders_ord, { $key => $value };
      push @placeholder_values_ord, $value;
      $$placeholders{$key} = $placeholders_ord[-1]
    }

    $$placeholders{$key}
  }
}