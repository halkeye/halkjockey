#! /usr/bin/perl

package Icecast;

use Icecast::Radio;
use Icecast::Playlist;
use HTML::ProgressBar;
use MP3::Info;
use strict;

my @playlist = Icecast::Playlist::get_playlist();

my $count = 0;
foreach my $line (@playlist)
{
	my %tmp = ();
	
	print $$line{'filename'};

	my $tag = get_mp3tag($$line{'filename'}) || undef;
	next unless $tag;
#	error("No ID3 tag info") unless $tag;
	%tmp = ( playing=>($count == 0),
			next=>($count == 1),
			artist=>$tag->{ARTIST}, 
			title=>$tag->{TITLE},
			time=>$tag->{TIME},
			min=>$tag->{MM},
			sec=>$tag->{SS},
	) if (defined $tag);
#	push (@requests, \%tmp);
	$count++;
}

$count = 1;
print HTML::ProgressBar::prepare(1);;
print "\n";

1;
