use Object::Pad qw/:experimental(mop)/;

package Frame::Base;
role Frame::Base;

use utf8;
use v5.36;

use Exporter;
use Time::Piece;
use Data::Dumper;
use Devel::StackTrace::WithLexicals;

use Frame::Base;

use subs qw(dmsg _dmsg);

our @EXPORT = qw(dmsg);

our $dev_mode = $ENV{'PLACK_ENV'} && $ENV{'PLACK_ENV'} eq 'development';
our $frame_debug = defined $ENV{'FRAME_DEBUG'};
our $AUTOLOAD;

field $app :mutator :weak;

# {
#   no strict 'refs';
#   no warnings 'redefine';

#   *{__PACKAGE__ . '::dmsg'} = sub (@msgs) {
#     our $dev_mode;
#     return undef unless $dev_mode;

#     my $caller = [caller];

#     my $out = "*** " . localtime->datetime . " - DEBUG MESSAGE ***\n\n";
#     { local $Data::Dumper::Pad = "  "; $out .= scalar @msgs > 1 ? Dumper(@msgs) . "\n": "  $msgs[0]\n\n"; }

#     $out .= $frame_debug ? join "\n", map { (my $line = $_) =~ s/^\t/  /; "  $line" } split /\R/, Devel::StackTrace::WithLexicals->new(
#       indent => 1,
#       skip_frames => 1
#     )->as_string : "at $$caller[1]:$$caller[2]";

#     say STDERR "$out\n";
#     $out
#   };
# }

# BEGIN {
#   no strict 'refs';
#   no warnings 'redefine';
#   *{__PACKAGE__ . '::dmsg'} = \&_dmsg;
# }

BUILD {
  {
    
    no strict 'refs';
    no warnings 'redefine';
    
    my $meta = Object::Pad::MOP::Class->for_class(__CLASS__);
    my @roles = $meta->all_roles;

    *{__CLASS__ . '::dmsg'} = \&_dmsg;
    *{[caller]->[0] . '::dmsg'} = \&_dmsg;

    foreach my $pkg ($meta, @roles) {
      dmsg $pkg->name;
      *{$pkg->name . "::dmsg"} = \&_dmsg
    }
  }

  use subs qw(dmsg _dmsg); # Vaguely (very) confused about what namespace this is running in

  Exporter::import __PACKAGE__;
  __CLASS__->import(__PACKAGE__)
}

ADJUSTPARAMS ($params) {
  $app //= $$params{app} if $$params{app}
}

method import :common {
  use Frame::Base;

  {
    no strict 'refs';
    no warnings 'redefine';
    
    my $meta = Object::Pad::MOP::Class->for_class($class);
    my @roles = $meta->all_roles;

    *{$class . '::dmsg'} = \&_dmsg;
    *{[caller]->[0] . '::dmsg'} = \&_dmsg;

    say *{$class . '::dmsg'};
    say *{[caller]->[0] . '::dmsg'};

    foreach my $pkg ($meta, @roles) {
      say *{$pkg->name . "::dmsg"};
      *{$pkg->name . "::dmsg"} = \&_dmsg
    }
  }

  Exporter::import __PACKAGE__
}

method dmsg :common (@msgs) { die "Its not good that you're here" }; # "Placeholder" method

sub _dmsg (@msgs) {
  our $dev_mode;
  return undef unless $dev_mode;

  my $caller = [caller];

  my $out = "*** " . localtime->datetime . " - DEBUG MESSAGE ***\n\n";
  { local $Data::Dumper::Pad = "  "; $out .= scalar @msgs > 1 ? Dumper(@msgs) . "\n": "  $msgs[0]\n\n"; }

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
  *{__PACKAGE__ . '::dmsg'} = \&_dmsg
}

1
