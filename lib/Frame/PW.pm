use Object::Pad qw(:experimental(:all));

package Frame::PW;
role Frame::PW;

use utf8;
use v5.40;

use Carp;
use POSIX;
use Const::Fast;
use Net::SSLeay;
use Crypt::Argon2 qw/argon2id_pass argon2_verify/;

const our @UNAME = POSIX::uname(); 
const our $NPROC = ``;

APPLY {
  die "Required binary pwgen not found in PATH." unless system(qw(which pwgen));
  dmsg @UNAME if $ENV{DEBUG};
}

field %users : inheritable = ();

method add_pass ($user, $pass) {
  my $salt = get_random(32);
  my $hashpass = argon2id_pass($pass, $salt, 3, '64M', `echo $(nproc)`, 32);
  store_pass($user, $hashpass)
}

method hashpass :common ($pw = `pwgen -s 32`) {
  die "Error generating password hash/no password provided: $?" unless $pw;

  my $salt;
  my $rv = Net::SSLeay::RAND_bytes($salt, 32);

  die "Error generating random salt: $rv" unless $rv == 1 && defined $salt;

  argon2id_pass($pw, $salt, '4', '32M', $NPROC, 16)
}

method check_pass ( $user, $pass ) {
    argon2_verify( $pass, get_hashed_pass($user) );
}

method store_pass ( $user, $hashpass, $update = 0 ) {
    $update != 1 && defined $users{$user} && die "User already exists";
    $users{$user} = $hashpass;
}

method get_hashed_pass ($user) {
    $users{$user} || croak "No user matching '$user' in user db";
}
