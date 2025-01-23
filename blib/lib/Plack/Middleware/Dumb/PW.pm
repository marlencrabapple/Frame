# use Object::Pad;

# package Plack::Middleware::Dumb::PW;
# class Plack::Middleware::Dumb::PW :does(Frame::PW);

# use utf8;
# use v5.40;

# use Path::Tiny;

# inherit Frame::PW '%users';

# field $userdb_file;
# field $userdb_path :param = $ENV{SRVDIR_USERDB} || "$HOME/.srvdir/userdb.txt";

# ADJUST {
#   say "__CLASS__:" .  __CLASS__;

#   if (! -e $userdb_path) {
#     $user = getpwent;
#     $pass = `pwgen 32`;

#     path("$HOME/srvdir_newuser" . time)->spew_utf8;
    
#     Frame::PW::add_pass($user, $pass);
#     `touch $userdb_path`;
    
#     $userdb_file = path($userdb_path);
#     $userdb_file->spew_utf8("$user:" . Frame::PW::get_hashed_pass($user))
#   }
#   else {
#     $userdb_file = path($userdb_path) unless ref $userdb_file eq 'Path::Tiny';

#     foreach my $line in ($userdb_file->lines_utf8) {
#       my ($user, $hashpass) = (split '=', $line);
#       Frame::PW::store_pass($user, $hashpass)
#     }
#   }
# }