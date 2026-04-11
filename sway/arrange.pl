#!/usr/bin/env perl

use strict;
use warnings;

use AnyEvent::Sway;
our $s = AnyEvent::Sway->new();

sub switch ($workspace) {
  return defined($s->message(0,"workspace $workspace")->recv->[0]->{'success'});
}

sub move ($output) {
  return defined($s->message(0,"move workspace to output $output")->recv->[0]->{'success'});
}

sub assign ($workspace, $output) {
  return 0 unless (switch($workspace));
  return 0 unless (move($output));
  return 1;
}

my $workspaces = {
  '0'   => [ 'DP-1', 'eDP-1' ],       # HUD
  '1'   => [ 'DP-1', 'eDP-1' ],       # Chat (mattermost, rocket.chat)
  '2'   => [ 'DP-1', 'eDP-1' ],       # Mail (thunderbird)
  '3'   => [ 'DP-1', 'eDP-1' ],       # Secondary browser (ungoogled chromium)
  '4'   => [ 'DP-1', 'eDP-1' ],       # Git (gittyup)
  '5'   => [ 'HDMI-A-1', 'eDP-1' ],   # TBD
  '6'   => [ 'HDMI-A-1', 'eDP-1' ],   # Terminals (gnome-terminal) - not auto-assigned since they are used everywhere
  '7'   => [ 'HDMI-A-1', 'eDP-1' ],   # Browser (firefox)
  '8'   => [ 'HDMI-A-1', 'eDP-1' ],   # IDE (neovide, vscode)
  '9'   => [ 'HDMI-A-1', 'eDP-1' ],   # Music (WIP)
  # Miscellaneous Extras
  'c0'  => [ 'DP-1', 'eDP-1' ],
  'c1'  => [ 'DP-1', 'eDP-1' ],
  'c2'  => [ 'DP-1', 'eDP-1' ],
  'c3'  => [ 'DP-1', 'eDP-1' ],
  'c4'  => [ 'DP-1', 'eDP-1' ],
  'c5'  => [ 'HDMI-A-1', 'eDP-1' ],
  'c6'  => [ 'HDMI-A-1', 'eDP-1' ],
  'c7'  => [ 'HDMI-A-1', 'eDP-1' ],
  'c8'  => [ 'HDMI-A-1', 'eDP-1' ],
  'c9'  => [ 'HDMI-A-1', 'eDP-1' ],
};

my $outputs = ($s->get_outputs->recv())[0];
my $focused;
my %attached;
foreach my $o (@{$outputs}) {
  $focused = $o->{'current_workspace'} if ($o->{'focused'});
  if ($o->{'active'}) {
    $attached{$o->{'name'}} = $o->{'current_workspace'};
  }
}

foreach my $w (keys(%{$workspaces})) {
  foreach my $o (@{$workspaces->{$w}}) {
    if (defined($attached{$o})) {
      last() if assign($w, $o);
      print STDERR ("Failed to assign $w to $o\n")
    }
  }
}

# Favour for which workspace should be focused at the end should follow this logic:
# - Focused window should return to being focused, regardless of the display.
# - Any workspaces which were currently visible at the start should be made current again (multiple could be on the same output, pick random)
# - Any output which is has neither of the above should just be left with the last switch
# Laziest just to switch to those in reverse order, even if it means a few extra switches
foreach (keys(%attached)) {
  switch($attached{$_});
}
switch($focused);
