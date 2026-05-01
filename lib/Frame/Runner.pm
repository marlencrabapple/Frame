use Object::Pad ':experimental(:all)';

package Frame::Runner;

class Frame::Runner : isa(Plack::Runner) : does(Frame::Base);

use utf8;
use v5.40;

use lib 'lib';

use List::Util     qw(none all mesh);
use Const::Fast    qw( const );
use Path::Tiny     qw( path );
use Getopt::Long   qw(GetOptionsFromArray :config no_ignore_case);
use Plack::Runner  ();
use Plack::Builder ();
use Cwd            qw( abs_path getcwd );

use IPC::Nosh;
use IPC::Nosh::Common;

const our $sockscheme_re => qr'^unix://';
