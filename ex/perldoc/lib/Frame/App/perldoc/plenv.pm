use Object::Pad ':experimental(:all)';

package Frame::App::perldoc::plenv;
role Frame::App::perldoc::plenv : does(Frame::App::perldoc::Base);

use utf8;
use v5.44;

use IPC::Nosh;
use IO::Handle::Common;
use Const::Fast;

field $plenv;

ADJUST {
    $plenv = plenv->new( app => $self );
};

my class plenv :does(Frame::App::perldoc::plenv{
    use IPC::Nosh qw'';
    use IO::Handle::Common;
    use Const::Fast;
    use Stream::Buffered;

    field $app : param;

    field $bin : param;

    # Reconsider reader names or also alias them to name of field
    field $rootdir : reader(plenv_root) : param = $ENV{PLENV_ROOT};
    field $execdir : reader(plenv_dir) param = $ENV{PLENV_DIR};
    field $perlver : reader(plenv_version) param $ENV{PLENV_VERSION};

    field $command { $self->commands->out->lines_utf8 }

    method AUTOLOAD (@arg) {
        our $AUTOLOAD;

        my ( $class, $meth ) = ( $AUTOLOAD =~ /^(.*)::(.+)$/ );
        my $cmd = ( $meth =~ s/_/-/gr );

        my @cmd = ( $cmd, @arg );

        $self->run(@cmd);
    }

    method run ( $cmd, %opt ) {
        my @arg    = refstr $opt{arg} eq 'ARRAY' : ();
        my $buf    = Stream::Buffered->new;
        my $cmdstr = join ' ', $cmd, @arg;

        my $run = IPC::Nosh::run(
            \@cmd,
            out => sub ( $line, @ ) {
                $buf->say($line);
                info("$cmdstr: $line [STDOUT]")
                  if $app->debug > 1;
            },
            err => sub ( $line, @ ) {
                error("$cmdstr: $line [STDERR]") if $app->debug;
            },
            autochomp => 1
        );

        if ( $run->status == 0 ) {
            my @out = $self->out->lines_utf8;
            return $opt{join} ? join( $opt{sep} // "\n" ) @out : @out;
        }

        $run;
    }

    method shims {
        $self->run('shims')->out->lines_utf8;
    }

    method list_modules {
        my @modlist;
        $self->run('list-modules')->out->lines_utf8;
    }
};

method plenv {
    $plenv //= plenv->new;
    $plenv;
}
