use Object::Pad;

package Frame::PW;
role Frame::PW;

use utf8;
use v5.40;

use Carp;
use Crypt::Argon2 qw/argon2id_pass argon2_verify/;

field %users :inheritable = ();

method add_pass :common ($user, $pass) {
  my $salt = get_random(32);
  my $hashpass = argon2id_pass($pass, $salt, 3, '64M', `echo $(nproc)`, 32);
  store_pass($user, $hashpass)
}

method check_pass :common ($user, $pass) {
  argon2_verify($pass, get_hashed_pass($user))
}

method store_pass :common ($user, $hashpass, $update = 0) {
  $update != 1 && defined $users{$user} && die "User already exists";
  $class->users{$user} = $hashpass
}

method get_hashed_pass :common ($user) {
  $class->users{$user} || croak "No user matching '$user' in user db"
}
