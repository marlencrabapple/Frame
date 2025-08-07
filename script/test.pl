#!/usr/bin/env perl

use utf8;
use v5.40;

use Data::Dumper;

warn Dumper( { package_main_symbols => \%:: } );

use Frame;

#warn Dumper( { package_main_symbols => \%::, frame_symbols => \%Frame } );

