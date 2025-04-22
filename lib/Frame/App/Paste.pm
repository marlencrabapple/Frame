use Object::Pad qw(:experimental(:all));

package Frame::App::Paste;

class Frame::App::Paste : isa(Frame::Controller::Default)
  : does(Frame);

use utf8;
use v5.40;

use Path::Tiny;
use DBD::SQLite;
use Text::Xslate;
use Time::Moment;
use SQL::Abstract;
use DBIx::Connector;

field $config;

method startup {
    my $r = $self->routes;
    $config = $self->config;

    $r->get( '/p/:id', 'get_paste' );
    $r->post( 'paste', 'post_paste' );
}

method get_paste ($id) {

}

method post_paste {

}

method delete_paste ($id) {

}
