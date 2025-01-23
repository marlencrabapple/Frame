package Frame::Request::Placeholder::Dummy;

use utf8;
use v5.36;

use parent 'Exporter';
use parent 'Frame::Request::Placeholder';

our @ISA;
push @ISA, qw(Tie::StdScalar Frame::Request::Placeholder);

our @EXPORT_OK = qw(allow);


use Carp;

our %whitelist = (); # 'foo::bar' => 'placeholder_key', ...
                     # local ${Frame::Request::Placeholder::Dummy::whitelist}{ 'Custom::Class' => 'placeholder_key' }
                     # local ${Frame::Request::Placeholder::Dummy::whitelist}{ \&some_sub => 'placeholder_key' }

sub FETCH ($self) {
  untie $self;
  croak Frame::Request::Placeholder::ribbit('Illegal usage of placeholder in inline route.')
    # unless (caller(1))[0] eq ...
  # warn Frame::Request::Placeholder::ribbit('Illegal usage of placeholder in inline route.')
}

sub allow ($scope, $placeholder_key) {
  # Not sure if this is necessary
  my @caller = caller(1);
  # ("$caller[0]"::whitelist){$scope} = $placeholder_key
}

1