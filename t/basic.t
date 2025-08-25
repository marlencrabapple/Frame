
use utf8;
use v5.40;

#use Frame;
use Test::More;
use Syntax::Keyword::Try;

try {
    use Data::Dumper;
    warn Dumper({ caller => [[caller 0], [caller]] });
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
