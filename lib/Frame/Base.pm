# BEGIN {
#   $ENV{FRAME_DEBUG} = 1
# }

use Object::Pad;

package Frame::Base;
role Frame::Base;

BEGIN {
  $^H{__PACKAGE__ . '/user'} = 1;
}

use utf8;
use v5.36;

use parent 'Exporter';

use Devel::StackTrace::WithLexicals;
use PadWalker qw(peek_my peek_our);
use Feature::Compat::Try;
use List::AllUtils qw(singleton any);
use JSON::MaybeXS;
use Data::Dumper;
use Time::Piece;
use Plack::Util;

our @EXPORT = qw(dmsg json);
our $prefix = '';
our $dev_mode = $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development';
our $frame_debug = $ENV{FRAME_DEBUG} // 0;
our $json_default = JSON::MaybeXS->new(utf8 => 1, $dev_mode ? (pretty => 1) : ());

$^H{__PACKAGE__ . '/user'} //= 1;

field $app :weak :param :accessor = undef;
# field $json :accessor(_json);

ADJUSTPARAMS ($params) {
  # $app //= $$params{app} if $$params{app};
  # $json //= JSON::MaybeXS->new(utf8 => 1, $dev_mode ? (pretty => 1) : ());

  # Exporter::import(__CLASS__);

  # $^H{__CLASS__ . '/user'} = 1
}

sub json ($self = undef) {
  # $self ? $self->_json : $json_default
  $json_default
}

