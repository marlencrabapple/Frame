use Object::Pad qw(:experimental(:all));

package Frame::PW;
role Frame::PW : does(Frame::Base);

use utf8;
use v5.40;

use Carp;
use Crypt::Argon2 qw/argon2id_pass argon2_verify/;

field %users : inheritable = ();

method add_pass ( $user, $pass ) {
    my $salt     = get_random(32);
    my $hashpass = argon2id_pass( $pass, $salt, 3, '64M', `echo $(nproc)`, 32 );
    store_pass( $user, $hashpass );
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
