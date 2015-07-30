#!/usr/bin/perl

use DBI;
use File::Find;
use strict;

my $user = 'halkeye';
my $password = '';
my $dsn = 'dbi:Pg:dbname=halkjockey';

my $dbh = DBI->connect($dsn, $user, $password,
	{ RaiseError => 1, AutoCommit => 1 });

$dbh->do("DELETE FROM songs");
my $sql = "INSERT INTO songs (filename) VALUES(?)";

print "$0 dirname [..]\n" unless @ARGV;

my $sth = $dbh->prepare($sql);
for my $dir ( @ARGV ) 
{
	next unless -d $dir;
	print "Adding directory: $dir\n";
	
	find(
		sub {
			return unless /\.mp3$/;
			my $file = "$File::Find::dir/$_";
#$file =~ s/\'/\\\'/g;
#			return unless dirname($file) eq $dir;
		
			print "Added: $file\n";
			$sth->execute($file);
			},
			$dir
	);
}

