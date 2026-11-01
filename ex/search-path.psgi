#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

package Frame::Example::SearchPath;

class Frame::Example::SearchPath : isa(Frame) : does(Frame::Base);

use utf8;
use v5.44;

# use JSON::MaybeXS;
# use TOML::Tiny;
use IO::Handle::Common;
use Path::Try;

field $root = './';
field $ofs;
field $follow;
field $recurse;
field $unrestricted;
field $mount = '/';
field $found = {};
field $fsize_human //= 1;

field $lines;
field $columns;
field $bytes;
field $cmp;
field $verbose;

# field $app { $self };

# field $json {
#     JSON::MaybeXS->new(
#         {
#             $self->is_utf8 ? ( utf8   => 1 ) : (),
#             $self->devmode ? ( pretty => 1 ) : ()
#         }
#     )
# };

method startup {
    my $r = $self->routes;

    my $mount = $self->under($mount, sub ($self) {

    });

    $r->get(
        "$mount/:path",
        sub ( $self, $path ) {
            my $searchpath =
              path( $path // $root )->relative($root)->realpath->exists;

            my $currfound;

            $searchpath->visit(
                sub( $path, $state ) {
                    $currfound //= $state;
                    if ($ofs) {
                        return if $path->parent->stat->dev != $path->stat->dev;
                    }

                    if ( $path->is_dir ) {
                        $found->{$searchpath}{dir}{ $path->realpath } =
                          { bytes => 0, path => $path, file => {} };
                    }
                    else {

                        my $print = 1;
                        defer {
                            my $size =
                              ( $human ? $path->size_human : $path->size );
                            if ( $print == 1 && ( !$bytes || $verbose ) ) {
                                my $line = sprintf '%-8s %s', $size,
                                  wrap( "", ( " " x 9 ), $path );

                                my $len = length( ( split /\n/, $line )[0] );
                                dmsg $line, $columns, $len
                                  if $len > $columns + 8;

                                # dmsg length $line;
                            }
                        };

                        if ($bytes) {
                            $cmp //= '>=';
                            my $cmp_evalstr =
                              "\$path->size $cmp \$bytes ? true : false";
                            my $bool = eval $cmp_evalstr;

                            dmsg $cmp, $cmp_evalstr, $bool;

                            $print = 0 unless $bool;

                            unless ($bool) {
                                $print = 0;
                                return $bool if $prune;
                            }
                        }

                        my $parentdata =
                          $found->{$searchpath}{dir}{ $path->parent->realpath };
                        $parentdata->{file}{ $path->realpath } = $path;

                        $parentdata->{bytes} += $path->size;
                        $found->{$searchpath}{bytes} += $path->size;

                    }
                },
                { follow => $follow, recursive => $recurse }
            );

            $self->res->status(200);
            $self->res->body($currfound);
        }
    );

    $self;
}

method is_utf8 {

}

method devmode {

}

package search_path;

use v5.44;

Frame::Example::SearchPath->new->to_app
