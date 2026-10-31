#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

package search_path;

class search_path : isa(Frame);

use utf8;
use v5.44;

use JSON::MaybeXS;
use TOML::Tiny;
use IO::Handle::Common;
use Path::Try;

field $root = './';
field $ofs;
field $follow;
field $recurse;
field $unrestricted;
field $mount = '/';

field $app { $self };

field $json {
    JSON::MaybeXS->new(
        {
            $self->is_utf8 ? ( utf8   => 1 ) : (),
            $self->devmode ? ( pretty => 1 ) : ()
        }
    )
};

method startup {
    my $r = $self->routes;

    $r->get(
        "$mount/:path",
        sub ( $self, $path ) {
            my $searchpath =
              path( $path // $root )->relative($root)->realpath->exists;

            my $content;

            $searchpath->visit(
                sub( $path, $state ) {
									$content{}
                },
                { follow => $follow, recursive => $recurse }
              )

              $self->res->status(200) $self->res->body($content);
        }
    );

    $self;
}

method is_utf8 {

}

method devmode {

}

search_path->new->to_app
