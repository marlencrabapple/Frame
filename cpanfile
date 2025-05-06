requires 'perl', 'v5.40';

requires 'Cwd';
requires 'Const::Fast';
requires 'Const::Fast::Exporter';

use Const::Fast;
use Cwd 'abs_path';

const our $PWD => abs_path;

requires 'Plack', '1.0053',
  url => "file://$PWD/vendor/Plack-1.0053-TRIAL.tar.gz",
  dist => 'CRABAPP/Plack-1.0053-TRIAL.tar.gz';

requires 'Crypt::Argon2', '0.029';
requires 'HTTP::Parser::XS', '0.17';
requires 'Server::Starter', '0.35';
requires 'DBI', '1.643';
requires 'DBD::SQLite', '1.72';
requires 'SQL::Abstract', '2.000001';
requires 'List::AllUtils', '0.19';

requires 'Net::SSLeay';
requires 'Mozilla::CA';
requires 'HTTP::Tinyish';
requires 'Net::Async::HTTP', '0.50';

requires 'JSON::MaybeXS';
requires 'Cpanel::JSON::XS';

requires 'Object::Pad';
requires 'Future';
requires 'Future::AsyncAwait';
requires 'Syntax::Keyword::Dynamically';
requires 'Syntax::Keyword::MultiSub';
requires 'Syntax::Keyword::Try';

requires 'Time::Moment';
requires 'Time::HiRes';
requires 'HTML::Escape', '1.11';
requires 'TOML::Tiny';
requires 'Text::Xslate', 'v3.5.9';

requires 'Module::Refresh';

const our $DEVDEPENDS => sub {
  requires 'Devel::StackTrace::With::Lexicals';
  requires 'PadWalker';
  requires 'Minilla';
  requires 'Perl::Critic';
  requires 'Perl::Critic::Community';
  requires 'Perl::Tidy';
  requires 'App::perlimports';
  requires 'Carmel';
  requires 'Plack::Middleware::Debug';
};

on 'test' => sub {
    requires 'Test::More', '0.98'
}


