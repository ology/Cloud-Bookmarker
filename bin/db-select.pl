#!/usr/bin/env perl
use strict;
use warnings;

use DBI;

use constant PATH     => 'public/accounts/';
use constant EXT      => '.txt';
use constant ENCODING => ':encoding(UTF-8)';

my $account = shift or die "Usage: perl $0 123\n";

my $driver   = 'SQLite';
my $database = 'cloudbookmarker.db';
my $dsn      = "DBI:$driver:dbname=$database";
my $userid   = '';
my $password = '';
my $dbh      = DBI->connect( $dsn, $userid, $password, { RaiseError => 1 } ) or die $DBI::errstr;

my $sql = 'SELECT * FROM bookmarks WHERE account = ? ORDER BY id';
my $sth = $dbh->prepare($sql) or die $dbh->errstr;
$sth->execute($account) or die $dbh->errstr;

my %seen;

while( my @row = $sth->fetchrow_array ) {
    print join( ',', @row ), "\n";
    $seen{ $row[3] }++;
}

$dbh->disconnect();

for my $k ( keys %seen ) {
    next if $seen{$k} <= 1;
    print "$k\n";
}
