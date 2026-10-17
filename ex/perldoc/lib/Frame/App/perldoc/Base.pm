use Object::Pad ':experimental(:all)';

package Frame::App::perldoc::Base;
role Frame::App::perldoc::Base;

use utf8;
use v5.44;

use IPC::Nosh;
use IO::Handle::Common;
use Const::Fast;
use builtin;

use parent 'Exporter';
use vars qw'@EXPORT @EXPORT_OK';

@EXPORT = ( qw'refstr as_array', @IO::Handle::Common::EXPORT );

APPLY($class_mop) {
    dmsg $class_mop;
    __PACKAGE__->import;
};

ADJUST : params (%param) {
    dmsg $self, \%param;
    __PACKAGE__->import;
};

sub refstr ($var) {
    reftype $var // '';
}

sub as_list ($var) {
    if ( my $type = reftype $var ) {
        fatal if $type ne 'ARRAY';
        return @$var;
    }
    $var;
}
