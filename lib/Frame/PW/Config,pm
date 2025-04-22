use Object::Pad qw(:experimental(:all));

package Frame::PW::Config;
role Frame::PW::Config : does(Frame::PW);

use utf8;
use v5.40;

use Path::Tiny;
use Const::Fast;

const our $DEBUG = 1;#$ENV{FRAME_DEBUG} // $ENV{DEBUG};

#field %users : inheritable = ();

#APPLY {
#    const our $userdb_path =
#      path( $ENV{SRVDIR_USERDB} || "$ENV{HOME}/.srvdir/userdb.txt" );

#    const our $DEBUG = $ENV{FRAME_DEBUG} // $ENV{DEBUG};

#    if ( !-e $userdb_path ) {
#        my $user = getpwent;
#        my $pass = `pwgen 32`;

#        path( "$ENV{HOME}/srvdir_newuser" . time )->spew_utf8;

#        Frame::PW::add_pass( $user, $pass );

#        $userdb_path->spew_utf8( "$user:" . Frame::PW::get_hashed_pass($user) );
#    }
#    else {
#        foreach my $line ( $userdb_path->lines_utf8 ) {
#            my ( $user, $hashpass ) = ( split /=/, $line );
#            Frame::PW->store_pass( $user, $hashpass );
#        }
#    }
#}
