use Object::Pad;

package Frame::Db;
role Frame::Db :does(Frame::Base);

use utf8;
use v5.36;
# use autodie;

use SQL::Abstract;

field $sqla :reader;

ADJUST {
  $sqla = SQL::Abstract->new
}

method _dbh {
  DBI->connect_cached($self->app->config->{db}->@{qw/source username auth attr/})
}

method dbh :required;

1