sub dmsg ($class, @msgs) {
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

method exports :common ($cb, @vars) {
  no strict 'refs';

  foreach my $export (${"$class\::"}{EXPORT}->@*) {
    my $sub = defined *{"$class\::_$prefix\_$export"}
      && ref \&{"$class\::_$prefix\_$export"} eq 'CODE'
        ? "_$prefix\_$export"
        : $export;

    return 0 unless $cb->($export, $sub, @vars)
  }

  1
}

# method import :common {
#   # my $caller = [caller 0];

#   # say $$caller[0];
#   # say $class, "\n";
#   # {
#   #   no strict 'refs';
#   #   no warnings 'redefine';

#   #   exports($class, sub ($export, $realsub, @vars) {
#   #     # *{"$class\::$export"} = \&{"$class\::$realsub"}; 1
#   #     *{"$$caller[0]\::$export"} = sub { $class->$realsub(@_) }
#   #       unless $$caller[0]->can($export);
#   #     1
#   #   });
#   # }

#   Exporter::import $class
# }

# method import_on_compose :common {
#   my @og_INC = @INC;
#   my $import_on_compose = sub ($coderef, $filename) {
#     local @INC = @og_INC;
#     my $res = do "$filename";
#     die Dumper($res, $!, $@) unless $res;
#     undef
#   };

#   unshift @INC, $import_on_compose
# }

method import_on_compose :common {
  my @og_INC = @INC;

  my $import_on_compose = sub ($coderef, $filename, $i = -1) {
    state $seen_users = {};
    state @seen;
    state @prev;
    my $prev_filename = shift @prev;
    my @curr = ($filename);
    my $fh;

    # unless($INC{$filename}) {
    #   {
    #     local @INC = @og_INC;
    #     my $res = eval { do($filename) };
    #     die Dumper($res, $!, $@) unless $res;
    #     open($fh, "<", $INC{$filename}) or die "Can't open < input.txt: $!";
    #     # return $fh
    #   }
    # }

    # open($fh, "<", $INC{$filename}) or die "Can't open < input.txt: $!"
    #   if $INC{$filename};

    # say Dumper($filename);

    # do{{
      
      
    #   package Asdf; local @INC = @og_INC; no warnings 'redefine'; require "$filename"
      
    # }};

    {
      no strict 'refs';
      no warnings 'redefine';

      while (my $caller = shift(@prev) || [caller $i]) {
        last unless scalar @$caller;

        # next if any { 0 == scalar singleton @$_, @$caller[0..9] } @seen;

        # if($i >= 0) {
        #   push @{"$$caller[0]\::BEGIN"}, sub {
        #     use Data::Dumper;
        #     CORE::say Dumper(\%^H);
        #   }
        # }

        # if ($i >= 0) {
        #   push @curr, $caller
        # }
        # elsif(1 == scalar (@prev)) {
        #   # push @seen, [@$caller[0..9]]
        # }

        # if($i >= 0) {
        #   try {
        #     Plack::Util::load_class($$caller[0]) unless $$caller[0] eq 'main';
        #     $caller = [caller $i];
        #     say Dumper($caller, \%{"$$caller[0]::"}) if $$caller[0] =~ /Momiji/;
        #   }
        #   catch ($e) {

        #   }
        # }

        $i >= 0 ? push @curr, $caller : push @seen, [@$caller[0..9]];

        if (${"$$caller[0]\::"}{META}) { # && $$caller[0] ne 'main') {
          my $meta = ${"$$caller[0]\::"}{META}->();

          foreach my $pkg (($meta->all_roles), ($meta->superclasses)) {
            $caller->[10]{"$class/user"} = 1
              if any { $pkg->name eq $_ } ($class, keys $$seen_users{pkg}->%*)
          }
        }

        if (defined ${"$$caller[0]\::"}{import_on_compose}
          || $caller->[10]{"$class/user"}
          || ($$caller[7] && $seen_users->{fn}{$$caller[6]})
          # || $$caller[3] ...
          || ($$caller[0] ne 'main' && any { $_ =~ /$class/ } [%{"$$caller[0]\::"}]->@*)
          # || ($$caller[0] ne 'main' && any { $class->exports(sub ($s) { $_ eq "*$$caller[0]::$s" }) } [%{"$$caller[0]\::"}]->@*)
        ) {
          $class->exports(sub ($export, $realsub, @vars) {
            # warn *{"$$caller[0]\::$export"} unless $$caller[0]->can($export);
            return 1 if $$caller[0]->can($export);

            $seen_users->{pkg}{$$caller[0]} = 1;
            $seen_users->{fn}{$$caller[1]} = 1;
            
            *{"$$caller[0]\::$export"} = sub { $class->$realsub(@_) };
            $caller->[10]{"$class/user"} = 1;

            1
          });
        }
      }
      continue { $i++ unless scalar @prev }
    }

    push @prev, @curr;

    # say Dumper($INC{$filename});
    # say Dumper \%INC;

    # undef

    # \qq{
    #   BEGIN {
    #     require $filename;
    #     CORE::say 'hi';
    #   };
    #   1
    # }

    undef
  };

  $import_on_compose->($import_on_compose, __FILE__, 0);

  # say Dumper \%INC;

  unshift @INC, $import_on_compose
}

BEGIN {
  __PACKAGE__->import_on_compose
}

# method import_on_compose :common {
#   state @nsarr = qw(Frame);
#   state $nspat = 'Frame';

#   # This doesn't work and the solution is to basically do this all at once
#   # Its unclear when each anon sub is being run/where it is in @INC
#   return sub {
#     my $exports = sub ($sub, @vars) {
#       no strict 'refs';
      
#       # local $Data::Dumper::Indent = 0;
      
#       foreach my $export (${"$class\::"}{EXPORT}->@*) {
#         # warn $export;
#         return 0 unless $sub->($export, @vars)
#       }
#       1
#     };

#     unshift @INC, sub ($coderef, $filename) {
#       state %seen;

#       my @caller = caller 0;

#       # local $Data::Dumper::Indent = 0;
#       # warn Dumper $class, $nspat, \%seen unless $class eq 'Frame::Base';
      
#       # {
#       #   no strict 'refs';

#       #   state $ii = 0;
#       #   my $i = 0;

#       #   while(my @caller = caller $i) {
#       #       local $Data::Dumper::Indent = 0;
#       #       # warn "$ii-$i: ", Dumper $class, $filename, \@caller, \%{"$caller[0]\::"}, peek_my($i), peek_our($i);

#       #       try {
#       #         warn "$ii-$i: ", Dumper $class, $filename, \@caller, \%{"$caller[0]\::"}, keys %{peek_my($i)}, keys %{peek_our($i)}
#       #       }
#       #       catch ($e) {
#       #       }
#       #     # try {
#       #     #   local $Data::Dumper::Indent = 0;
#       #     #   warn "$ii-$i: ", Dumper $class, $filename, \@caller, \%{"$caller[0]\::"}, peek_my($i), peek_our($i);
#       #     # }
#       #     # catch ($e) {
#       #     #   local $Data::Dumper::Indent = 0;
#       #     #   # warn "$ii-$i: ", Dumper $class, $filename, \@caller, \${"$caller[0]\::"}, $e;
#       #     # }
#       #   }
#       #   continue {
#       #     $i++
#       #   }

#       #   $ii++
#       # }

#       return undef if $seen{$caller[0]}
#         || $seen{$filename}
#         || $exports->(sub { $caller[0]->can($_[0]) });

#       if($caller[0] =~ /^($nspat)(::.+)?$/
#         || $filename =~ /^($nspat)(\/.+)?\.pm$/
#         || $caller[10] && $caller[10]->{$class . '/user'})
#       {
#         $seen{$caller[0]} //= 0;
#         $seen{$caller[0]}++;

#         $exports->(sub {
#           {
#             no strict 'refs';
#             no warnings 'redefine';
#             my $sub = "$_[0]";
#             #*{"$caller[0]\::$_[0]"} = \&{"$class\::$_[0]"};
#             # *{"$caller[0]\::$_[0]"} = sub { &{"$class\::$_[0]"}($class, @_) };
#             *{"$caller[0]\::$_[0]"} = sub { $class->$sub(@_) };
#             # warn *{"$caller[0]\::$_[0]"} if $frame_debug
#           }
#         }, \@caller, __LINE__);

#         if($caller[0] !~ /^$nspat|Plack/) {
#           my ($tlns) = ($caller[0] =~ /^([^:]+)(::.+)?$/);
#           @nsarr = uniq(@nsarr, $tlns);
#           $nspat = join '|', @nsarr
#         }

#         if($filename =~ /^($nspat).*/) {
#           $seen{$filename} //= 0;
#           $seen{$filename}++;

#           $filename =~ s/\//::/g;
#           $filename = substr $filename, 0, -3;

#           $exports->(sub {
#             {
#               no strict 'refs';
#               no warnings 'redefine';
#               my $sub = $_[0];
#               # *{"$filename\::$_[0]"} = \&{"$class\::$_[0]"};
#               *{"$caller[0]\::$_[0]"} = sub { $class->$sub->(@_) };
#               # warn *{"$filename\::$_[0]"} if $frame_debug
#             }
#           }, $filename, __LINE__)
#         }

#         my $i = 1;
#         while(my @caller = caller $i) {
#           $seen{$caller[0]} //= 0;
#           next if $seen{$caller[0]} || $caller[0] eq 'main';
#           $seen{$caller[0]}++;

#           if(($caller[0] =~ /^($nspat)(::.+)?$/)
#             || ($caller[6] && $caller[6] =~ /^($nspat).pm$/)
#             || ($caller[10] && $caller[10]->{$class . '/user'})
#             || { eval "no strict 'refs'; %{[caller $i]->[0] . '::'}" }->{dmsg})
#           {
#             next if $caller[0] =~ /^Plack/;

#             $exports->(sub {
#               {
#                 no strict 'refs';
#                 no warnings 'redefine';
#                 my $sub = $_[0];
#                 # *{"$caller[0]\::$_[0]"} = \&{"$class\::$_[0]"};
#                 *{"$caller[0]\::$_[0]"} = sub { $class->$sub->(@_) };
#                 # warn *{"$caller[0]\::$_[0]"} if $frame_debug
#               }
#             }, \@caller, $nspat);

#             if($caller[0] !~ /^$nspat/) {
#               my ($tlns) = ($caller[0] =~ /^([^:]+)(::.+)?$/);
#               @nsarr = uniq(@nsarr, $tlns);
#               $nspat = join '|', @nsarr
#             }
#           }
#         }
#         continue { $i++ }
#       }

#       undef
#     }
#   }
# }

# method import :common {
#   Exporter::import $class
# }

# BEGIN {
#   __PACKAGE__->import_on_compose()->()
# }

1
