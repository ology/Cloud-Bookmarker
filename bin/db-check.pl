#!/usr/bin/env perl
use strict;
use warnings;

use DBI;
use HTTP::Simple qw/ getstore is_error /;

my $account = shift or die "Usage: perl $0 account\n";

my $driver   = 'SQLite';
my $database = 'cloudbookmarker.db';
my $dsn      = "DBI:$driver:dbname=$database";
my $userid   = '';
my $password = '';
my $dbh      = DBI->connect( $dsn, $userid, $password, { RaiseError => 1 } ) or die $DBI::errstr;

my $sql = 'SELECT * FROM bookmarks WHERE account = ? ORDER BY id';
my $sth = $dbh->prepare($sql) or die $dbh->errstr;
$sth->execute($account) or die $dbh->errstr;

my $i = 0;

while( my @row = $sth->fetchrow_array ) {
    $i++;
#    print "$i. Trying $row[3] ...\n";
    my $status;
    eval { $status = getstore( $row[3], '/tmp/junk.html' ); };
    if ( is_error($status) ) {
        print 'ERROR: ', $row[3], "\n";
    };
}
