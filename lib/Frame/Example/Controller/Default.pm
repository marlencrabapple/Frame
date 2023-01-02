use Object::Pad;

package Frame::Example::Controller::Default;

use utf8;
use v5.36;
use autodie;

use Data::Dumper;

class Frame::Example::Controller::Default :does(Frame::Controller) {
  method list_items {
    $self->render('Hello World')
  }

  method view_item($id) {
    say Dumper($self, $id);
    my $sth = $self->app->dbh->prepare("SELECT * FROM items WHERE id=?");
    $sth->execute($id);
    $self->render($sth->fetchrow_hashref)
  }
}