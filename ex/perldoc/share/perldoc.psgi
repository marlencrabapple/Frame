use Object::Pad ':experimental(:all)';

package Frame::App::perldoc::mcpani;
role Frame::App::perldoc::mcpani;

use utf8;
use v5.44;

my class mcpani {

    use v5.44;

    use Path::Try;
    use File::HomeDir;
    use Const::Fast;
    use List::Util qw'all any pairgrep';
    use IO::Handle::Common;
    use builtin;

    const our $splitle_re => qr/[\n\r]+/;

    field $userhome : param = File::HomeDir->my_home;
    field $config = {};
    field $modlist { $self->modlist };

    ADJUST : params (:$config_file = "$userhome/.mcpani/config") {
        dmsg $config_file;
        $config = {
            __PACKAGE__->parse_config(
                [ path($config_file)->absolute->lines_utf8 ]
            )
        };
        dmsg $config;
    };

    method parse_config : common (@in) {
        const my $lines_aref => sub($str) {
            [ split /$splitle_re/, $str ]
        };

        my $in =
          scalar @in == 1
          && ( any { Frame::Base::refstr( $in[0] ) eq $_ } ( 'ARRAY', '' ) )
          ? shift @in
          : \@in;

        if ( my $type = reftype $in ) {
            if ( $type ne 'ARRAY' ) {
                $in = $lines_aref->("$in");
            }
        }
        else {
            $in = $lines_aref->($in);
        }

        my %config;

        foreach my ( $k, $v ) ( map { (/^([^\s:]+)\s*:\s(.+)$/g) } @$in ) {
            $v = builtin::trim($v);

            next unless all { $_ && $_ ne '' } ( $k, $v );

            my @v = split /\s/, $v;
            $v = \@v if scalar @v > 1;

            $config{$k} = $v;
        }

        %config;
    }

    method modlist {

        # my $path = path( $$config{local} );
        dmsg $self, $config;
        my @modlist;

        #         my $visit = path( $$config{local} )->visit(
        #             sub ( $path, $state ) {
        #                 return
        #                   unless $path->is_file;

        #                 my %diststub;

        #                 ( @diststub{qw'name version suffix'} ) =
        #                   ( $path->basename =~
        # /^([a-z90-9_-]+)-([a-z0-9._]+)(?:-([a-z0-9_]+))?.tar.gz$/ig
        #                   );

        #                 dmsg \%diststub;

        #                 push @modlist, \%diststub;
        #             },
        #             { recurse => 1 }
        #         );
    }
};

# method mcpani {
#     state $mcpani //= mcpani->new;
#     $mcpani;
# }

# method plenv {
#     state $plenv //= plenv->new;
#     $plenv;
# }

package Frame::App::perldoc;

class Frame::App::perldoc : isa(Frame) : does(Frame::App::perldoc::Base);

our $VERSION = '0.01_00';

my class Perldoc {
    use v5.44;

    use Pod::Perldoc;
    use Pod::Simple::HTML;
    use IO::Handle::Common;
    use Capture::Tiny qw'capture';
    use Syntax::Keyword::Try;

    field $perldoc : param : reader;
    field $pod2html;
    field $pod    : param : reader;
    field $poderr : param : reader;
    field $podret : param : reader;

    ADJUST {
        $pod2html = $self->pod2html;
    };

    method pod2html {
        $pod2html //= Pod::Simple::HTML->new;
        $pod2html->perldoc_url_prefix("/");
        $pod2html->bare_output(1);
        $pod2html->index(1);

        # $pod2html->complain_stderr(1);
        $pod2html;
    }

    method html (%opt) {
        my $dest = "";
        $opt{dest} //= \$dest;
        $pod2html->output_string( $opt{dest} );
        $pod2html->set_source( \$pod );
        $pod2html->run;
        $opt{dest} == \$dest ? $dest : $pod2html;
    }

    method module : common ($name) {
        my $perldoc;
        my ( $stdout, $stderr, @ret ) = capture sub {
            try {
                use vars '@ARGV';
                local @ARGV = ( qw'-T -u', $name );
                $perldoc = Pod::Perldoc->run(@ARGV);
            }
            catch ($e) {
                dmsg $e, $name;    #$req, $res;
                error $e;
            }
        };

        return $class->new(
            module  => $name,
            pod     => $stdout,
            poderr  => $stderr,
            podret  => \@ret,
            perldoc => $perldoc
        );
    }
};

