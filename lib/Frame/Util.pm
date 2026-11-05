use Object::Pad ':experimental(:all)';

package Frame::Util;
role Frame::Util : does(Frame::Base);

use utf8;
use v5.40;

use subs qw'ua_list ua_active';

use IO::Async;
use Const::Fast;
use Net::Async::HTTP;

# field $_ua = {};

method slugify : common ($text) {
    $text =~ s/[^a-zA-Z0-9]+/-/g;
    $text =~ s/^-+|-+$//g;
    $text =~ tr/A-Z/a-z/;
    $text;
}

# method ua_notifier (%key) {
#     scalar keys %key ? $_ua->%{%key} : %$_ua;
# }

# *ua_list   = \&ua_notifier;
# *ua_active = \&ua_notifier;

# method ua (@opt) {
#     state $ua;
#     state $ua_opt //= \@opt;

#     const my @ua_default => ();

#     if ( !$ua || scalar @opt ) {
#         if ( $opt[0] eq undef && scalar @opt == 1 ) {
#             $self->loop->remove($ua);
#             delete $$_ua{$ua};
#         }

#         $ua = Net::Async::HTTP->new( @ua_default, @opt );
#         $self->loop->add($ua);
#         $$_ua{$ua} = $ua;
#     }
# }
