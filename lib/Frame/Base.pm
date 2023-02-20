use Object::Pad;

package Frame::Base;
role Frame::Base;

use utf8;
use v5.36;

use parent 'Exporter';

use Time::Piece;
use Data::Dumper;
use List::Util 'uniq';
use Devel::StackTrace::WithLexicals;

use subs qw(dmsg import_on_compose);

our @EXPORT = qw(dmsg);

our $dev_mode = $ENV{'PLACK_ENV'} && $ENV{'PLACK_ENV'} eq 'development';
our $frame_debug = defined $ENV{'FRAME_DEBUG'};

$^H{__PACKAGE__ . '/user'} = 1;

field $app :weak :param :mutator = undef;

ADJUSTPARAMS ($params) {
  $app //= $$params{app} if $$params{app}
}

sub dmsg (@msgs) {
  our $dev_mode;
  return undef unless $dev_mode;

  my @caller = caller 0;

  my $out = "*** " . localtime->datetime . " - DEBUG MESSAGE ***\n\n";
  
  {
    local $Data::Dumper::Pad = "  ";
    $out .= scalar @msgs > 1 ? Dumper(@msgs) : ref $msgs[0] ? Dumper(@msgs) : "  $msgs[0]\n";
    $out .= "\n"
  }

  $out .= $frame_debug ? join "\n", map { (my $line = $_) =~ s/^\t/  /; "  $line" } split /\R/, Devel::StackTrace::WithLexicals->new(
    indent => 1,
    skip_frames => 1
  )->as_string : "at $caller[1]:$caller[2]";

  say STDERR "$out\n";
  $out
}

method import_on_compose :common {
  sub {
    my $exports = sub ($sub, @vars) {
      no strict 'refs';
      foreach my $export (@{"$class\::EXPORT"}) {
        return 0 unless $sub->($export, @vars)
      }
      1
    };

    unshift @INC, sub ($coderef, $filename) {
      state @nsarr = qw(Frame);
      state $nspat = 'Frame';
      state %seen;

      my @caller = caller 0;

      return undef if $seen{$caller[0]}
        || $seen{$filename}
        || $exports->(sub { $caller[0]->can($_[0]) });

      if($caller[0] =~ /^($nspat)(::.+)?$/
        || $filename =~ /^($nspat)(\/.+)?\.pm$/
        || $caller[10] && $caller[10]->{__PACKAGE__ . '/user'})
      {
        $seen{$caller[0]} //= 0;
        $seen{$caller[0]}++;

        $exports->(sub {
          {
            no strict 'refs';
            no warnings 'redefine';
            *{"$caller[0]\::$_[0]"} = \&{"$_[0]"};
            warn *{"$caller[0]\::$_[0]"} if $ENV{FRAME_DEBUG}
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
              *{"$filename\::$_[0]"} = \&{"$_[0]"};
              warn *{"$filename\::$_[0]"} if $ENV{FRAME_DEBUG}
            }
          }, $filename, __LINE__)
        }

        my $i = 1;
        while(my @caller = caller $i) {
          $seen{$caller[0]} //= 0;
          next if $seen{$caller[0]} || $caller[0] eq 'main';
          $seen{$caller[0]}++;

          # warn 'asdf', $caller[0];

          if(($caller[0] =~ /^($nspat)(::.+)?$/)
            || ($caller[6] && $caller[6] =~ /^($nspat).pm$/)
            || { eval "no strict 'refs'; %{[caller $i]->[0] . '::'}" }->{dmsg})
          {
            next if $caller[0] =~ /^Plack/;

            $exports->(sub {
              {
                no strict 'refs';
                no warnings 'redefine';
                *{"$caller[0]\::$_[0]"} = \&{"$_[0]"};
                warn *{"$caller[0]\::$_[0]"} if $ENV{FRAME_DEBUG}
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
