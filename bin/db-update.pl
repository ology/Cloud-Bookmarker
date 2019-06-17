#!/usr/bin/env perl
use strict;
use warnings;

use Crypt::SaltedHash;
use DBI;

my $account = shift or die "Usage: perl $0 account passphrase\n";
my $pass    = shift;

my $driver   = 'SQLite';
my $database = 'cloudbookmarker.db';
my $dsn      = "DBI:$driver:dbname=$database";
my $userid   = '';
my $password = '';
my $dbh      = DBI->connect( $dsn, $userid, $password, { RaiseError => 1 } ) or die $DBI::errstr;

my ( $sql, $sth );

my $csh = Crypt::SaltedHash->new( algorithm => 'SHA-1' );
$csh->add($pass);
$pass = $csh->generate;

$sql = 'UPDATE users SET password = ? WHERE account = ?';
$sth = $dbh->prepare($sql) or die $dbh->errstr;
$sth->execute( $account, $pass ) or die $dbh->errstr;

$dbh->disconnect();
