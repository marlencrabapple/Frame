# NAME

Frame - Bare-bones, real-time web framework (WIP)

# SYNOPSIS
```
use utf8;
use v5.36;

use Object::Pad;

class FrameApp :does(Frame) {
  method startup {
    my $r = $self->routes;

    $r->get('/', sub ($c) {
      $c->render('Frame works!')
    })
  }
}

FrameApp->new->to_psgi
```

# DESCRIPTION

Frame is

# AUTHOR

Ian P Bradley <ian.bradley@studiocrabapple.com>

# COPYRIGHT

Copyright 2023- Ian P Bradley

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
