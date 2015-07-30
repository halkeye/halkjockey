#!/usr/bin/perl

use strict;

package Icecast::Radio;

use Apache::Request;
use Apache::Constants qw(:common REDIRECT MOVED SERVER_ERROR);

use CGI qw(:all);
use Data::Dumper;
use HTML::Template;
use File::Find;
use File::Basename;
use Icecast::Playlist;
use HTML::ProgressBar;

my @letters;
my @errors = ();
my $base_path;

$SIG{__WARN__} = sub { error($_[0]); };
$SIG{__DIE__} = sub { error($_[0]); };

BEGIN
{
       $base_path = '/var/www/icecast.halkeye.net/';

       @letters = ();
       my %let = ( letter=>'0', name=>'0-9' );
       push (@letters, \%let );
       foreach my $letter ('a'..'z') 
       {
               my %let = ( letter=>$letter, name=>uc($letter) );
               push (@letters, \%let);
       }
       
       print STDERR "Pre-loading HTML Templates...\n";
       find(
                       sub {
                       return unless /\.tmpl$/;
                       HTML::Template->new(
                               filename => "$File::Find::dir/$_",
                               cache => 1,
                               cache_debug => 0,
                               path=> $base_path . 'tmpl/',
                               );
                       },
                       $base_path . 'tmpl/'
       );
}

use MP3::Info;

sub redir
{
    my ($r, $url, $code) = @_;
    $r->content_type("text/html");
    $r->header_out(Location => $url);
    return $code || REDIRECT;
}

sub handler
{
        my $r = shift;
        my $uri = $r->path_info || $r->uri || '/';

        @errors = ();
        $r->log_error("$uri");

        if ($uri eq "/" or $uri =~ /^\/playing$/ or $uri eq "/index.html")
        {
                return playing($r);
        }
        elsif ($uri =~ /^\/top10$/)
        {
                return top10($r);
        }
        elsif ($uri =~ /^\/request\/([0-9]*)$/ or $uri =~ /^\/([0-9]*)$/)
        {
                return request_song($r, $1);
                $r->send_http_header('text/plain');
                print "Picked letter song id: $1\n";
                return OK;
        }
        elsif ($uri =~ /^\/([a-z0]).html$/)
        {
#                $r->send_http_header('text/plain');
#               print "Picked letter $1\n";
                return song_listing($r, $1);
                return OK;
        }
        elsif ($uri =~ /^\/status$/)
        {
                my $c = new CGI;
                my $time = `date`;
                $r->send_http_header('text/html');

                print($c->start_html('HalkJockey Radio Status'));
                print($c->h1('hi'));
                print($c->p('hi there there jord'));
                print($c->hr);
                print($c->pre(Dumper($r)));
                print($c->hr);
                print($c->pre(Dumper(%ENV)));
                print($c->hr);
                print($c->pre($base_path));
                print($c->hr);
                print($c->pre($time));
                print($c->hr);
                print($c->pre($r->path_info) . $c->hr);
                print($c->pre($r->as_string));
                print($c->hr);
                print($c->pre($r->uri));
                print($c->hr);
                print($c->end_html);
                return OK;
        }
        $r->log_error("$uri not found");
        return NOT_FOUND; 
}

sub error($)
{
    my $msg = shift;
    my %err = ( error=>$msg );
    push (@errors, \%err );
}

