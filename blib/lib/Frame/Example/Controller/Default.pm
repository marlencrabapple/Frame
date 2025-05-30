use Object::Pad;

package Frame::Example::Controller::Default;
class Frame::Example::Controller::Default :does(Frame::Controller);

use utf8;
use v5.36;

use Data::Dumper;

method list_items {
  my $sth = $self->app->dbh->prepare("SELECT * FROM items");
  $sth->execute;

  my @items;

  while(my $row = $sth->fetchrow_hashref) {
    push @items, $row
  }

  $self->render({ items => \@items })
}

method view_item($id) {
  my $sth = $self->app->dbh->prepare("SELECT * FROM items WHERE id=?");
  $sth->execute($id);
  
  $self->render($sth->fetchrow_hashref)
}

method add_item {
  ...
}

1