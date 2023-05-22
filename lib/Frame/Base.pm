# BEGIN {
#   $ENV{FRAME_DEBUG} = 1
# }

use Object::Pad ':experimental(mop)';

package Frame::Base;
role Frame::Base;

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
use Module::Metadata;

our @EXPORT_DOES = qw(dmsg json __pkgfn__);
our $prefix = '';
our $dev_mode = $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development';
our $frame_debug = $ENV{FRAME_DEBUG} // 0;
our $json_default = JSON::MaybeXS->new(utf8 => 1, $dev_mode ? (pretty => 1) : ());
our %seen_users;

use subs @EXPORT_DOES;

$^H{__PACKAGE__ . '/user'} = 1;

# __PACKAGE__->import_on_compose;

field $app :weak :param :accessor = undef;
# field $json :accessor(_json);

ADJUSTPARAMS ($params) {
  # $app //= $$params{app} if $$params{app};
  # $json //= JSON::MaybeXS->new(utf8 => 1, $dev_mode ? (pretty => 1) : ());

  # Exporter::import(__CLASS__);

  $^H{__CLASS__ . '/user'} = 1
}

sub json ($self = undef) {
  # $self ? $self->_json : $json_default
  $json_default
}

method __pkgfn__ :common ($pkgname = undef) {
  $pkgname //= $class;
  "$pkgname.pm" =~ s/::/\//rg
}

