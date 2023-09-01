# use Object::Pad;

# package Frame::Request::Placeholder::Dummy;
# class Frame::Request::Placeholder::Dummy :isa(Frame::Request::Placeholder);

# use utf8;
# use v5.38;

# use Carp;
# use Tie::Scalar;

# our @ISA;
# push @ISA, 'Tie::Scalar';

# ADJUSTPARAMS {
#   tie $self->key, 'Frame::Request::Placeholder::Dummy';
#   tie $self->value, 'Frame::Request::Placeholder::Dummy';
# }

# method inline_error {
#   croak "Illegal usage of placeholder in inline route/stop."
# }

# sub FETCH {
#   __CLASS__->inline_error;
# }

# sub STORE {
#   __CLASS__->inline_error;
# }

package Frame::Request::Placeholder::Dummy;

use utf8;
use v5.38;

use parent 'Frame::Request::Placeholder';

our @ISA;
push @ISA, qw(Tie::StdScalar Frame::Request::Placeholder);

use Carp;

# our @ISA;
# @ISA = qw(Frame::Request::Placeholder);

# sub TIEARRAY {
#   @ISA = qw(Tie::StdArray);
# }

# sub TIEHASH {
#   @ISA = qw(Tie::StdHash);
# }

# sub TIESCALAR {
#   @ISA = qw(Tie::StdScalar);
# }

sub FETCH {
  warn Frame::Request::Placeholder::ribbit('Illegal usage of placeholder in inline route.')
}

1