method perldoc {
    Perldoc;
}

use utf8;
use v5.44;

use Const::Fast;
use Path::Try;
use IO::Handle::Common;
use Text::Xslate;
use List::Util qw'uniq';

field $xs : reader = Text::Xslate->new( path => './view' );
field $modlist {
    [
        uniq(
            # $self->mcpani->modlist,

            $self->plenv->list_modules->out->lines_utf8
        )
    ]
};

field $html = {};
field $uribase;

field $app { $self };

method render( $template, $data, %opt ) {
    $xs->render(
        $template,
        {
            uribase => $uribase,
            %$data
        }
    );
}

method modlist_page ($tx) {

    my $res     = $tx->req->new_response(200);
    my %modlist = ();

    foreach my $mod (@$modlist) {
        my $perldoc;
        my $pod2html;
        my $htmlstr;

        const my $getmodinfo => sub ($mod) {
            $perldoc  = $self->perldoc->module($mod);
            $pod2html = $perldoc->html( dest => \$htmlstr );

            my %modinfo = (
                name     => $mod,
                html     => $htmlstr,
                pod      => $perldoc->pod,
                perldoc  => $perldoc,
                pod2html => $pod2html
            );

            foreach my $meth (
                qw'get_author get_authors get_description get_short_title get_title get_title_short get_token get_version'
              )
            {
                my ($field) = ( $meth =~ s/get_//rg );
                $modinfo{$field} = $pod2html->$meth;
            }

            dmsg \%modinfo;

            %modinfo;
        };

        # push , $mod;
        $modlist{$mod} //= {
            name    => $mod,
            podhtml => $htmlstr,

            $getmodinfo->($mod),
            url => $tx->req->script_name . "/$mod"
        };
    }

    $res->body(
        $app->render(
            'modlist.tx',
            { title => 'Module Index', modlist => [ @modlist{@$modlist} ] }
        )
    );
    $res;
}

method perldoc_page( $tx, $name //= 'perl' ) {
    my $req = $tx->req;
    my $res = $req->new_response(200);
    $$html{$name} = "";

    my $perldoc = $self->perldoc->module($name);
    dmsg $perldoc, $perldoc->perldoc;
    my $pod2html = $perldoc->html( dest => \$$html{$name} );
    dmsg $pod2html;
    $res->status(200);

    my $body = $app->render(
        'module.tx',
        {
            module  => $name,
            title   => $pod2html->get_short_title,
            htmlstr => Text::Xslate::mark_raw( $$html{$name} )
        }
    );

    $res->body($body);
    $res;
}

method perl_index($tx) {
    $self->perldoc_page( $tx, 'perl' );
}

method startup {
    my $r   = $self->routes;
    my $app = $self;

    my $doc = $r->under(
        '/' => sub ( $self, @arg ) {
            $uribase = $self->req->script_name;
            return $app->perl_index($self) if $self->req->path_info eq '/';
            1;
        }
    );

    $doc->get(
        '/modlist' => sub ($self) {
            $app->modlist_page($self);
        }
    );

    $doc->get(
        '/:name' => sub ( $self, $name //= 'perl' ) {
            $app->perldoc_page( $self, $name );
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

    field $req;

    method get_path ($path) {
        fatal "Request field is not an instance of Plack::Request"
          unless blessed($req) && $req->isa('Plack::Request');

        my $res = $req->new_response;

        if ( $path->is_file ) {
            $res->status(200);
            $res->body( $path->openr_utf8 );
        }
        else {
            $res->status(404);
            $res->body('404 - File not found');
        }

        $res->finalize;
    }

    method call ( $env, @arg ) {

        $req = Plack::Request->new($env);

        if ( my ($rel) =
            $req->path_info eq '/' ? '/' : ( $req->path_info =~ /^\/(.*)$/g ) )
        {
            my $path =
              path(
                "$$self{root}/" . ( $rel =~ /\/$/g ? 'index.html' : $rel ) );
            return $self->get_path($path);
        }

        Plack::App::File::call( $self, @_ );
    }
};

builder {
    mount '/s/' => StaticSrv->new( root => './static' )->to_app;
    mount '/s/bulma.min.css' =>
      StaticSrv->new( file => './bulma/css/bulma.min.css' )->to_app;

    mount '/' => Frame::App::perldoc->new->to_app;
}

