#!/usr/bin/env perl
use strict;
use warnings;

use DBI;
use Netscape::Bookmarks;

my $account = shift or die "Usage: perl $0 account\n";

my $bookmarks = Netscape::Bookmarks::Category->new({
    add_date    => time(),
    description => 'Imported from Cloudbookmarker',
    folded      => 0,
    title       => 'Root',
});

my $driver   = 'SQLite';
my $database = 'cloudbookmarker.db';
my $dsn      = "DBI:$driver:dbname=$database";
my $userid   = '';
my $password = '';
my $dbh      = DBI->connect( $dsn, $userid, $password, { RaiseError => 1 } ) or die $DBI::errstr;

my $sql = 'SELECT * FROM bookmarks WHERE account = ? ORDER BY id';
my $sth = $dbh->prepare($sql) or die $dbh->errstr;
$sth->execute($account) or die $dbh->errstr;

while( my @row = $sth->fetchrow_array ) {
    my $link = Netscape::Bookmarks::Link->new({
        ADD_DATE => $row[0],
        TITLE    => $row[2],
        HREF     => $row[3],
    });
    $bookmarks->add($link);
}

print $bookmarks->as_string, "\n";

