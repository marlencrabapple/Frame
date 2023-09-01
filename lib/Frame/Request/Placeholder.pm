package Frame::Request::Placeholder;

use utf8;
use v5.38;

use Carp;
use Tie::Scalar;

our @ISA;
@ISA = qw(Tie::StdScalar);

sub ribbit {
  $_[0] // 'Placeholder values are read-only.'
}

sub STORE {
  warn ribbit
}

1