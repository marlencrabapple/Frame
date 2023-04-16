# BEGIN {
#   $ENV{FRAME_DEBUG} = 1
# }

BEGIN {
  $^H{__PACKAGE__ . '/user'} = 1;
}

use Object::Pad;

package Frame::Base;
role Frame::Base;

use utf8;
use v5.36;

use parent 'Exporter';

use Devel::StackTrace::WithLexicals;
use PadWalker qw(peek_my peek_our);
use Feature::Compat::Try;
use List::Util 'uniq';
use JSON::MaybeXS;
use Data::Dumper;
use Time::Piece;

use subs qw(dmsg json);

our @EXPORT = qw(dmsg json);

our $dev_mode = $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development';
our $frame_debug = $ENV{FRAME_DEBUG};
our $json_default = JSON::MaybeXS->new(utf8 => 1, $dev_mode ? (pretty => 1) : ());

$^H{__PACKAGE__ . '/user'} = 1;

field $app :weak :param :accessor = undef;
field $json :accessor(_json);

ADJUSTPARAMS ($params) {
  # $app //= $$params{app} if $$params{app};
  $json //= JSON::MaybeXS->new(utf8 => 1, $dev_mode ? (pretty => 1) : ());
  $^H{__CLASS__ . '/user'} = 1
}

sub json ($self = undef) {
  $self ? $self->_json : $json_default
}

sub dmsg (@msgs) {
  # our $dev_mode;
  return '' unless $dev_mode;

  my @caller = caller 0;

  my $out = "*** " . localtime->datetime . " - DEBUG MESSAGE ***\n\n";
  
  {
    local $Data::Dumper::Pad = "  ";
    $out .= scalar @msgs > 1 ? Dumper(@msgs) : ref $msgs[0] ? Dumper(@msgs) : "  $msgs[0]\n";
    $out .= "\n"
  }

  $out .= $frame_debug == 2 ? join "\n", map { (my $line = $_) =~ s/^\t/  /; "  $line" } split /\R/, Devel::StackTrace::WithLexicals->new(
    indent => 1,
    skip_frames => 1
  )->as_string : "at $caller[1]:$caller[2]";

  say STDERR "$out\n";
  $out
}

method import_on_compose :common {
  state @nsarr = qw(Frame);
  state $nspat = 'Frame';

  # This doesn't work and the solution is to basically do this all at once
  # Its unclear when each anon sub is being run/where it is in @INC
  return sub {
    my $exports = sub ($sub, @vars) {
      no strict 'refs';
      
      # local $Data::Dumper::Indent = 0;
      
      foreach my $export (${"$class\::"}{EXPORT}->@*) {
        # warn $export;
        return 0 unless $sub->($export, @vars)
      }
      1
    };

    unshift @INC, sub ($coderef, $filename) {
      state %seen;

      my @caller = caller 0;

      # local $Data::Dumper::Indent = 0;
      # warn Dumper $class, $nspat, \%seen unless $class eq 'Frame::Base';
      
      # {
      #   no strict 'refs';

      #   state $ii = 0;
      #   my $i = 0;

      #   while(my @caller = caller $i) {
      #       local $Data::Dumper::Indent = 0;
      #       # warn "$ii-$i: ", Dumper $class, $filename, \@caller, \%{"$caller[0]\::"}, peek_my($i), peek_our($i);

      #       try {
      #         warn "$ii-$i: ", Dumper $class, $filename, \@caller, \%{"$caller[0]\::"}, keys %{peek_my($i)}, keys %{peek_our($i)}
      #       }
      #       catch ($e) {
      #       }
      #     # try {
      #     #   local $Data::Dumper::Indent = 0;
      #     #   warn "$ii-$i: ", Dumper $class, $filename, \@caller, \%{"$caller[0]\::"}, peek_my($i), peek_our($i);
      #     # }
      #     # catch ($e) {
      #     #   local $Data::Dumper::Indent = 0;
      #     #   # warn "$ii-$i: ", Dumper $class, $filename, \@caller, \${"$caller[0]\::"}, $e;
      #     # }
      #   }
      #   continue {
      #     $i++
      #   }

      #   $ii++
      # }

      return undef if $seen{$caller[0]}
        || $seen{$filename}
        || $exports->(sub { $caller[0]->can($_[0]) });

      if($caller[0] =~ /^($nspat)(::.+)?$/
        || $filename =~ /^($nspat)(\/.+)?\.pm$/
        || $caller[10] && $caller[10]->{$class . '/user'})
      {
        $seen{$caller[0]} //= 0;
        $seen{$caller[0]}++;

        $exports->(sub {
          {
            no strict 'refs';
            no warnings 'redefine';
            *{"$caller[0]\::$_[0]"} = \&{"$class\::$_[0]"};
            # warn *{"$caller[0]\::$_[0]"} if $frame_debug
          }
        }, \@caller, __LINE__);

        if($caller[0] !~ /^$nspat|Plack/) {
          my ($tlns) = ($caller[0] =~ /^([^:]+)(::.+)?$/);
          @nsarr = uniq(@nsarr, $tlns);
          $nspat = join '|', @nsarr
        }

        if($filename =~ /^($nspat).*/) {
          $seen{$filename} //= 0;
          $seen{$filename}++;

          $filename =~ s/\//::/g;
          $filename = substr $filename, 0, -3;

          $exports->(sub {
            {
              no strict 'refs';
              no warnings 'redefine';
              *{"$filename\::$_[0]"} = \&{"$class\::$_[0]"};
              # warn *{"$filename\::$_[0]"} if $frame_debug
            }
          }, $filename, __LINE__)
        }

        my $i = 1;
        while(my @caller = caller $i) {
          $seen{$caller[0]} //= 0;
          next if $seen{$caller[0]} || $caller[0] eq 'main';
          $seen{$caller[0]}++;

          if(($caller[0] =~ /^($nspat)(::.+)?$/)
            || ($caller[6] && $caller[6] =~ /^($nspat).pm$/)
            || ($caller[10] && $caller[10]->{$class . '/user'})
            || { eval "no strict 'refs'; %{[caller $i]->[0] . '::'}" }->{dmsg})
          {
            next if $caller[0] =~ /^Plack/;

            $exports->(sub {
              {
                no strict 'refs';
                no warnings 'redefine';
                *{"$caller[0]\::$_[0]"} = \&{"$class\::$_[0]"};
                # warn *{"$caller[0]\::$_[0]"} if $frame_debug
              }
            }, \@caller, $nspat);

            if($caller[0] !~ /^$nspat/) {
              my ($tlns) = ($caller[0] =~ /^([^:]+)(::.+)?$/);
              @nsarr = uniq(@nsarr, $tlns);
              $nspat = join '|', @nsarr
            }
          }
        }
        continue { $i++ }
      }

      undef
    }
  }
}

method import :common {
  Exporter::import $class
}

BEGIN {
  __PACKAGE__->import_on_compose()->()
}

1
