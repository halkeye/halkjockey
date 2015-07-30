#!/usr/bin/perl

use DBI;
use lib('lib');
use Icecast::Playlist;
use strict;


my $lastplayed = 'etc/lastplayed';
my $shout_requests = 'etc/shout.requests';
my $shout_playlist_rand = 'etc/playlist.rand';
my $shout_playlist_orig = 'etc/playlist.orig';

my $user = 'halkeye';
my $password = '';
my $dsn = 'dbi:Pg:dbname=halkjockey';

my $dbh = DBI->connect($dsn, $user, $password,
	{ RaiseError => 1, AutoCommit => 1 });

my $sth;

# Function called to initialize your perl environment.
# Should return 1 if ok, and 0 if something went wrong.

sub ices_perl_initialize {
	print "Perl subsystem Initializing:\n";
	return 1;
}

# Function called to shutdown your perl enviroment.
# Return 1 if ok, 0 if something went wrong.
sub ices_perl_shutdown {
	print "Perl subsystem shutting down:\n";
}

# Function called to get the next filename to stream. 
# Should return a string.
sub ices_perl_get_next {
	my @goodqueue = ();
	
	print "Perl subsystem quering for new track:\n";
	
# Here we make sure the request queue exists, otherwise we'll skip
# # it and do a random song.

	@goodqueue = get_playlist();

	my $sql = "UPDATE songs SET last_play=NOW() WHERE id=?";
	$sth = $dbh->prepare($sql);
	use Data::Dumper;
	my $id = $goodqueue[0]{'id'}+0;
	$sth->execute($id);
	my $temp = $goodqueue[0]{'filename'};
	chomp ($temp);
	return "$temp";
	
}

# Function used to put the current line number of
# the playlist in the cue file. If you don't care
# about cue files, just return any integer.
# It should, however, return 0 the very first time
# and then never 0 again. This is because the metadata
# updating function should be delayed a little for
# the very first song, because the icecast server may
# not have accepted the stream yet.
sub ices_perl_get_current_lineno {
	print "here\n";
	return 0;
}

1;
