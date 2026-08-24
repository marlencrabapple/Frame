#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

package ip_pl;

class ip_pl;

use v5.40;

use lib 'lib';

use Frame::Util::IPClassExporter;
use Data::Printer;

# p @ARGV;
my $ip = ip(@ARGV);

# p $ip;
