use Object::Pad;

package Frame::Server::Protocol;
class Frame::Server::Protocol :isa(IO::Async::Stream);

use utf8;
use v5.36;

use Carp;
use Scalar::Util 'weaken';

use HTTP::Parser::XS 'parse_http_request';

method on_read ($buf, $eof) {

}

method on_closed {

}

method _flush_reqs {
  
}

1