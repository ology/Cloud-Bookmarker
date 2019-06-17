#!/usr/bin/env perl
use strict;
use warnings;

use DBI;

my $driver   = 'SQLite';
my $database = 'cloudbookmarker.db';
my $dsn      = "DBI:$driver:dbname=$database";
my $userid   = '';
my $password = '';
my $dbh      = DBI->connect( $dsn, $userid, $password, { RaiseError => 1 } ) or die $DBI::errstr;

my $sql = <<'SQL';
CREATE TABLE users
   (id INT PRIMARY KEY NOT NULL,
    account TEXT NOT NULL,
    password TEXT NOT NULL)
SQL

#CREATE TABLE bookmarks
#   (id INT PRIMARY KEY NOT NULL,
#    account TEXT NOT NULL,
#    title TEXT NOT NULL,
#    url TEXT NOT NULL,
#    tags TEXT)
#SQL

my $r = $dbh->do($sql);

print $r < 0 ? $DBI::errstr : "Table created successfully\n";

$dbh->disconnect();