sub playing
{
        my $r = shift;
        my @requests = ();
        
        open (IN_FILE, $base_path . 'var/ices.pid') || error("Cannot open pid file!");
        my $pid = <IN_FILE>;
        close (IN_FILE);
        
        my @playlist = Icecast::Playlist::get_playlist();
        
        $r->send_http_header('text/html');
        # open the html template
        my $template = HTML::Template->new(
                        filename => 'playing.tmpl',
                        die_on_bad_params => 0,
                        cache=>1,
                        cache_debug=>0,
                        path=> $base_path . 'tmpl/',
        ) || undef;
        
        print "Unable to find Template" and $r->log_error("find Template") and return SERVER_ERROR unless (defined($template));
        
        open (DATA, $base_path . 'var/ices.cue') || error("Cannot open cue file!");
        my $count = 0;
        foreach my $line (<DATA>)
        {	
                chomp $line;
                
                if ($count eq 4)
                {
                        my $tmp = HTML::ProgressBar::prepare($line+0);
                        $template->param(playing_progress=>$tmp);
                }
                
                $count++;
                next unless ($count == 1);
                
                my $info = Icecast::Playlist::get_fileinfo($line,0) || undef;
                last unless $info;
                $template->param(playing=>1);
                $template->param(playing_time=>$info->{'time'});
                $template->param(playing_min=>$info->{'min'});
                $template->param(playing_sec=>$info->{'sec'});
                $template->param(playing_bitrate=>$info->{'bitrate'});
                $template->param(playing_length=>$info->{'time'});
                $template->param(playing_album=>$info->{'album'});
                $template->param(playing_artist=>$info->{'artist'});
                $template->param(playing_title=>$info->{'title'});
        }
        close(DATA);

        $template->param(errors=> \@errors);
        $template->param(letters=> \@letters);
        my @top10 = Icecast::Playlist::get_top10(10);
        $template->param(top10=> \@top10);
        $template->param(playlist=> \@playlist);
        
        print ($template->output);

        return OK;
}

sub top10
{
        my $r = shift;
        my @top10 = Icecast::Playlist::get_top10(5);
        
        $r->send_http_header('text/html');
        # open the html template
        my $template = HTML::Template->new(
                        filename => 'top10.tmpl',
                        die_on_bad_params => 0,
                        cache=>1,
                        cache_debug=>0,
                        path=> $base_path . 'tmpl/',
                        ) || undef;
        
        print "Unable to find Template" and $r->log_error("find Template") and return SERVER_ERROR unless (defined($template));
        
        $template->param(errors=> \@errors);
        $template->param(letters=> \@letters);
        $template->param(top10=> \@top10);
        
        print ($template->output);


        return OK;
}

sub song_listing($$)
{
#        my ($r, $letter) = @_;
        my $r = shift;
        my $letter = shift;
        my @songs = ();

        $r->send_http_header('text/html');
        # open the html template
        my $template = HTML::Template->new(
                        filename => 'letter.tmpl',
                        die_on_bad_params => 0,
                        cache=>1,
                        cache_debug=>0,
                        path=> $base_path . 'tmpl/',
                        ) || undef;
        
        print "Unable to find Template" and $r->log_error("find Template") and return SERVER_ERROR unless (defined($template));

        my @playlist = Icecast::Playlist::get_allplaylist();
        
        my $count = 0;
        foreach my $line (@playlist)
        {
                my $info = Icecast::Playlist::get_fileinfo($line->{'filename'}, $line->{'id'});
                
                next if (lc(substr($info->{'artist'}, 0, 1)) ne $letter);
                push (@songs, \%{$info});
        }
        
        $template->param(letter=> uc($letter));        
        $template->param(errors=> \@errors);
        $template->param(letters=> \@letters);
        $template->param(songs=> \@songs);
        
        print ($template->output);
        return OK;
}
                
sub request_song($$)
{
        my $r = shift;
        my $id = (shift)+0;
        
        my $info = Icecast::Playlist::request($id);
        error("Song doesn't exist") unless $info;
        
        $r->send_http_header('text/html');
        # open the html template
        my $template = HTML::Template->new(
                        filename => 'requested.tmpl',
                        die_on_bad_params => 0,
                        cache=>1,
                        cache_debug=>0,
                        path=> $base_path . 'tmpl/',
                        ) || undef;
        
        print "Unable to find Template" and $r->log_error("find Template") and return SERVER_ERROR unless (defined($template));
               
        if (defined ($info))
        {
                $template->param(song_id=>$id);
                $template->param(song_filename=>$info->{'filename'});
                $template->param(song_album=>$info->{'album'});
                $template->param(song_artist=>$info->{'artist'});
                $template->param(song_title=>$info->{'title'});
                $template->param(song_time=>$info->{'time'});
                $template->param(song_man=>$info->{'min'});
                $template->param(song_sec=>$info->{'sec'});
        }

        $template->param(errors=> \@errors);
        $template->param(letters=> \@letters);
        
        print ($template->output);

}

1;
