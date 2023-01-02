use Object::Pad;

package Frame::Example::Db;

use utf8;
use v5.36;
use autodie;

use DBI;
use DBD::SQLite::Constants ':dbd_sqlite_string_mode';
use Data::Dumper;

role Frame::Example::Db {
  field $dbh_old;
  field $config;

  method init_db {
    $self->app->config->{db}{attr} //= {};
    $self->app->config->{db}{attr}->@{qw/AutoCommit RaiseError sqlite_string_mode/}
      = (1, 1, DBD_SQLITE_STRING_MODE_UNICODE_STRICT);

    $self->dbh
  }

  method dbh {
    my $dbh = DBI->connect_cached($self->app->config->{db}->@{qw/source username auth attr/});

    if(!$dbh_old || $dbh != $dbh_old) {
      $dbh->do("PRAGMA foreign_keys = ON");
      $dbh_old = $dbh
    }

    $dbh
  }
}