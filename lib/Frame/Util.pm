use Object::Pad ':experimental(:all)';

package Frame::Util;
role Frame::Util : does(Frame::Base);

use utf8;
use v5.40;

method slugify : common ($text) {
    $text =~ s/[^a-zA-Z0-9]+/-/g;
    $text =~ s/^-+|-+$//g;
    $text =~ tr/A-Z/a-z/;
    $text;
}
