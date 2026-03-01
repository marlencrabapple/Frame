requires 'Const::Fast';
requires 'Const::Fast::Exporter';
requires 'Cpanel::JSON::XS';
requires 'Crypt::Argon2';
requires 'Cwd';
requires 'DBD::SQLite';
requires 'DBI';
requires 'Devel::StackTrace::WithLexicals';
requires 'File::XDG';
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
requires 'List::AllUtils';
requires 'meta';
requires 'MIME::Types';
requires 'Module::Build::Tiny';
requires 'Module::Refresh';
requires 'Mozilla::CA';
requires 'Net::Async::HTTP';
requires 'Net::Async::HTTP::Server';
requires 'Net::Async::WebSocket';
requires 'Net::SSLeay';
requires 'Object::Pad';
requires 'PadWalker';
requires 'Parallel::Prefork';
requires 'Path::Tiny';
requires 'Plack', '==1.0051';
requires 'Server::Starter';
requires 'SQL::Abstract';
requires 'Syntax::Keyword::Dynamically';
requires 'Syntax::Keyword::Try';
requires 'Test::More';
requires 'Test::Pod';
requires 'Text::Xslate';
requires 'Time::HiRes';
requires 'Time::Moment';
requires 'TOML::Tiny';

on develop => sub {
  recommends 'Perl::Tidy', '20221112';
  recommends 'Perl::Critic', '1.144';
  recommends 'Perl::Critic::Community', 'v1.0.3';
  requires 'Dist::Milla', 'v1.0.21';
  requires 'Plack::Middleware::Debug';
  recommends 'Archive::Tar::Wrapper';
};

on test => sub {
  requires 'Test::More', '0.96';
  requires 'Test::Pod';
}

