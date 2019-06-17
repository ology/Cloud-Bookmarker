#!/usr/bin/env perl
use strict;
use warnings;

use Encode;
use File::Slurper 'read_text';
use JSON::MaybeXS;
use IO::Prompt::Tiny 'prompt';
use HTTP::Simple;

my $bookmarks = shift or die "Usage: perl $0 /some/bookmarks.json\n";

my $content = read_text($bookmarks);

my $data = decode_json( encode( 'utf-8', $content ) );
#use Data::Dumper;warn(__PACKAGE__,' ',__LINE__," MARK: ",Dumper$data);

my $host    = 'http://dev.ology.net:8870';
my $action  = 'add';
my $account = 'gene';

my $i = 0;

traverse($data);

sub traverse {
    my $struct = shift;

    if ( exists $struct->{uri} && $struct->{uri} =~ /^http/ ) {
        print ++$i, '. ', $struct->{title}, "\n\t", $struct->{uri}, "\n";

        my $title = $struct->{title};
        my $url   = $struct->{uri};

        my $response = postjson( "$host/$action", { account => $account, url => $url, title => $title, tags => '' } );
        print "\n", $response, "\n";

        sleep 3;
    }
    else {
        print "\n*** $struct->{title}:\n" unless $struct->{title} eq 'x';
    }

    for my $child ( @{ $struct->{children} } ) {
        next if $struct->{title} eq 'x';
        traverse($child);
    }
}
