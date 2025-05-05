use Object::Pad ':experimental(:all)';

package Frame::App::Static::Index;

class Frame::App::Static::Index : does(Frame);

use utf8;
use v5.40;

method startup {

}
#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

package srv;

class srv : does(Frame);

use utf8;
use v5.40;

use Cwd;
use List::Util 'any';
use Path::Tiny;
use Const::Fast;
use File::Basename;
use Plack::Builder;
use Plack::App::File;
use Plack::Middleware::Static;
use Syntax::Keyword::Dynamically;
use Plack::Middleware::Auth::Basic;
use Crypt::Argon2 qw(argon2id_pass argon2_verify);

class DirIndex : isa(Plack::App::Directory) {

    use Const::Fast;

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

    method BUILDARGS : common (@BUILDARGS) {
        @BUILDARGS;
    }

    ADJUST {
        $Plack::App::Direectory::dir_page = $DirIndex::dir_page;
    };

    $Plack::App::Direectory::dir_page = $dir_page;

    method serve_path : override ($env, $dir) {
        $Plack::App::Direectory::dir_page = $dir_page;
        Plack::App::Directory::serve_path( $self, $env, $dir );
    }
};

const our $DEBUG   => $ENV{DEBUG};
const our $MOUNTRE => qr/^(.+)(?:\:(.+))?$/;

our ( $srvpath, $mount ) = $ARGV[-1] =~ $MOUNTRE;

our $builder = Plack::Builder->new;


sub serve_directory ( $path, %args ) {
    ( DirIndex->new( { root => $path } )->to_app, $args{uri} // '/' );
}

sub init ( $path = path( $srvpath // getcwd ), $uri = $mount // undef ) {
    $builder->add_middleware('Debug')
      unless any { $_ } @ENV{qw'NODEBUG PRODUCTION'};
    $builder->app_middleware('REPL') if $ENV{REPLWARNING};

    my $envoptname = sub ($unqualified, $sep = qr/_[a-z0-9]+([a-z0-9]|_*)/, @prefix) {
    };

    $builder->add_middleware(
        'Auth::Basic',
        authenticator => sub (@args) {
            valid_user(@args);
        }
    ) unless any { $_ } @ENV{map {} qw(FRAME)};

    my ( $app, $mount ) =
        -f $path ? serve_file( $path, uri => $uri )
      : -d $path ? serve_directory( $path, uri => $uri )
      :   die "Path '$path' does not appear to be a file or directory.";

    ...
}

method startup {
    ...;
}
