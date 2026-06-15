use Object::Pad ':experimental(:all)';

package Frame::App::Static::DirIndex;

class Frame::App::Static::DirIndex   : isa(Frame);

use utf8;
use v5.40;

use Cwd;
use List::Util 'any';
use Path::Tiny;
use Const::Fast;
use Plack::Builder;
use Plack::App::File;
use Plack::Middleware::Static;
use Syntax::Keyword::Dynamically;
use Plack::Middleware::Auth::Basic;
use IO::Handle::Common;

const our $DEBUG   => $ENV{DEBUG};
const our $MOUNTRE => qr/^(.+)(?:\:(.+))?$/;

my class DirIndex : isa(Plack::App::Directory) {    #:does(Frame::Controller) {
    use utf8;
    use v5.40;

    use IO::Handle::Common;
    use Const::Fast;
    use Path::Tiny;

    # use parent 'Plack::App::Directory';

    const our $dir_page => <<'...';
<!DOCTYPE html>
<html lang="en">

<head>
<title>%s</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rel="stylesheet" href="/static/css/bulma.min.css">
<style type='text/css'>
table {
  width: 100 % %;
  }

  . name {
    text-align : left;
  }

  . size, . mtime {
    text-align : right;
  }

  . type {
  width: 11 em;
  }

  . mtime {
  width: 15 em;
}
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

    use vars '$dir_page';

    method BUILDARGS : common (@BUILDARGS) {
        @BUILDARGS;
    }

    ADJUST {
        $Plack::App::Directory::dir_page = $dir_page;
    };

    $Plack::App::Directory::dir_page = $dir_page;

    method should_handle : override ( $path ) {
        $path = path($path);
        $path->is_directory || $path->is_file;
    }

    method return_dir_redirect ($env) {
        my $uri = Frame::Request->new($env)->uri;
        $self->redirect( "$uri/", 301 );
    }

    method serve_path : override ($env, $dir) {
        $dir = path($dir);

        # $self->Frame::App::Static::File::serve_path( $env, $dir )
        #   if $dir->is_directory;

        $Plack::App::Directory::dir_page = $dir_page;
        Plack::App::Directory::serve_path( $self, $env, $dir );

        # my $dir_url = $env->{SCRIPT_NAME} . $env->{PATH_INFO};
    }
};

field $srvpath;
field $mount;
field $builder = Plack::Builder->new;

method serve_directory ( $path, %args ) {
    ( DirIndex->new( { root => $path } )->to_app, $args{uri} // '/' );
}

method init ( $path = path( $srvpath // getcwd ), $uri = $mount // undef ) {
    $builder->add_middleware('Debug')
      unless any { $_ } @ENV{qw'NODEBUG PRODUCTION'};
    $builder->app_middleware('REPL') if $ENV{REPLWARNING};

    my $envoptname =
      sub ( $unqualified, $sep = qr/_[a-z0-9]+([a-z0-9]|_*)/, @prefix ) {
      };

    # $builder->add_middleware(
    #     'Auth::Basic',
    #     authenticator => sub (@args) {
    #         valid_user(@args);
    #     }
    # ) unless any { $_ } @ENV{ map { ... } qw(FRAME) };

    my ( $app, $mount ) = -f $path
      ? fatal
"Unimplemented: Virtual directory index for file or list of files is not yet implemented." #serve_file( $path, uri => $uri )
      : -d $path ? serve_directory( $path, uri => $uri )
      :   fatal "Path '$path' does not appear to be a file or directory.";

    ...;
}

method startup {
    ...;
}
