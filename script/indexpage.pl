#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

package Frame::App::Middleware;
class Frame::App::Middleware :does(Frame::Base);

use utf8;
use v5.44;

#use URI; my $li_contentstr = join "\n", map { $_ = path($_); my $uri = URI->new("https://cincotuf.lan:1415$_"); qq{<li><a href="$uri" target="_blank" title="} . escape_html($_) . qq{">} . escape_html($_->basename).  qq{</a></li> } } grep { $_ && $_ =~ /.+.(jpe?g|jxl|mp4|mov|m4v)$/ig } map { path($_)->lines_utf8({chomp => 1}) } glob('*teddy*'); path("$ENV{HOME}/teddybearosito-links-" . time . ".html")->spew_utf8(qq{<!doctype html>
#<html><head><meta charset="utf-8"></head><body><ul>$li_contentstr</ul></body></html> }) 

package Frame::App::Middleware::CLI;

use Getopt::Long qw'GetOptionsFromArray :config bundling auto_abbrev long_options_prefix=--?';

sub cli ($argv //= \@ARGV) {
  GetOptionsFromArray($argv, \%param, 'input|infile|indir:s@', 'pattern|search|regexp:s', );
}

cli(\@ARGV)
