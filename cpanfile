requires 'perl', 'v5.36';

requires 'Plack', '1.0050';
requires 'Plack::App::File';
requires 'Plack::Util';

requires 'Path::Tiny', '0.144';
requires 'List::AllUtils', '0.19';

requires 'IO::Async', '0.802';
requires 'IO::Async::SSL', '0.23';

requires 'Object::Pad', '0.77';
requires 'Future::AsyncAwait', '0.62';
requires 'Syntax::Keyword::Dynamically', '0.11';

requires 'Starlet', '0.31';
requires 'Gazelle', '0.49';
requires 'Net::Async::HTTP::Server', '0.13';
requires 'HTTP::Parser::XS', '0.17';
requires 'Server::Starter', '0.35';
requires 'Parallel::Prefork', '0.18';

requires 'DBI', '1.643';
requires 'DBD::SQLite', '1.72';
requires 'SQL::Abstract', '2.000001';

requires 'JSON::MaybeXS';
requires 'Cpanel::JSON::XS';
requires 'YAML::Tiny';
requires 'Text::Xslate', 'v3.5.9';

requires 'Net::SSLeay', '1.92';
requires 'IO::Socket::SSL', '2.075';
requires 'HTTP::Tinyish', '0.18';

on develop => sub {
  recommends 'App::perlimports', '0.000049';
  recommends 'Perl::Tidy', '20221112';
  recommends 'Perl::Critic', '1.144';
  recommends 'Perl::Critic::Community', 'v1.0.3';
  recommends 'Dist::Milla';
  recommends 'Carmel'
};

on test => sub {
    requires 'Test::More', '0.96'
}
