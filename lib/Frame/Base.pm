use Object::Pad qw/:experimental(mop)/;

package Frame::Base;
role Frame::Base;

use utf8;
use v5.36;

use parent 'Exporter';

use Time::Piece;
use Data::Dumper;
use Feature::Compat::Try;
use Syntax::Keyword::Dynamically;
use List::Util qw(any none uniq);
use Devel::StackTrace::WithLexicals;

our @EXPORT = qw(dmsg);
use subs qw(dmsg _dmsg);

BEGIN {
  use Frame::Base;

  use subs qw(dmsg _dmsg);
  our @EXPORT = qw(dmsg);

  # {
  #   no strict 'refs';
  #   no warnings 'redefine';
  #   *{__PACKAGE__ . '::dmsg'} = \&_dmsg
  # }

  unshift @INC, sub ($coderef, $filename) {
    BEGIN {
      use subs 'dmsg';
    }
    # say $filename;
    state @nsarr = qw(Frame);
    state $nspat = 'Frame';
    
    my $caller = [caller];

    #if($$caller[0] =~ /^Frame((\/.+)?\.pm|::.+)?$/) {
    if($$caller[0] =~ /^($nspat)(::.+)?$/ || $filename =~ /^($nspat)(\/.+)?\.pm$/) {
      if($$caller[0] !~ /^Frame/) {
        my ($tlns) = ($$caller[0] =~ /^([^:]+)(::.+)?$/);
        @nsarr = uniq(@nsarr, $tlns);
        $nspat = join '|', @nsarr
      }

      my @pkgs;
      my $meta = Object::Pad::MOP::Class->for_class($$caller[0]);
      push @pkgs, $meta;
 
      no strict 'refs';
      no warnings 'redefine';

      # TODO: Check if is Object::Pad class
      *{$$caller[0] . '::dmsg'} = \&_dmsg;# if $meta->is_role;
      # "$$caller[0]::import"->(__PACKAGE__);

      if($filename =~ /^($nspat).*/) {
        $filename =~ s/\//::/g;
        $filename = substr $filename, 0, -3;
        #say *{$filename . '::dmsg'};

        *{$filename . '::dmsg'} = \&_dmsg;

        my @INC_ = @INC;
        #say Dumper @INC_[1, -1];
        say $INC[0], __LINE__;

        try {
          local @INC = @INC_[1 .. (scalar @INC_ - 1)];
          say $INC[0], __LINE__;
          #say Dumper \@INC;
          eval "require $filename";
          say $@;
          my $meta = Object::Pad::MOP::Class->for_class($filename);
          push @pkgs, $meta
        }
        catch ($e) {
          warn $e
        }

        # if $meta->is_role;
        # "$filename\::import"->(__PACKAGE__);

        # &{"$filename\::dmsg"}
      }

      foreach my $pkg (@pkgs) {
        foreach my $role ($pkg->all_roles) {
          *{$role->name . '::dmsg'} = \&_dmsg;
          ($pkg->name . "::import")->(__PACKAGE__);
          # say *{$role->name . '::dmsg'}
        }
      }

      Exporter::import __PACKAGE__;

      # {
      #   eval "package $$caller[0]; use subs 'dmsg'; use Frame::Base;";
      #   use Frame::Base;
      #   say __PACKAGE__;
      #   use subs 'dmsg'
      # }

      # say Dumper $filename, \@nsarr, $nspat, $$caller[0];
      # say *{$$caller[0] . '::dmsg'}
    }

    return undef
  }
}

our $dev_mode = $ENV{'PLACK_ENV'} && $ENV{'PLACK_ENV'} eq 'development';
our $frame_debug = defined $ENV{'FRAME_DEBUG'};

# our $AUTOLOAD;

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
      # dmsg $pkg->name;
      *{$pkg->name . "::dmsg"} = \&_dmsg
    }
  }

  use subs qw(dmsg _dmsg); # Vaguely (very) confused about what namespace this is running in

  Exporter::import __PACKAGE__;
  __CLASS__->import(__PACKAGE__);
  # Exporter::export_to_level(1, @_)
}

ADJUSTPARAMS ($params) {
  $app //= $$params{app} if $$params{app}
}

method import :common {
  {
    no strict 'refs';
    no warnings 'redefine';
    
    my $meta = Object::Pad::MOP::Class->for_class($class);
    my @roles = $meta->all_roles;

    *{$class . '::dmsg'} = \&_dmsg;
    *{[caller]->[0] . '::dmsg'} = \&_dmsg;

    #say *{$class . '::dmsg'};
    #say *{[caller]->[0] . '::dmsg'};

    foreach my $pkg ($meta, @roles) {
      #say *{$pkg->name . "::dmsg"};
      *{$pkg->name . "::dmsg"} = \&_dmsg
    }
  }

  Exporter::import __PACKAGE__;
  # Exporter::export_to_level(1, @_)
}


# method dmsg :common :override (@msgs) { die "Its not good that you're here" }; # "Placeholder" method
# method dmsg :common;

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

# {
#   no strict 'refs';
#   no warnings 'redefine';
#   *{__PACKAGE__ . '::dmsg'} = \&_dmsg
# }

1
