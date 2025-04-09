use Object::Pad qw(:experimental(:all));

package Frame::Db;
role Frame::Db :does(Frame::Base);

use utf8;
use v5.40;
# use autodie;

use Data::Printer;
use SQL::Abstract;
use Syntax::Keyword::Try;

APPLY ($mop) {
  try {
    p $ENV{config};
    
    my ($driver) = $ENV{config}->{db}{source} =~ /dbi:([^:]+):.+/;
      my $fn = "Frame/Db/$driver.pm";
    require "$fn";
    $mop->add_role("Frame::Db::$driver");
  }
  catch ($err) {
    p $err
  }
}

ADJUST {
  my $mop = Object::Pad::MOP::Class->for_caller;
  my ($driver) = $self->config->{db}{source} =~ /dbi:([^:]+):.+/;
      my $fn = "Frame/Db/$driver.pm";
    require "$fn";
  $mop->add_role("Frame::Db::$driver");
}

field $sqla = SQL::Abstract->new;

method _dbh {
  DBI->connect_cached($self->app->config->{db}->@{qw/source username auth attr/})
}

#method dbh :required;
