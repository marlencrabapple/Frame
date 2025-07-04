requires 'perl', 'v5.40';

use utf8;
use v5.40;

requires 'Cwd';
requires 'Const::Fast';

use Cwd 'abs_path';
use Const::Fast;

const our $PWD => abs_path;

requires 'Plack';

requires 'Path::Tiny', '0.144';
requires 'List::AllUtils', '0.19';
requires 'meta', '0.013';
requires 'MIME::Types';
requires 'File::XDG';

requires 'IO::Async', '0.802';
requires 'IO::Async::SSL', '0.23';
requires 'IO::Socket::SSL', '2.074';
requires 'Net::SSLeay', '1.92';
requires 'Mozilla::CA', '20211001';
requires 'LWP::UserAgent', '6.67';
requires 'LWP::Protocol::https', '6.10';
requires 'Hash::Ordered';
requires 'Data::Printer';
requires 'Const::Fast';
requires 'Const::Fast::Exporter';
requires 'Time::Moment';
requires 'Time::HiRes';

requires 'Object::Pad', '0.808';
requires 'Future', '0.50';
requires 'Future::AsyncAwait', '0.62';
requires 'Syntax::Keyword::Dynamically', '0.11';
requires 'Syntax::Keyword::MultiSub';

# Which one do we stick with?
requires 'Feature::Compat::Try', '0.05';
requires 'Syntax::Keyword::Try';

requires 'Devel::StackTrace::WithLexicals', '2.01';

requires 'Net::Async::HTTP::Server', '0.14';
requires 'Net::Async::WebSocket', '0.13';
requires 'HTTP::Parser::XS', '0.17';
requires 'Server::Starter', '0.35';
requires 'Parallel::Prefork', '0.18';

requires 'Crypt::Argon2', '0.029';

requires 'DBI', '1.643';
requires 'DBD::SQLite', '1.72';
requires 'SQL::Abstract', '2.000001';

requires 'HTML::Escape', '1.11';
requires 'JSON::MaybeXS', '1.004004';
requires 'Cpanel::JSON::XS', '4.32';
requires 'TOML::Tiny';
requires 'Text::Xslate', 'v3.5.9';

requires 'Net::SSLeay', '1.92';
requires 'IO::Socket::SSL', '2.075';
requires 'HTTP::Tinyish', '0.18';
requires 'Net::Async::HTTP', '0.50';

requires 'Module::Refresh';

on develop => sub {
  recommends 'App::perlimports', '0.000049';
  recommends 'Perl::Tidy', '20221112';
  recommends 'Perl::Critic', '1.144';
  recommends 'Perl::Critic::Community', 'v1.0.3';
  requires 'Dist::Milla', 'v1.0.21';
  requires 'Carmel', 'v0.1.56';
  requires 'Plack::Middleware::Debug';
};

on test => sub {
  requires 'Test::More', '0.96'
};

requires 'HTTP::Parser::XS', '0.17';
requires 'Server::Starter', '0.35';
requires 'PadWalker'
