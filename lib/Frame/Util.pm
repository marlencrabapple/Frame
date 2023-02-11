use Object::Pad;

package Frame::Util;
role Frame::Util;

use utf8;
use v5.36;

use Time::Piece;
use Data::Dumper;
use Exporter 'import';
use Devel::StackTrace::WithLexicals;

use subs 'dmsg _dmsg';

$Data::Dumper::Pad = "  ";

our @EXPORT = qw(dmsg _dmsg);

our $dev_mode = $ENV{'PLACK_ENV'} && $ENV{'PLACK_ENV'} eq 'development';
our $frame_debug = defined $ENV{'FRAME_DEBUG'};

# Most of this stuff is hacks to avoid explicitly writing `use Frame::Util` since
# its already composed with :does(...). In the future syntax could look as follows:
#
#   use Object::Pad;
#
#   package Foo::Bar;
#   role Foo::Bar :does(Frame::Base); # Frame::Base does everything but type the :export attr
#
#   # TODO: Figure out how to make composing Frame::Base auto-enable these
#   use utf8;
#   use v5.36;

#   method baz :export ($asdf) {
#     say "$caller says: $asdf" # $caller as scalar is [caller]->[0]
#                               # $caller[/^[0-9]+$/] is as expected
#                               # $caller->class and $caller->sub are also available
#   }
#
#   1
#
# Not entirely sure this is a good idea yet...

method BUILARGS {
  import __PACKAGE__;
  say Dumper([caller]->[0]);
}

{
  say Dumper([caller]->[0]);
}

BUILD {
  import __PACKAGE__;
  our @ISA;
  # say "BUILD: " . Dumper(__CLASS__, [caller]->[0])
}

ADJUST {{ # TODO: Check if this scoping works like it looks
  # say Dumper(__CLASS__, [caller]->[0]);
  no strict 'refs';
  no warnings 'redefine';
  *{__CLASS__ . '::dmsg'} = \&_dmsg;
  *{[caller]->[0] . '::dmsg'} = \&_dmsg;
  import __PACKAGE__
}}

method AUTOLOAD :common {
  (my $sub = our $AUTOLOAD) =~ s/.*:://;
  return if $sub eq 'DESTROY';
  $sub eq 'dmsg' ? _dmsg(@_) : die
}

method dmsg :common (@msgs) { die "Its not good that you're here" }; # "Placeholder" method

sub _dmsg (@msgs) {
  our $dev_mode;
  return undef unless $dev_mode;

  my $caller = [caller];

  my $out = "*** " . localtime->datetime . " - DEBUG MESSAGE ***\n\n";
  $out .= scalar @msgs > 1 ? Dumper(@msgs) . "\n": "  $msgs[0]\n\n";

  $out .= $frame_debug ? join "\n", map { (my $line = $_) =~ s/^\t/  /; "  $line" } split /\R/, Devel::StackTrace::WithLexicals->new(
    indent => 1,
    skip_frames => 1
  )->as_string : "at $$caller[1]:$$caller[2]";

  say STDERR "$out\n";
  $out
}

{
  no strict 'refs';
  no warnings 'redefine';

  *{__CLASS__ . '::dmsg'} = \&_dmsg;
  *{__PACKAGE__ . '::dmsg'} = \&_dmsg;
  *{[caller]->[0] . '::dmsg'} = \&_dmsg
}

1
