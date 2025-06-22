#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

package srv;

class srv : does(Frame);

use utf8;
use v5.40;

use Cwd;
use List::Util qw(any first);
use Path::Tiny;
use Const::Fast;
use File::Basename;
use Plack::Builder;
use Plack::App::File;
use Plack::Middleware::Static;
use Syntax::Keyword::Dynamically;
use Plack::Middleware::Auth::Basic;
use Crypt::Argon2 qw(argon2id_pass argon2_verify);

#role Frame::App::Static : does(Frame) {
#    method startup {
#    }
#};

class PublicFile : isa(Plack::App::File) {
    use utf8;
    use v5.40;

    use File::Basename;
    use File::Spec;
    use Path::Tiny;
    use Cwd;

    #field $root : param;
    #field $path : param = { path( $root . '/' . basename($path) ) };

    ADJUST {
        ...
    }
};

class DirIndex : isa(Plack::App::Directory) {

    use URI::Escape;
    use Plack::Util;
    use HTTP::Date;
    use Const::Fast;
    use MIME::Types;
    use List::Util qw(any first);

    const our $dir_file =>
"<tr><td class='name'><a href='%s'>%s</a></td><td class='size'>%s</td><td class='type'>%s</td><td class='mtime'>%s</td></tr>";

    const our $dir_page => <<'...';
<!DOCTYPE html>
<html lang="en">
<head>
<title>%s</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link
  rel="stylesheet"
  href="/www/bulma.min.css"
>
<style type='text/css'>
table { width:100%%; }
.name { text-align:left; }
.size, .mtime { text-align:right; }
.type { width:11em; }
.mtime { width:15em; }
</style>
</head>
<body>
<h1>%s</h1>
<hr />
<table>
  <tr>
    <th class='name'>Name</th>
    <th class='size'>Size</th>
    <th class='type'>Type</th>
    <th class='mtime'>Last Modified</th>
  </tr>
%s
</table>
<hr />
</body>
</html>
...

    field $mimetypes = MIME::Types->new;

    method BUILDARGS : common (@BUILDARGS) {
        @BUILDARGS;
    }

    # Think I'd rather this be a common method but its called with $self by
    # Plack::App::File
    method should_handle ($path) {
        -d $path || -f $path;
    }

    method return_dir_redirect ($env) {
        my $uri = Plack::Request->new($env)->uri;
        return [
            301,
            [
                'Location'       => $uri . '/',
                'Content-Type'   => 'text/plain',
                'Content-Length' => 8,
            ],
            ['Redirect'],
        ];
    }

    method serve_path : override ($env, $dir) {
        return Plack::App::File::serve_path( $self, $env, $dir ) if -f $dir;
        my $is_dir  = -d $dir;
        my $dir_url = join '', $env->@{qw'SCRIPT_NAME PATH_INFO'};

        my $uriendslash_re => qr!/$!;

        return $self->return_dir_redirect($env)
          unless $dir_url =~ $uriendslash_re;

        my @files = ( [ "../", "Parent Directory", '', '', '' ] );

        my $dh = DirHandle->new($dir);
        my @children;

        while ( my $ent = $dh->read ) {
            next if $ent eq '.' or $ent eq '..';
            push @children, $ent;
        }

        for my $basename ( sort { $a cmp $b } @children ) {

            my $file = "$dir/$basename";
            my $url  = $dir_url . $basename;

            my $is_dir = -d $file;
            my @stat   = stat _;

            const my $PATHSEP_RE => qr!/!;

            $url = join '/', map { uri_escape($_) } split qr/$PATHSEP_RE/, $url;

            if ($is_dir) {
                $basename .= "/";
                $url      .= "/";
            }

            my $mime_type =
              $is_dir
              ? 'directory'
              : ( first { $_ }
                  ( $mimetypes->mimeTypeOf($file), 'text/plain' ) );

            push @files,
              [
                $url, $basename, $stat[7], $mime_type,
                HTTP::Date::time2str( $stat[9] )
              ];
        }

        my $path  = Plack::Util::encode_html("Index of $env->{PATH_INFO}");
        my $files = join "\n", map {
            my $f = $_;
            sprintf $dir_file, map Plack::Util::encode_html($_), @$f;

        } @files;

        my $page = sprintf $dir_page, $path, $path, $files;

        [ 200, [ 'Content-Type' => 'text/html; charset=utf-8' ], [$page] ];
    }
};

const our $DEBUG   => $ENV{DEBUG};
const our $MOUNTRE => qr/^(.+)(?:\:(.+))?$/;

our ( $srvpath, $mount ) = $ARGV[-1] =~ $MOUNTRE;

our $builder = Plack::Builder->new;

method startup {
    ...;
}

sub valid_user ( $user, $pass, $env ) {
    $user eq $ENV{SRV_USER}
      && argon2_verify( $ENV{SRVPATH_PWHASH}, $pass );
}

sub serve_directory ( $path, %args ) {
    ( DirIndex->new( { root => $path } )->to_app, $args{uri} // '/' );
}

sub serve_file ( $file, %args ) {
    (
        Plack::App::File->new( file => $file )->to_app,
        map { s/^([^\/]{1}.+)$/\/$1/r } ( $args{uri} // basename($file) )
    );
}

sub init ( $path = path( $srvpath // getcwd ), $uri = $mount // undef ) {
    $builder->add_middleware('Debug')
      unless any { $_ } @ENV{qw'NODEBUG PRODUCTION'};
    $builder->app_middleware('REPL') if $ENV{REPLWARNING};

    $builder->add_middleware(
        'Auth::Basic',
        authenticator => sub (@args) {
            valid_user(@args);
        }
    ) unless $ENV{SRVPL_NOLOGIN};

    my ( $app, $mount ) =
        -f $path ? serve_file( $path, uri => $uri )
      : -d $path ? serve_directory( $path, uri => $uri )
      :   die "Path '$path' does not appear to be a file or directory.";

    $builder->mount( $mount => $app );
    $builder->mount( '/www' => './www' );
    $builder;
}

unless (caller) {
    require Plack::Runner;

    my $runner = Plack::Runner->new;
    $runner->parse_options( qw(-s Frame::Server), @ARGV );
    $runner->run( init->to_app );

    exit( $? // 0 );
}

init
