use utf8;
use v5.42;

#use Frame;
use Test::More;

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
