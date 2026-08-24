
use v5.40;
use utf8;

use Path::Try;

my $state = $searchdir->visit(sub ($path, $state) { return undef if $path->is_dir; $$state{$path->size} = $path->realpath; say $path->size_h . (join "", ('…’ x 8)) .  $path->realpath }, {recurse => 1}))
