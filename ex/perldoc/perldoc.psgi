use Object::Pad ':experimental(:all)';

package Frame::App::perldoc::plenv;
role Frame::App::perldoc::plenv;

use utf8;
use v5.44;

field $plenv;

my class plenv {
    use v5.44;

    use Const::Fast;
    use IPC::Nosh;
    use IO::Handle::Common;

    use vars qw'@commands';

    field $debug : param = $ENV{DEBUG} // 0;

    BEGIN {
        my $run = run(
            [qw'plenv commands'],
            out => sub ( $line, %opt ) {

                # const my $dev_null = IO::Handle->
                # error join " ", @opt{cmd} . ": $line"
                # ...;
            },
            autochomp => 1
        );
        const our @commands => ( $run->out->lines_utf8 );
    }

    field $commands = \@commands;

    method AUTOLOAD (@arg) {
        dmsg $commands;
        our $AUTOLOAD;

        my ( $class, $meth ) = ( $AUTOLOAD =~ /^(.*)::(.+)$/ );
        my $cmd = ( $meth =~ s/_/-/gr );

        my @cmd    = ( 'plenv', $cmd, @arg );
        my $cmdstr = join ' ', @cmd;

        my $run = run(
            \@cmd,
            out => sub ( $line, @ ) {
                info("$cmdstr: $line [STDOUT]") if $debug;
            },
            err => sub ( $line, @ ) {
                error("$cmdstr: $line [STDERR]") if $debug;
            },
            autochomp => 1
        );
        $run;
    }
};

method plenv {
    $plenv //= plenv->new;
    $plenv;
}

package Frame::App::perldoc;

class Frame::App::perldoc : isa(Frame) : does(Frame::App::perldoc::plenv);

use utf8;
use v5.44;

use Path::Try;
use Capture::Tiny qw'capture';
use IO::Handle::Common;
use Text::Xslate;
use Plack::App::File;
use Pod::Perldoc;
use Pod::Simple::HTML;
use Syntax::Keyword::Dynamically;

field $json = JSON::MaybeXS->new(
    {
        utf8 => 1,
        (
                 $ENV{PLACK_ENV} eq 'development'
              || $ENV{DEBUG} && $ENV{DEBUG} == 1 ? ( pretty => 1 ) : ()
        )
    }
);

field $xs = Text::Xslate->new( path => './view' );
field $modlist { [ $self->plenv->list_modules->out->lines_utf8 ] };
field $perldoc = {};
field $uribase;
field $pod2html { Pod::Simple::HTML->new }

ADJUST {
    $pod2html->bare_output(1)
}

method render ( $template, $data, %opt ) {

    # dmsg path("./")->absolute, path("./")->children;
    $xs->render(
        $template,
        {
            title   => 'Perl 5 Documentation',
            uribase => $uribase,
            %$data
        }
    );
}

method modlist ($tx) {
    my $res = $tx->req->new_response(200);
    foreach my $mod (@$modlist) {
        $mod = {
            name => $mod,
            url  => $tx->req->script_name . "/$mod"
        };
    }

    $res->body( $self->render( 'modlist.tx', { modlist => $modlist } ) );
    $res;
}

method startup {
    my $r = $self->routes;

    my $doc = $r->under(
        '/',
        sub ( $self, @arg ) {

            # dmsg $self, \@arg;
            $uribase = $self->req->script_name;
            1;
        }
    );

    # $doc->get( '/s/',
    #     Plack::App::File->new( root => 'static', file => 'static' )->to_app );
    # $doc->get(
    #     '/s/bulma.min.css',

    #     # sub {
    #     #     state $file //= Plack::App::File->new(
    #     #         root => 'bulma/css',
    #     #         file => 'bulma.min.css'

    #     #     )->to_app;
    #     #     $file->call;
    #     # }
    #     Plack::Middleware::File->new(
    #         root => 'bulma/css',
    #         file => 'bulma.min.css'
    #     )->to_app
    # );

    # $doc->get( '/',        \&modlist );
    # $doc->get( '/modlist', \&modlist );

    $doc->get(
        '/modlist',
        sub ( $self, @arg ) {
            $self->app->modlist($self);
        }
    );

    $doc->get(
        '/:name' => sub ( $self, $name ) {
            my $req = $self->req;
            my $res = $req->new_response(200);

            my $htmlstr;

            my ( $stdout, $stderr, @ret ) = capture sub {
                local @ARGV = ( qw'-T -o pod', $name );

                # dmsg $self, $self->app, $req, $res, $name;
                Pod::Perldoc->run();
            };

            # dmsg $stdout, $stderr, \@ret;

            $pod2html->output_string( \$htmlstr );
            $pod2html->parse_string_document($stdout);

            # if ( $run->status != 0 ) {
            #     dmsg $run;
            #     $res->status(400);
            #     $res->body( join "", $run->err->lines_utf8 );
            # }
            # else {
            #     dmsg $run;
            $res->status(200);

            $$perldoc{$name} = $htmlstr;

            my $body = $self->app->render(
                'module.tx',
                {
                    module  => $name,
                    htmlstr => Text::Xslate::mark_raw( $$perldoc{$name} )
                }
            );

            $res->body($body);

            $res;
        }
    );

    $self;
}

package perldoc_psgi;

class perldoc_psgi;

use utf8;
use v5.44;

use IO::Handle::Common;
use Plack::Builder;
use Path::Try;
use Plack::App::File;

my class StaticSrv : isa(Plack::App::File) {
    use v5.44;

    use Path::Try;
    use IO::Handle::Common;

    ADJUST {
        # dmsg $self;
        # dmsg path("./bulma/css/bulma.min.css")->absolute->lines_utf8
    }
};

builder {
    mount '/s/bulma.min.css' =>
      StaticSrv->new( file => './bulma/css/bulma.min.css' )->to_app;

    mount '/s' => StaticSrv->new( root => './static' )->to_app;
    mount '/'  => Frame::App::perldoc->new->to_app;

}

