use Object::Pad;

package Frame::Db::SQLite;
role Frame::Db::SQLite :does(Frame::Db);

use utf8;
use v5.36;
# use autodie;

use DBI;
use DBD::SQLite::Constants ':dbd_sqlite_string_mode';
use Hash::Util qw(unlock_hashref_recurse lock_hashref_recurse);

field $dbh_old;

ADJUST {
  my $config = $self->app->config->{db};
  unlock_hashref_recurse($config);

  $$config{attr}->@{qw/AutoCommit RaiseError sqlite_string_mode/}
    = (1, 1, DBD_SQLITE_STRING_MODE_UNICODE_STRICT);

  lock_hashref_recurse($config)
}

method dbh {
  my $dbh = $self->_dbh;

  if(!$dbh_old || $dbh != $dbh_old) {
    $dbh->do("PRAGMA foreign_keys = ON");
    $dbh_old = $dbh
  }

  $dbh
}

1