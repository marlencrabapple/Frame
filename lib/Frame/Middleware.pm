use Object::Pad ':experimental(:all)';

package Frame::Middleware;
role Frame::Middleware :does(Frame::Base);

use utf8;
use v5.40;

use Carp;

field $middleware :param = [];

method wrap ($app, %opts) {
  carp "Both \$app and \$opts{app} are set. \$app will only be used if "
     . "\$opts{app} is undefined. Unset one to disable this warning."
    if $app && $opts{app};

  my %args = (app => delete $opts{app} // $app, %opts);

  ref $self
    ? $self->{app} = $app
    : $app =~ /^Plack::(Component|Middleware)/
      ? $self->new({ %args })
      : $self->new( %args )
}

method call :required ($env, %opts);
