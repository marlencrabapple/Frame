#!/usr/bin/env perl

use utf8;
use v5.40;

use lib 'lib';
use Frame::Util;

say Frame::Util->slugify($ARGV[0])

