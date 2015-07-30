#!/usr/bin/perl
#

use strict;

package HTML::ProgressBar;

sub new 
{
        my $this = shift;
        my $class = ref($this) || $this;
        my $args = shift;
        my $self = {
                'current' => $args->{'current'} || 1,
                'max' => $args->{'max'} || 100,
                'step' => $args->{'step'} || 1,
                'min' => $args->{'min'} || 0,
        };
        bless $self, $class;
        return $self;
}  

sub as_string($)
{
        my $self = shift;
        my $max = $self->{'max'};
        my $min = $self->{'min'};
        my $step = $self->{'step'};
        my $current = shift || $self->{'current'} || 0;
        my $percentage = ($current / ($max - $min)) * 100;
        my $output = '';

        $output =  '<table border="1" width="100%" bgcolor="#FFFFFF"><tr><td>'.
                   '<table border="0" width="' . $percentage . '%" cellpadding="0" cellspacing="0"><tr>' . 
                   '<td bgcolor="#000080"><font size="1">&nbsp;</font></td></tr></table></td></tr></table>';
        return $output;
}

sub prepare
{
=cut
    my $output = '';
	my $max = 10;
	my $stop = 1;
	my $cur = 1;
	my $percentage = shift;

	$output .= '<div style="border-style: solid; border-width: 2px; border-color: #000; width: 5em;">';
	$output .= '<div style="border-style: solid; border-width: 2px; border-color: #00F; background-color: #00F; width: ' . $percentage . '%;">&nbsp;</div>';
	$output .= '</div>';
	$output =  '<table border="1" width="100%" bgcolor="#FFFFFF"><tr><td><table border="0" width="' . $percentage . '%" cellpadding="0" cellspacing="0"><tr><td bgcolor="#000080"><font size="1">&nbsp;</font></td></tr></table></td></tr></table>';
=cut
        
        my $bar = HTML::ProgressBar->new({'current'=>shift});
        return $bar->as_string();
}

1;

