#!/usr/bin/perl

use lib('lib');
use Icecast::Playlist;
use strict;

my $lastplayed = 'etc/lastplayed';
my $shout_requests = 'etc/shout.requests';
my $shout_playlist_rand = 'etc/playlist.rand';
my $shout_playlist_orig = 'etc/playlist.orig';

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

	@goodqueue = Icecast::Playlist::get_playlist();
	my $song = $goodqueue[0];
	Icecast::Playlist::play($song);
    
	chomp ($song->{'filename'});
	return $song->{'filename'};
	
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
	return 0;
}

1;
