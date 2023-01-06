use Object::Pad;

package Frame::Routes::Map;
role Frame::Routes::Map;

use utf8;
use v5.36;
use autodie;

use Data::Dumper;
use List::AllUtils;
use Scalar::Util 'blessed';

# ...and I'm just gonna take notes for another idea here:
# - Add route key to $patterns hash field in Frame::Routes

1