method dmsg :common (@msgs) {
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

method monkey_patch :common ($package, $sub, %args) {
  {
    no strict 'refs';
    no warnings 'redefine';
    
    return -1 if ${"$package\::"}{$sub};# || $package->can($sub);

    if (ref $sub eq 'CODE') {
      return -1 unless $args{name};
      *{"$package\::$args{name}"} = $sub
    }
    else {
      *{"$package\::$sub"} = \&{$class . "::$sub"};
    }
  }

  $args{on_patch}($args{on_patch_args})
    if ref $args{on_patch} eq 'CODE';

  1
}

method exports :common ($cb, @vars) {
  foreach my $export (@EXPORT_DOES) {
    return 0 unless $cb->($export, $export, @vars)
  }

  1
}

method compose :common ($caller, %args) {
  no strict 'refs';
  # return unless ${"$$caller[0]\::"}{ISA};

  use utf8;
  use v5.36;

  $^H{__PACKAGE__ . '/user'} = 1;
  $caller->[10]{__PACKAGE__ . '/user'} = 1;

  __PACKAGE__->exports(sub ($export, $realsub, @vars) {
    $class->monkey_patch($$caller[0], $export)
  });

  # $seen_users{pkg}{$$caller[0]} = 1;
  # $seen_users{fn}{__pkgfn__($$caller[0])} = 1
}

method import :common  {
  my $caller = eval "[caller 1]";

  no strict 'refs';
  return unless ${"$$caller[0]\::"}{ISA};

  use utf8;
  use v5.36;

  $^H{__PACKAGE__ . '/user'} = 1;
  $$caller[10]{__PACKAGE__ . '/user'} = 1;

  {
    local $Data::Dumper::Indent = 0;
    # warn Dumper($caller, \%{"$$caller[0]\::"}) if $$caller[0] =~ /^(Frame|Momiji)/
    # warn Dumper($caller, [caller 0]) if $$caller[0] =~ /^(Frame|Momiji)/
  }

  __PACKAGE__->exports(sub ($export, $realsub, @vars) {
    $class->monkey_patch($$caller[0], $export)
  });

  $seen_users{pkg}{$$caller[0]} = 1;
  $seen_users{fn}{__pkgfn__($$caller[0])} = 1;
  
  __PACKAGE__->export_to_level(1, $class, @_)
}

method import_on_compose :common {
  state @og_INC = @INC;

  $class->exports(sub ($export, $realsub, @vars) {
    my $og_sub = \&{"$class\::$export"};
    $class->monkey_patch($class, sub {
      unshift @_, $class;
      goto $og_sub
    }, name => $export)
  });

  my $import_on_compose = sub ($coderef, $filename, $i = -1) {
    # state $seen_users = { pkg => { $class => 1 }, fn => { $filename => 1 } };
    state @seen;
    state @prev;

    my $prev_filename = (shift @prev // '');
    my @dout;

    my ($prev_pkgname, $pkgname) = map {
      join '::', ($_ =~ /([^\/]+)(?:\/|\.pm)/g);
    } ($prev_filename, $filename);

    if($prev_pkgname) {
      no strict 'refs';
      local $Data::Dumper::Indent = 0;
      # warn Dumper($prev_pkgname, \%{"$prev_pkgname\::"}) if $prev_pkgname =~ /^(Frame|Momiji)/
    }

    my @curr = ($filename);

    {
      no strict 'refs';
      no warnings 'redefine';

      while (my $caller = shift(@prev) || [caller $i]) {
        last unless scalar @$caller;
        # next if $$caller[0] eq 'main';
        # next if any { 0 == scalar singleton @$_, @$caller[0..9] } @seen;

        if ($i >= 0) {
          push @curr, $caller
        }
        # elsif (1 == scalar (@prev)) {
        else {
          # push @seen, [@$caller[0..9]]
        }

        {
          local $Data::Dumper::Indent = 0;
          # warn Dumper($caller, \%{"$$caller[0]\::"}) if $$caller[0] =~ /^(Frame|Momiji)/
        }

        if (${"$$caller[0]\::"}{META} && (my $meta = $$caller[0]->META())) {
          foreach my $pkg ($meta->all_roles, $meta->superclasses) {
            $$caller[10]{"$class/user"} = 1
              if any { $pkg->name eq $_ } ($class, keys $seen_users{pkg}->%*)
          }
        }

        if (defined ${"$$caller[0]\::"}{import_on_compose}
          || $$caller[0]->DOES($class)
          || $$caller[10]{"$class/user"}
          # || $$caller[3] ...
          || ($$caller[0] ne 'main' && any { $_ =~ /$class/ } [%{"$$caller[0]\::"}]->@*)
          # || ($$caller[0] ne 'main' && any { $class->exports(sub ($s) { $_ eq "*$$caller[0]::$s" }) } [%{"$$caller[0]\::"}]->@*)
        ) {
          # return unless ${"$$caller[0]\::"}{ISA};

          $seen_users{pkg}{$$caller[0]} = 1;
          $seen_users{fn}{__pkgfn__($$caller[0])} = 1;

          $class->exports(sub ($export, $realsub, @vars) {
            $class->monkey_patch($$caller[0], $export)
          });

          # $^H{$class . '/user'} = 1;
          $$caller[10]{$class . "/user"} = 1
        }
      }
      continue { $i++ unless scalar @prev }
    }

    push @prev, @curr;

    return undef unless $pkgname; # Probably not a module

    my $pkgpath = Module::Metadata->find_module_by_name($pkgname, \@og_INC);
    return undef unless $pkgpath && !$INC{$filename};

    $INC{$filename} = $pkgpath;
    open my $fh, '<', $pkgpath or die "$! $@";

    my $prepend = qq{{
      use utf8;
      use v5.36;

      my \$caller = [caller 0];
      my \$compose = 0;

      local \$Data::Dumper::Indent = 0;

      no strict 'refs';
      # warn Data::Dumper::Dumper('$pkgname', \\%{'$pkgname' . '::'}, \\%{__PACKAGE__ . '::'}, \$caller, \\%^H)
      #   if List::Util::any { \$_ =~ /^(Frame|Momiji)/ } ('$pkgname', __PACKAGE__);

      foreach my \$pkg (__PACKAGE__, '$pkgname') {
        no strict 'refs';
        next unless \${\$pkg . '::'}{META};
        use strict 'refs';

        my \$meta = \$pkg->META();

        foreach my \$role (\$meta->all_roles) {
          if (\$role eq '$class') {
            \$compose = 1;
            last
          }
        }
      }

      \$compose = 1 if List::Util::any { \$_ =~ /$class/ } (\%{__PACKAGE__ . '::'});

      if (\$^H{'$class/user'} || \$caller->[10]{'$class/user'} || \$compose) {
        use utf8;
        use v5.36;

        \$^H{'$class/user'} = 1;
        \$caller->[10]{'$class/user'} = 1;
        $class->compose(\$caller)
      }
    }};

    # local $Data::Dumper::Indent = 0;
    # warn Dumper($seen_users{pkg});

    my $prev;
    my $compose_str = qq{
      my \@caller = (caller 0);
      my \$compose;

      use utf8;
      use v5.36;
      use $class;
      \$^H{'$class\/user'} = 1;
      \$caller[10]->{'$class\/user'} = 1;

      {
        no strict 'refs';
        if (\${"\$caller[0]\::"}{META}) {
          my \$meta = \${"\$caller[0]\::"}{META}();
          \$compose = 1 if \$meta->is_role;
        }
      }

      # my \$i = 0;
      # while (my (\@caller) = caller(\$i)) {
      #   no strict 'refs';
      #   local \$Data::Dumper::Indent = 0;
      #   warn Data::Dumper::Dumper(\\\@caller, \\%{"\$caller[0]\::"});
      #   \$i++;
      # }

      $class->compose(\\\@caller) if \$compose;

      1;
    };

    # This is really slow, maybe only return source filter sub if package is in certain dir(s)?
    \$prepend, $fh, sub ($, $prev = undef) {
      my $line = \$_;
      foreach my $user (keys $seen_users{pkg}->%*) {
        if ($$line =~ /\:does\($user\)/) {
          $seen_users{pkg}{$pkgname} = 1;
          $seen_users{fn}{$filename} = 1;
          $$line .= $compose_str;
        }
      }
      
      $$line ? 1 : 0
    }, $prev
    # $fh
    # undef
  };

  $import_on_compose->($import_on_compose, scalar @EXPORT_DOES ? __pkgfn__ : $class->__pkgfn__, 0);
  unshift @INC, $import_on_compose;

  1
}

__PACKAGE__->import_on_compose
