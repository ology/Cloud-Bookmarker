#!/usr/bin/env perl
use strict;
use warnings;

use IO::Prompt::Tiny 'prompt';
use HTTP::Simple;

my $host   = 'http://localhost:5000';
my $action = 'add';

my $account = prompt('Account:');
my $title   = prompt('Title:');
my $url     = prompt('URL:');

my $response = postjson( "$host/$action", { account => $account, url => $url, title => $title } );

print "\n", $response, "\n";
