use utf8;
use v5.44;

use subs qw'requires recommends on';

requires 'perl', 'v5.40';

requires 'Plack';

requires 'perl', 'v5.44';
requires 'Const::Fast';

use Const::Fast;

sub distname ($pkgname) {
    const my $pkg2dist => qr/::/;
    ( $pkgname =~ s/$pkg2dist/-/rg );
}

const our %pinned => (
    CRABAPP => {
        'Path::Try'          => '0.01_03',
        'IO::Handle::Common' => '0.01_06',
        'IPC::Nosh'          => '0.01_04',
        'Adjust::Params'     => '0.01_06'
    }
);

foreach my ( $author, $modules ) (%pinned) {
    foreach my ( $name, $ver ) (%$modules) {
        requires $name, $ver,
          dist => "$author/" . distname($name) . "-$ver-TRIAL.tar.gz";
    }
}

requires 'Const::Fast';
requires 'Const::Fast::Exporter';
requires 'Cpanel::JSON::XS';
requires 'Crypt::Argon2';
requires 'Cwd';

requires 'DBD::SQLite';
requires 'DBI';
requires 'SQL::Abstract';

requires 'Future';
requires 'Future::AsyncAwait';

requires 'Hash::Ordered';

requires 'HTML::Escape';
requires 'HTTP::Parser::XS';

requires 'IO::Async';
requires 'IO::Async::SSL';
requires 'IO::Socket::SSL';

requires 'File::ConfigDir';
requires 'Net::SSLeay';
requires 'Object::Pad';
requires 'List::Util';
requires 'meta';
requires 'Time::HiRes';
requires 'Time::Moment';
requires 'Syntax::Keyword::Dynamically';
requires 'Syntax::Keyword::Try';

requires 'MIME::Types';

requires 'Mozilla::CA';

requires 'Net::Async::HTTP';
requires 'Net::Async::HTTP::Server';
requires 'Net::Async::WebSocket';
requires 'Parallel::Prefork';
requires 'Server::Starter';

requires 'TOML::Tiny';
requires 'JSON::MaybeXS';
requires 'Text::Xslate';

on 'develop' => sub {
    recommends 'Perl::Tidy', '20221112';
    recommends 'Perl::Critic';
    recommends 'Perl::Critic::Community';
    requires 'Dist::Milla';
    requires 'Module::Build::Tiny';
    requires 'Plack::Middleware::Debug';
    recommends 'Plack::Middleware::REPL';
    recommends 'Archive::Tar::Wrapper';
    recommends 'Carton';
};

on 'test' => sub {
    requires 'Test::More';
    requires 'Test::Pod';
}

