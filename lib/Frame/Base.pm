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
our $dev_mode = $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development';
our $frame_debug = $ENV{FRAME_DEBUG} // 0;
our $json_default = JSON::MaybeXS->new(utf8 => 1, $dev_mode ? (pretty => 1) : ());
our $package = __PACKAGE__;
our %seen_users = (fn => { __PACKAGE__->__pkgfn__ => 1}, pkg => { $package => 1 });

use subs @EXPORT_DOES;

$^H{__PACKAGE__ . '/user'} = 1;

__PACKAGE__->import_on_compose;
__PACKAGE__->compose([caller 0]);

field $app :weak :param :accessor = undef;
# field $json :accessor(_json);

ADJUSTPARAMS ($params) {
  # $app //= $$params{app} if $$params{app};
  # $json //= JSON::MaybeXS->new(utf8 => 1, $dev_mode ? (pretty => 1) : ());
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

  my $compose = sub ($caller) {
    return if $seen_users{pkg}{$$caller[0]};

    {
      no strict 'refs';
      return unless ${"$$caller[0]\::"}{META};
    }

    $^H{__PACKAGE__ . '/user'} = 1;
    $$caller[10]{__PACKAGE__ . '/user'} = 1;

    my $meta = $$caller[0]->META();

    __PACKAGE__->exports(sub ($export, $realsub, @vars) {
      $class->monkey_patch($$caller[0], $export)
    }) if $meta->is_role;

    $seen_users{pkg}{$$caller[0]} = 1;
    $seen_users{fn}{__pkgfn__($$caller[0])} = 1
  };

  $compose->($caller);

  my $i = 0;
  while (my (@caller) = (caller $i)) {
    no strict 'refs';
    
    next unless ${"$caller[0]\::"}{META};
    next if $seen_users{pkg}{$caller[0]};

    my $is_user;

    $is_user = 1 if any {
      my $seen = $_;

      return 1 if $caller[0]->DOES($seen);
      return 1 if any { ${"$seen\::"}{$_} =~ /$caller[0]/ } keys %{"$seen\::"};
      0
    } keys $seen_users{pkg}->%*;

    $is_user = 1 if any { $caller[7] && $caller[6] eq $_ } keys $seen_users{fn}->%*;

    $compose->(\@caller) if $is_user;
  } continue { $i++ }
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

  my $import_on_compose = sub ($coderef, $filename) {
    my $pkgname = join '::', ($filename =~ /([^\/]+)(?:\/|\.pm)/g);

    return undef unless $pkgname; # Probably not a module

    my $pkgpath = Module::Metadata->find_module_by_name($pkgname, \@og_INC);
    return undef unless $pkgpath && !$INC{$filename};

    $INC{$filename} = $pkgpath;
    open my $fh, '<', $pkgpath or die "$! $@";

    # my $prepend = qq{{
    #   use utf8;
    #   use v5.36;

    #   my \$caller = [caller 0];
    #   my \$compose;

    #   foreach my \$pkg (__PACKAGE__, '$pkgname') {
    #     no strict 'refs';
    #     next unless \${\$pkg . '::'}{META};
    #     use strict 'refs';

    #     my \$meta = \$pkg->META();

    #     foreach my \$role (\$meta->all_roles) {
    #       if (\$role eq '$class') {
    #         \$compose = 1;
    #         last
    #       }
    #     }
    #   }
      
    #   {
    #     no strict 'refs';
    #     \$compose = 1 if List::Util::any { \${__PACKAGE__ . '::'}{\$_} =~ /$class/ } (keys \%{__PACKAGE__ . '::'})
    #   }

    #   \$compose = 1 if \$^H{'$class/user'} || \$caller->[10]{'$class/user'};

    #   if (\$compose) {
    #     use utf8;
    #     use v5.36;

    #     # {
    #     #   no strict 'refs';
    #     #   local \$Data::Dumper::Indent = 0;
    #     #   warn Data::Dumper::Dumper(\$caller, \\%{"\$\$caller[0]\::"}, \\%^H);
    #     # }

    #     \$^H{'$class/user'} = 1;
    #     \$caller->[10]{'$class/user'} = 1;
        
    #     $class->compose(\$caller)
    #   }
    # }};

    my $prev;
    my $compose_str = qq{
      my \@caller = (caller 0);
      my \$compose;

      use utf8;
      use v5.36;
      use $class;
      \$^H{'$class\/user'} = 1;
      \$caller[10]{'$class\/user'} = 1;

      {
        no strict 'refs';
        if (\${"\$caller[0]\::"}{META}) {
          my \$meta = \${"\$caller[0]\::"}{META}();
          \$compose = 1 if \$meta->is_role
        }
      }

      $class->compose(\\\@caller) if \$compose;

      1;
    };

    state %doesre = ();
    
    # \$prepend, $fh, sub ($, $prev = undef) {
    $fh, sub ($, $prev = undef) {
      my $line = \$_;
      foreach my $user (keys $seen_users{pkg}->%*) {
        $doesre{$user} //= qr/\:does\($user\)/;
        if ($$line =~ $doesre{$user}) {
          $seen_users{pkg}{$pkgname} = 1;
          $seen_users{fn}{$filename} = 1;
          $$line .= $compose_str
        }
      }
      
      $$line ? 1 : 0
    }, $prev
  };

  $import_on_compose->($import_on_compose, scalar @EXPORT_DOES ? __pkgfn__ : $class->__pkgfn__);
  unshift @INC, $import_on_compose;

  1
}

BEGIN {
  __PACKAGE__->compose([caller 0])
}

1
