use utf8;
use v5.40;

use subs qw'requires recommends on';

requires 'perl', 'v5.40';

requires 'Plack';

requires 'IPC::Nosh', '0.01.4', dist => "CRABAPP/IPC-Nosh-0.01.4-TRIAL.tar.gz";

requires 'IO::Handle::Common', '0.01_2',
  dist => "CRABAPP/IO-Handle-Common-0.01_2-TRIAL.tar.gz";

requires 'Const::Fast';
requires 'Const::Fast::Exporter';
requires 'Cpanel::JSON::XS';
requires 'Crypt::Argon2';
requires 'Cwd';

requires 'DBD::SQLite';
requires 'DBI';

requires 'Devel::StackTrace::WithLexicals';

requires 'File::ConfigDir';

requires 'Future';
requires 'Future::AsyncAwait';

requires 'Hash::Ordered';

requires 'HTML::Escape';
requires 'HTTP::Parser::XS';
requires 'HTTP::Tinyish';

requires 'IO::Async';
requires 'IO::Async::SSL';
requires 'IO::Socket::SSL';

requires 'JSON::MaybeXS';

requires 'List::Util';

requires 'meta';

requires 'MIME::Types';

requires 'Module::Refresh';
requires 'Mozilla::CA';

requires 'Net::Async::HTTP';
requires 'Net::Async::HTTP::Server';
requires 'Net::Async::WebSocket';
requires 'Net::SSLeay';

requires 'Object::Pad';
requires 'PadWalker';

requires 'Parallel::Prefork';

requires 'Path::Try';

requires 'Server::Starter';

requires 'SQL::Abstract';

requires 'Syntax::Keyword::Dynamically';
requires 'Syntax::Keyword::Try';

requires 'Text::Xslate';
requires 'Time::HiRes';
requires 'Time::Moment';
requires 'TOML::Tiny';

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

