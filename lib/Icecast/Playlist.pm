#!/usr/bin/perl
#

package Icecast::Playlist;
use DBI;
use MP3::Info;
use File::Basename;
use strict;


my $dbh;
my $base_path = '/var/www/icecast.halkeye.net/';
my %MP3_CACHE;

BEGIN
{
	my $user = 'halkeye';
	my $password = '';
	my $dsn = 'dbi:Pg:dbname=halkjockey';
	$dbh = DBI->connect($dsn, $user, $password,
	{ RaiseError => 1, AutoCommit => 1 });
	%MP3_CACHE = ();
	
	eval { use MP3::Info; };
	die "You need to install MP3::Info" if ($_);
}

use MP3::Info;


sub union_hash($$)
{
        my ($hash_a, $hash_b) = @_;
        my %union = ();

        if (defined $hash_a)
        {
            foreach my $key (keys %{$hash_a})
            {
                    $union{$key} = $hash_a->{$key};
            }
        }
        
        if (defined $hash_b)
        {
            foreach my $key (keys %{$hash_b})
            {
                $union{$key} = $hash_b->{$key};
            }
        }

        return {%union};
}

sub get_playlist
{
	my @playlist;
	
	my $sth = $dbh->prepare("SELECT song_id as id, filename, COUNT(user_id) as rank FROM requests " .
		"LEFT JOIN songs ON song_id = id " .
		"GROUP BY song_id, filename " .
		"ORDER BY rank DESC");
	$sth->execute();
	
	my @ids;
	my $row;
	
	my $count = 0;
	while ($row = $sth->fetchrow_hashref)
	{
            my $file = $row->{'filename'};
            $file =~ s/\\\'/\'/g;
            my $info = get_fileinfo($file,$row->{'id'});
            $info->{'rank'} = $row->{'rank'};
            $info->{'count'} = $count+1;
            $info->{'playing'} = 0;
            $info->{'next'} = !$count;
            push (@playlist, \%{$info});
            $count++;
	}
	
	my $sql = "SELECT id, filename, 0 as rank FROM songs ORDER BY last_play ASC LIMIT 5";
	$sth = $dbh->prepare($sql);
	$sth->execute();
	while ($row = $sth->fetchrow_hashref)
	{
            my $file = $row->{'filename'};
            $file =~ s/\\\'/\'/g;
            my $info = get_fileinfo($file,$row->{'id'});
            $info->{'rank'} = $row->{'rank'};
            $info->{'count'} = $count+1;
            $info->{'playing'} = 0;
            $info->{'next'} = !$count;
            push (@playlist, \%{$info});
            $count++;
	}

    
	return @playlist;	
}

sub get_allplaylist
{
	my @playlist;
	
	my $sql = "SELECT id, filename, 0 as rank FROM songs ORDER BY filename ASC";
	my $sth = $dbh->prepare($sql);
    my $row;
	$sth->execute();
    my $count = 0;
	while ($row = $sth->fetchrow_hashref)
    {
            my $file = $row->{'filename'};
            my $info = get_fileinfo($file,$row->{'id'});
            $info->{'rank'} = $row->{'rank'};
            $info->{'count'} = $count;
            push (@playlist, \%{$info});
            $count++;
    }

    
	return @playlist;	
}

sub play($)
{
        my $playlist = shift;
        my $song = $playlist->{'filename'};
        my $id = $playlist->{'id'};
        
        print "We are now playing $song\n";
        
        my $sql = 'UPDATE songs SET last_play=NOW(), requested=requested+(SELECT COUNT(*) FROM requests WHERE song_id=?) WHERE id=?;';
        $sql .=   'DELETE FROM requests WHERE song_id=?;';
        my $sth = $dbh->prepare($sql);
        $sth->execute($id, $id, $id);       
}

sub get_top10
{
        my $amount = shift || 10;
# sanitize
        $amount = $amount + 0;
        my $sql = "SELECT id, filename, requested+(SELECT COUNT(*) FROM requests WHERE song_id=id) as requested, filename FROM songs ORDER BY requested DESC, last_play, id LIMIT ?";
        my $sth = $dbh->prepare($sql);
        $sth->execute($amount);
        
        my @top10 = ();
        my $row;
        my $count = 1;
        
        while ($row = $sth->fetchrow_hashref)
        {
                my $tmp = get_fileinfo($row->{'filename'}, $row->{'id'});
                $tmp->{'rank'} = $count;
                $tmp->{'times'} = $row->{'requested'};
                $count++;
                push (@top10, \%{$tmp});
        }
        return @top10;
}

sub request($)
{
        my $id = (shift)+0;
        my $sql = "INSERT INTO requests (user_id, song_id) VALUES(?,?)";
        my $sth = $dbh->prepare($sql);
        $sth->execute(0, $id);
        $sql = "SELECT filename FROM songs WHERE id=?";
        $sth = $dbh->prepare($sql);
        $sth->execute($id);
      
        my $row = $sth->fetchrow_hashref;
        return undef unless ($row);
        
        return get_fileinfo($row->{'filename'}, $id);
}

sub get_fileinfo($$)
{
        my ($file, $id) = @_;
        if (defined $MP3_CACHE{$file})
        {
                # make sure id is up to date
                $MP3_CACHE{$file}->{'id'} = $id;
                return $MP3_CACHE{$file};
        }
        my $tag = get_mp3tag($file) || undef;
        my $info = get_mp3info($file) || undef;
        my $info = union_hash($tag, $info);
        $info->{'album'} = $info->{ALBUM} || dirname($file);
        $info->{'artist'} = $info->{ARTIST} || 'Unknown';
        $info->{'title'} = $info->{TITLE} || basename($file);
        $info->{'time'} = $info->{TIME} || 'Unknown';
        $info->{'bitrate'} = $info->{BITRATE} || 0;
        $info->{'id'} = sprintf("%04d", $id);
        $info->{'filename'} = $file;
        $info->{'min'} = sprintf("%2d", $info->{MM}) || -1;
        $info->{'sec'} = sprintf("%2d", $info->{SS}) || -1,
        $MP3_CACHE{$file} = \%{$info}; #{%tmp};
        return \%{$info};
}
END
{
	$dbh->disconnect;
}
1;

