use Object::Pad ':experimental(mop)';

package Frame::Base;
role Frame::Base;

use utf8;
use v5.36;

# use parent 'Exporter';

use Carp;
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

sub _json_default { JSON::MaybeXS->new(utf8 => 1, $dev_mode ? (pretty => 1) : ()) }
state $json_default = _json_default;

our $package = __PACKAGE__;
our %seen_users = (fn => { __PACKAGE__->__pkgfn__ => 1 }, pkg => { $package => 1 });

use subs @EXPORT_DOES;

$^H{__PACKAGE__ . '/user'} = 1;

#__PACKAGE__->compose(__PACKAGE__, [caller 0], patch_self => 1);
__PACKAGE__->import_on_compose;
__PACKAGE__->compose(__PACKAGE__, [caller 0]);

field $app :weak :param :accessor = undef;
field $json;

ADJUSTPARAMS ($params) {
  # $^H{__CLASS__ . '/user'} = 1
}

method json ($_json = undef) {
  $json = $_json if $_json;
  $json // $json_default
}

# method json :common {
#   $json_default
# }

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

    $out .= scalar @msgs > 1 ? Dumper(@msgs) : ref $msgs[0]
      ? Dumper(@msgs) : eval { my $s = $msgs[0] // 'undef'; "  $s\n" };

    $out .= "\n"
  }

  $out .= $ENV{FRAME_DEBUG} == 2
    ? join "\n", map { (my $line = $_) =~ s/^\t/  /; "  $line" } split /\R/, Devel::StackTrace::WithLexicals->new(
        indent => 1,
        skip_frames => 1
      )->as_string
    : "at $caller[1]:$caller[2]";

  say STDERR "$out\n";
  $out
}

method monkey_patch :common ($package, $sub, %args) {
  {
    no strict 'refs';
    no warnings 'redefine';

    # say Dumper($args{name} // $sub);
    
    if (ref $sub eq 'CODE') {
      return -1 unless $args{name};
      return -1 if ${"$package\::"}{$args{name}} && !$args{patch_self};
      *{"$package\::$args{name}"} = $sub
    }
    else {
      return -1 if ${"$package\::"}{$sub} && !$args{patch_self};
      *{"$package\::$sub"} = \&{$class . "::$sub"}
    }

    # say Dumper($args{name} // $sub)
  }

  $args{on_patch}($args{on_patch_args})
    if ref $args{on_patch} eq 'CODE';

  1
}

method exports :common ($src, $cb, @vars) {
  {
    no strict 'refs';
    foreach my $export (@{"$src\::EXPORT_DOES"}) {
      use strict 'refs';
      return 0 unless $cb->($export, $export, @vars)
    }
  }

  1
}

method patch_self :common ($src, $plain_subs) {
  my $meta = $src->META();

  $class->exports($src, sub ($export, $realsub, @vars) {
    use strict 'refs';
    my $og_sub = eval { no strict 'refs'; \&{"$src\::$export"} };
    my $wrapper;

    try {
      my $method_meta = $meta->get_method($export);
      # say Dumper($method_meta->name);

      if ($method_meta->is_common) {
        $wrapper = sub {
          unshift @_, $src;
          goto $og_sub
        }
      }
      else {
        $wrapper = sub {
          my @caller = caller 0;
          my $caller_vars = peek_my(1);
          my $_self = $$caller_vars{'$self'}->$*;
          my $_class = ref $_self;
          my $_meta = $_self->META();
        
          # {
          #   no strict 'refs';
          #   say Dumper($_class, \%{"$_class\::"})
          # }

          # my $i = 0;
          # while (my @caller = caller $i) {
          #   {
          #     no strict 'refs';
          #     local $Data::Dumper::Indent = 0;
          #     warn Dumper([caller($i)])
          #   }
          # } continue { $i++ }
          
          $og_sub = eval {
            no strict 'refs';
          #   # local *{"$_class\::$export"} = *{"$src\::$export"};
          #   ${"$_class\::"}{"$export"};
            \&{"$caller[0]\::$export"};
          };
          # $og_sub = \&$export;

          unshift @_, $_self;
          # $og_sub->(@_)
          goto $og_sub
        }
      }

      $class->monkey_patch($src, $wrapper, name => $export, patch_self => 1)
    }
    catch ($e) {
      $$plain_subs{$export} = 1
    }
  })
}

