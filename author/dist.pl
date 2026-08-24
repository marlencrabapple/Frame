#!/usr/bin/env perl
package dist;

use v5.40;
no warnings 'experimental::re_strict';
use re 'strict';

use Path::Tiny;
use Const::Fast;
use CPAN::Mini::Inject;
use IPC::Nosh;
use Syntax::Keyword::Defer;
use Syntax::Keyword::Try;
use IO::Handle::Common;
use Getopt::Long
  qw(GetOptionsFromArray :config no_ignore_case auto_abbrev passthrough bundling long_prefix_pattern=--?);
use JSON::MaybeXS;

our $verbose = $ENV{VERBOSE} // 9;
our $debug   = $ENV{DEBUG}   // 0;

our %config_path = ( meta => path('META.json'), author => path('dist.ini') );
our $config      = { meta => decode_json( $config_path{meta}->slurp_utf8 ) };

our $distname = $config->{meta}{name};
our $package;
our $archive;
our $version;

our $trial;

our $has_suffix;

const our $dist_suffix_default => 'TRIAL';
our $dist_suffix;
$dist_suffix = $dist_suffix_default if $trial;

sub cli ( $argv = \@ARGV, %opt ) {

    GetOptionsFromArray(
        $argv,
        'trial' => \$trial,
        'verbose+',
        => \$verbose,
        'debug+',
        => \$debug,
        'quiet' => sub {
            $verbose = 0;
        }
    );

    $$config{author} = parse_ini( $config_path{author} );

    $package = ( $config->{meta}{name} =~ s/-/::/gr );

    my $trial //= $$config{author}->{release_status}
      && $$config{author}->{release_status} ne 'stable' ? 1 : 0;

    $dist_suffix //= $dist_suffix_default if $trial;
}

sub parse_ini ($file) {
    my %data = ();
    my $section;

    foreach my $line ( $file->lines_utf8 ) {
        if ( $line =~ /^\[(.+)\]$/ ) {
            my $section = $1;
            $data{$1} = {};
            next;
        }

        my ( $k, $v ) = split /=/, $line;

        $section ? $data{$section}{$k} = $v : $data{$k} = $v;
    }

    \%data;
}

sub mvdir ( $src, $dst, %opt ) {
    $dst->mkdir unless $dst->is_dir;

    my $onvisit = sub ( $path, $state ) {

        if ( $path->is_dir ) {
            $dst->mkdir($path);
            $path->remove_tree if scalar $path->children == 0;
            return;
        }
        else {
            $path->copy($dst);
            $path->remove;
        }
    };

    $src->visit( $onvisit, { recurse => 1 } );
    $src->remove_tree;
}

sub make_dist( $dist, %opt ) {
    my ( $archive, $version, $has_suffix );
    my $test = 0;

    my $bindir = path('./bin');
    my $tmp;

    if ( $bindir->is_dir ) {
        info "Temporarily relocating './bin' to avoid conflict with Minilla";

        $tmp = Path::Tiny->tempdir;

        mvdir( $bindir, $tmp );

    }
    const my $archive_re =>
qr/^\[DZ\] writing archive to (($distname)-(.+?)?(?:-(TRIAL))?\.tar\.gz)$/;

    my $run = run(
        [ qw'milla build', ( $trial ? '--trial' : () ) ],
        out => sub ( $line, @ ) {
            $test++;

            if ($verbose) {
                my $say = $debug ? __LINE__ . ": $line" : $line;
                say $say;
            }

            # TODO: Add functionality to remove callback when no longer needed
            ( $archive, undef, $version, $has_suffix ) =
              ( $line =~ $archive_re )
              unless $archive && $version;
        },
        err       => sub ( $line, @ ) { say STDERR $line if $verbose },
        autochomp => 1
    );

    mvdir( $tmp, $bindir ) if $tmp;

    dmsg $run, $archive, $version, $has_suffix, $test;

    say join "\n", $run->err->lines_utf8 if $verbose;

    fatal( ( join " ", $run->cmd->@* )
        . " exited with non-zero status: "
          . $run->status )
      if $run->status != 0;

    fatal "Could not parse archive name from '"
      . ( join " ", $run->cmd->@* )
      . "' output."
      unless $archive && $version;

    ( $archive, $version, $has_suffix );
}

sub make_build () {

}

sub rename_archive ( $src, $dst ) {
    $archive->move($dst);
}

sub upload_to_cpanm {
    ...;
}

sub dist {

    ( $archive, $version, $has_suffix ) =
      make_dist( $distname, trial => $trial );

    $archive = path($archive);

    if (
        my $moved =
          $has_suffix || !$dist_suffix
        ? $archive
        : rename_archive(
            $archive,
            $archive->basename(qr/\.tar\.gz$/) . "-$dist_suffix.tar.gz"
        )
      )
    {
        success "Wrote $moved";
        exit 0;
    }
    else {
        fatal "Something went wrong. ($?)";
        dmsg $archive, $moved;
    }
}

cli( \@ARGV );
dist()
