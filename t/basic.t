use utf8;
use v5.40;

use Test::More;
use Syntax::Keyword::Try;

try {
    use Frame;
}
catch ($e) {
    use Data::Dumper;
    warn Dumper($e);
    say Dumper($e);
}

# replace with the actual test
ok 1;

done_testing;