# $dest was formerly $caller but it might not be an array ref with the
# return value of the caller depending on how this shapes  up
method compose :common ($src, $dest, %args) {
  my %plain_subs;

  $class->patch_self($src, \%plain_subs) if ($args{patch_self});

  # Maybe this should only accept a package name?
  my $compose = sub ($caller) {
    return if $seen_users{pkg}{$$caller[0]};

    {
      no strict 'refs';
      return unless ${"$$caller[0]\::"}{META};
    }
    
    use utf8;
    use v5.36;

    $^H{$class . '/user'} = 1;
    # $$caller[10]{$class . '/user'} = 1;

    my $meta = $$caller[0]->META();

    $class->exports($src, sub ($export, $realsub, @vars) {
      $class->monkey_patch($$caller[0], $export)
        if $meta->is_role || $plain_subs{$export}
    });

    $seen_users{pkg}{$$caller[0]} = 1;
    $seen_users{fn}{__pkgfn__($$caller[0])} = 1
  };

  return if $args{patch_self};
  $compose->($dest);
  # return if $args{patch_self};

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

# TODO: Double check if I like this as is, can't delete it now because
# it breaks things, but I'm suspicious its suspect
method import :common  {
  my $caller = eval "[caller 1]";

  no strict 'refs';
  return unless ${"$$caller[0]\::"}{ISA};

  use utf8;
  use v5.36;

  $^H{__PACKAGE__ . '/user'} = 1;
  $$caller[10]{__PACKAGE__ . '/user'} = 1;

  __PACKAGE__->exports(__PACKAGE__, sub ($export, $realsub, @vars) {
    $class->monkey_patch($$caller[0], $export)
  });

  $seen_users{pkg}{$$caller[0]} = 1;
  $seen_users{fn}{__pkgfn__($$caller[0])} = 1;
  
  # __PACKAGE__->export_to_level(1, $class, @_)
}

method import_on_compose :common {
  state @og_INC = @INC;
  my %plain_subs;

  # $class->exports($class, sub ($export, $realsub, @vars) {
  #   my $og_sub = \&{"$class\::$export"};

  #   # If we wrap our wrapper sub in a string eval maybe we could make
  #   # it a lexical named sub instead of an anon sub (for better hints)
  #   $class->monkey_patch($class, sub {
  #     unshift @_, $class;
  #     goto $og_sub
  #   }, name => $export)
  # });

  $class->patch_self($class, \%plain_subs);
  # say Dumper($class, \%plain_subs);
  # __PACKAGE__->compose(__PACKAGE__, [caller 0], patch_self => 1);

  my $import_on_compose = sub ($coderef, $filename) {
    my $pkgname = join '::', ($filename =~ /([^\/]+)(?:\/|\.pm)/g);

    return undef unless $pkgname; # Probably not a module

    my $pkgpath = Module::Metadata->find_module_by_name($pkgname, \@og_INC);
    return undef unless $pkgpath && !$INC{$filename};

    $INC{$filename} = $pkgpath;
    open my $fh, '<', $pkgpath or die "$! $@";

    my $prev;
    my $compose_str = qq{
      my \@caller = (caller 0);
      my \$compose;

      use utf8;
      use v5.36;
      use $class;
      \$^H{'$class\/user'} = 1;
      \$caller[10]{'$class\/user'} = 1;

      if (eval { no strict 'refs'; \${"\$caller[0]\::"}{META} }) {
        my \$meta = \$caller[0]->META;
        \$compose = 1 if \$meta->is_role
      }

      $class->compose('$class', \\\@caller) if \$compose;

      1;
    };

    state %doesre = ();
    
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

1
