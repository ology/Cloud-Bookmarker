#!/usr/bin/env perl
use strict;
use warnings;

use Crypt::SaltedHash;
use DBI;

#use constant PATH     => 'public/accounts/';
#use constant EXT      => '.txt';
#use constant ENCODING => ':encoding(UTF-8)';
#use constant NOAUTH   => 'Not authorized';
#use constant UNKNOWN  => 'Unknown account';

my $account = shift or die "Usage: perl $0 account [passphrase]\n";
my $pass    = shift;

#my $file = _auth($account);

my $driver   = 'SQLite';
my $database = 'cloudbookmarker.db';
my $dsn      = "DBI:$driver:dbname=$database";
my $userid   = '';
my $password = '';
my $dbh      = DBI->connect( $dsn, $userid, $password, { RaiseError => 1 } ) or die $DBI::errstr;

my ( $sql, $sth );

if ( $pass ) {
    my $csh = Crypt::SaltedHash->new( algorithm => 'SHA-1' );
    $csh->add($pass);
    $pass = $csh->generate;

    $sql = 'INSERT INTO users (id, account, password) VALUES (?, ?, ?)';
    $sth = $dbh->prepare($sql) or die $dbh->errstr;
    $sth->execute( time(), $account, $pass ) or die $dbh->errstr;
}

#$sql = 'INSERT INTO bookmarks (id, account, title, url, tags) VALUES (?, ?, ?, ?, ?)';
#$sth = $dbh->prepare($sql) or die $dbh->errstr;
#open my $fh, '<' . ENCODING, $file or die "Can't read $file: $!";
#while ( my $line = readline($fh) ) {
#    chomp $line;
#    my ( $id, $title, $url, $tags ) = split /\t/, $line, 4;
#    $sth->execute( $id, $account, $title, $url, $tags ) or die $dbh->errstr;
#}
#close $fh or die "Can't close $file: $!";

$dbh->disconnect();

sub _auth {
    my $account = shift;

    die NOAUTH unless $account;

    my $file = PATH . $account . EXT;

    die UNKNOWN unless -e $file;

    return $file;
}
