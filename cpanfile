requires 'perl', 'v5.40';

requires 'Plack', '1.0052',
  dist => 'CRABAPP/Plack-1.0052-TRIAL.tar.gz';

requires 'Path::Tiny', '0.144';
requires 'List::AllUtils', '0.19';

requires 'IO::Async', '0.802';
requires 'IO::Async::SSL', '0.23';
requires 'IO::Socket::SSL', '2.074';
requires 'Net::SSLeay', '1.92';
requires 'Mozilla::CA', '20211001';
requires 'LWP::UserAgent', '6.67';
requires 'LWP::Protocol::https', '6.10';

requires 'Object::Pad', '0.808';
requires 'Future', '0.50';
requires 'Future::AsyncAwait', '0.62';
requires 'Syntax::Keyword::Dynamically', '0.11';

# Which one do we stick with?
requires 'Feature::Compat::Try', '0.05';
requires 'Syntax::Keyword::Tiny';

requires 'namespace::autoclean', '0.31';

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
requires 'YAML::Tiny', '1.73';
requires 'Text::Xslate', 'v3.5.9';

requires 'Net::SSLeay', '1.92';
requires 'IO::Socket::SSL', '2.075';
requires 'HTTP::Tinyish', '0.18'; # TODO: Write a HTTP::Tiny compatible wrapper for Net::Async::HTTP

requires 'Net::Async::HTTP', '0.50';

on develop => sub {
  recommends 'App::perlimports', '0.000049';
  recommends 'Perl::Tidy', '20221112';
  recommends 'Perl::Critic', '1.144';
  recommends 'Perl::Critic::Community', 'v1.0.3';
  recommends 'Dist::Milla', 'v1.0.21';
  recommends 'Carmel', 'v0.1.56'
};

on test => sub {
  requires 'Test::More', '0.96'
};

requires 'HTTP::Parser::XS', '0.17';
requires 'Server::Starter', '0.35';
