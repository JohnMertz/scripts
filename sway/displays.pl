#!/usr/bin/env perl

use v5.40;
#no warnings 'builtin::blessed';
#use experimental qw( builtin::blessed );

########################################################################
# Usage
########################################################################
#
# $ displays.pl [layout] [-w]
#
# layout  Name of desired layout, as configured starting at line 100
#       If missing, last known layout is used (logged to file $last)
# -w    (Re)load waybar only. Skip display configuration. Only kill
#       existing waybars and start new ones for desired layout

########################################################################
# Dependencies
########################################################################
#
# Depends on JSON::MaybeXS and Proc::ProcessTable
#
# Debian:
# apt install libjson-xs-perl libproc-processtable-perl

########################################################################
# Directories and Files
########################################################################

# Template is a normal config with the following in place of values:
# "output": __OUTPUT__
# "position": __POSITION__
# "width": __WIDTH__ (optional)
my $waybar_template = "$ENV{'HOME'}/.dotfiles/.config/waybar/config.template";

my $swaysock = $ENV{'SWAYSOCK'} || $ENV{'HOME'} . "/.local/state/sway-ipc.sock";

# Path to actual config file generated from template
my $waybar_config = "$ENV{'HOME'}/.dotfiles/.config/waybar/config";

# Path to waybar binary
#my $waybar_bin = "$ENV{'HOME'}/.dotfiles/.config/nix/bin/waybar";
my $waybar_bin = "/usr/bin/waybar";

# File to log and recover last used layout name
my $last = "$ENV{'HOME'}/.local/state/last_display";

# File to log active outputs (used by swayidle, and to attempt to restore
my $active_outputs = "$ENV{'HOME'}/.local/state/active_outputs";

# File to log which displays have a wallpaper active, will be written to restart wallpapers.pl
my $wallpaper_outputs .= "$ENV{'HOME'}/.local/state/wallpaper_outputs";
my @wallpapers;

########################################################################
# Display Serials and Names
########################################################################

# Hash to match display model name to internal name
# You can get the model from (quoted with *):
#   $ swaymsg -t get_outputs --raw
my %outputs = (
  'LG TV SSCR2' => 'LG48',
  'DENON-AVAMP' => 'TV',
  'DASUNG' => 'eInk',
  '0x1305' => 'x13',
  'DELL P2723QE' => 'Dell'
);

########################################################################
# Display Configurations
########################################################################

# First-level key of hash is the name of each configuration
# Second-level keys are the display friendly-names, above
# Third-level are the actual settings for that display
my %configs = (
  'eInk' => {
    'eInk' => {
      'on' => 1,
      'width' => 3840,
      'height' => 2160,
      'x' => 0,
      'y' => 0,
      'rotate' => 0,
      'scale' => 1.33333,
      'waybar' => 'top',
      'fallback' => '#010101',
    },
    'LG48' => {
      'on' => 0
    },
    'x13' => {
      'on' => 0
    },
  },
  'TV' => {
    'eInk' => {
      'on' => 0
    },
    'TV' => {
      'on' => 1,
      'width' => 3840,
      'height' => 2160,
      'refresh' => 30,
      'x' => 0,
      'y' => 0,
      'rotate' => 0,
      'scale' => 1,
      'waybar' => 'top',
      'fallback' => '#010101',
      'bg' => 1,
    },
    'x13' => {
      'on' => 1,
      'width' => 2560,
      'height' => 1440,
      'x' => 3840,
      'y' => 0,
      'rotate' => 0,
      'scale' => 1.5,
      'waybar' => 'bottom',
      'fallback' => '#010101',
      'bg' => 1,
    },
  },
  'LG48' => {
    'eInk' => {
      'on' => 0
    },
    'LG48' => {
      'on' => 1,
      'width' => 3840,
      'height' => 2160,
      'x' => 0,
      'y' => 0,
      'rotate' => 0,
      'scale' => 1.33333,
      'waybar' => 'top',
      'fallback' => '#010101',
      'bg' => 1,
    },
    'x13' => {
      'on' => 0
    },
  },
  'x13' => {
    'eInk' => {
      'on' => 0
    },
    'Dell' => {
      on => 0,
    },
    'LG48' => {
      'on' => 0
    },
    'x13' => {
      'on' => 1,
      'width' => 2560,
      'height' => 1440,
      'x' => 0,
      'y' => 0,
      'rotate' => 0,
      'scale' => 1.5,
      'waybar' => 'bottom',
      'fallback' => '#010101',
      'bg' => 1,
    },
  },
  'eInk+x13' => {
    'eInk' => {
      'on' => 1,
      'width' => 3200,
      'height' => 1800,
      'x' => 54,
      'y' => 0,
      'rotate' => 0,
      'scale' => 2,
      'waybar' => 'top',
      'fallback' => '#010101',
    },
    'LG48' => {
      'on' => 0,
    },
    'x13' => {
      'on' => 1,
      'width' => 2560,
      'height' => 1440,
      'x' => 0,
      'y' => 960,
      'rotate' => 0,
      'scale' => 1.5,
      'waybar' => 'bottom',
      'fallback' => '#000000',
      'bg' => 1,
    },
  },
  'LG48+eInk' => {
    'eInk' => {
      'on' => 1,
      'width' => 3200,
      'height' => 1800,
      'x' => 2880,
      'y' => 0,
      'rotate' => 90,
      'scale' => 2,
      'waybar' => 'top',
      'fallback' => '#010101',
    },
    'LG48' => {
      'on' => 1,
      'width' => 3840,
      'height' => 2160,
      'refresh' => 30,
      'x' => 0,
      'y' => 0,
      'rotate' => 0,
      'scale' => 1.3333333333,
      'waybar' => 'top',
      'fallback' => '#000000',
      'bg' => 1,
    },
    'x13' => {
      'on' => 0
    },
  },
  'Alinto' => {
    'eInk' => {
      'on' => 0,
    },
    'LG48' => {
      'on' => 0,
    },
    'Dell' => {
      'on' => 1,
      'width' => 3840,
      'height' => 2160,
      'refresh' => 30,
      'x' => 0,
      'y' => 0,
      'rotate' => 0,
      'scale' => 1.333333333,
      'waybar' => 'bottom',
      'fallback' => '#000000',
      'bg' => 1,
    },
    'x13' => {
      'on' => 1,
      'width' => 2560,
      'height' => 1440,
      'refresh' => 30,
      'x' => 587,
      'y' => 1620,
      'rotate' => 0,
      'scale' => 1.5,
      'waybar' => 'top',
      'fallback' => '#000000',
      'bg' => 1,
    },
  },
  'LG48+x13' => {
    'eInk' => {
      'on' => 0,
    },
    'LG48' => {
      'on' => 1,
      'width' => 3840,
      'height' => 2160,
      'refresh' => 30,
      'x' => 0,
      'y' => 0,
      'rotate' => 0,
      'scale' => 1.333333333,
      'waybar' => 'top',
      'fallback' => '#000000',
      'bg' => 1,
    },
    'x13' => {
      'on' => 1,
      'width' => 2560,
      'height' => 1440,
      'refresh' => 30,
      'x' => 2880,
      'y' => 0,
      'rotate' => 0,
      'scale' => 1.5,
      'waybar' => 'bottom',
      'fallback' => '#000000',
      'bg' => 1,
    },
  },
  'all' => {
    'eInk' => {
      'on' => 1,
      'width' => 3200,
      'height' => 1800,
      'x' => 2880,
      'y' => 0,
      'rotate' => 90,
      'scale' => 2,
      'waybar' => 'top',
      'fallback' => '#010101',
    },
    'LG48' => {
      'on' => 1,
      'width' => 3840,
      'height' => 2160,
      'refresh' => 30,
      'x' => 0,
      'y' => 0,
      'rotate' => 0,
      'scale' => 1.3333333,
      'waybar' => 'top',
      'fallback' => '#000000',
      'bg' => 1,
    },
    'x13' => {
      'on' => 1,
      'width' => 2560,
      'height' => 1440,
      'x' => 2880,
      'y' => 1800,
      'rotate' => 0,
      'scale' => 1.5,
      'waybar' => 'bottom',
      'fallback' => '#000000',
      'bg' => 1,
    },
  },
);

########################################################################
# Program (do not edit below)
########################################################################

use strict;
use warnings;

my $waybar_only = 0;
my $restore = 0; # Set if no config is provided. Requires validation.
my $config;

if (scalar(@ARGV)) {
  while (@ARGV) {
    my $arg = shift;
    if ($arg eq "-w") {
      $waybar_only = 1;
    } else {
      if (defined $config) {
        die "Too many arguments.\n";
      }
      $config = $arg;
    }
  }
}

# Get previous config if one is not provided
unless (defined $config) {
  open(my $fh, '<', $last) ||
    die "Config name not provided and failed to open $last\n";
  $config = <$fh>;
  close($fh);
  chomp $config;
  $restore = 1;
}

# Bail if requested config doesn't exist
if (!defined($configs{$config})) {
  if ($restore) {
    # If restoration is attempted with invalid config, just enable eDP-1
    $config = 'detached';
  } else {
    die "$config is not a defined configuration: "
      . join(', ', keys %configs) . "\n";
  }
}

# Write config that is to be used so that it can be recovered as default
if (open(my $fh, '>', $last)) {
  print $fh $config;
  close($fh);
} else {
  print STDERR "Config name cannot be logged to: $last\n";
}

# Fetch connected displays
use JSON::MaybeXS;
my $json = JSON::MaybeXS->new();
my $displays_raw = `swaymsg -s $swaysock -t get_outputs --raw`;
my $displays = $json->decode($displays_raw);

# For each connected display, collect the desired settings for enabled
# displays and a list of displays to disable
my $on;
my @off;
for (my $i = 0; $i < scalar(@$displays); $i++) {

  # If a display is found without any settings print error and turn it off
  unless (defined $configs{$config}{$outputs{$displays->[$i]->{model}}}){
    print STDERR "Output $displays->[$i]->{name} ("
      . $displays->[$i]->{model}
      . ") found without defined function. Disabling.\n";
    push(@off, $displays->[$i]->{name});
    next;
  }

  # If display is enabled, copy all of the desired settings
  if ($configs{$config}{$outputs{$displays->[$i]->{model}}}{on}) {
    $on->{$outputs{$displays->[$i]->{model}}} =
      $configs{$config}{$outputs{$displays->[$i]->{model}}};
    $on->{$outputs{$displays->[$i]->{model}}}{output} =
      $displays->[$i]->{name};
  # Otherwise simply list it for disabling
  } else {
    push(@off, $displays->[$i]->{name});
  }

}

# Verify that all requested displays are actually available
my @unavailable;
foreach my $output (keys %$on) {
  my $found = 0;
  foreach my $o (keys %outputs) {
    if ($outputs{$o} eq $output) {
      $found = 1;
      last;
    }
  }
  unless ($found) {
    push(@unavailable, $output);
  }
}
if (scalar(@unavailable)) {
  die "Config requires unavailable output(s) " . join(', ', @unavailable)
    . "\n";
}

# Skip enabling/disabling displays if only running waybar (re)start
unless ($waybar_only) {
  # Number of simultaneous outputs is limited by gpu, so disabled displays first
  foreach (@off) {

    # Sway returns status as JSON
    my $res_raw = `swaymsg -s $swaysock output $_ disable`;
    my $res = $json->decode($res_raw)->[0];

    # If failed, print to STDERR
    unless ($res->{success}) {
      print STDERR "Error ($res->{error}) in command 'swaymsg"
        . " -s $swaysock output $_ disable'\n";
    }

  }
}

# Kill existing Waybars and wallpaper rotation script
require Proc::ProcessTable;
my $t = Proc::ProcessTable->new();
foreach my $p ( @{ $t->table } ) {
  my $cmndline = $p->{'cmndline'};
  $cmndline =~ s/\s*$//g;
  if ($cmndline =~ /^waybar.*/) {
    # Never kill this process
    if ($p->{'pid'} == $$) {
      next;
    } else {
      $p->kill(9);
    }
  }
}

# Load in config template
my $template;
if (open (my $fh, '<', $waybar_template)) {
  while (<$fh>) {
    $template .= $_;
  }
  close $fh;
  chomp $template;
} else {
  print STDERR "Failed to load template $waybar_template\n";
}

# If template is already set up as an array, remove the square brackets so that
# we can concatenate multiple displays
$template =~ s/^[^\[\{]*\[(.*)\]$/$1/s;

# Setup waybar config file
my $waybar = '';

# Configure each enabled display
my @active;
foreach my $out (keys %$on) {

  push(@active, $on->{$out}->{output});
  unless ($waybar_only) {
    # Build command, starting by enabling and powering on
    my $cmd = "swaymsg -s $swaysock output $on->{$out}->{output}" .
      " enable dpms on";

    # If additional options are provided, add them to command
    if (defined $on->{$out}->{scale}) {
      $cmd .= " scale $on->{$out}->{scale}";
    } else {
      $cmd .= " scale 1";
    }
    if (defined $on->{$out}->{rotate}) {
      $cmd .= " transform $on->{$out}->{rotate}";
    } else {
      $cmd .= " transform 0";
    }
    if (defined $on->{$out}->{x} && defined $on->{$out}->{y}) {
      $cmd .= " position $on->{$out}->{x} $on->{$out}->{y}";
    }
    if (defined $on->{$out}->{width} &&
      defined $on->{$out}->{height} )
    {
      $cmd .= " mode $on->{$out}->{width}x" .
        "$on->{$out}->{height}" .
        (defined($on->{$out}->{refresh}) ? '@'.$on->{$out}->{refresh}.'Hz' : '');
    }
    if (defined($on->{$out}->{bg}) && $on->{$out}->{bg}) {
      push(@wallpapers, $on->{$out}->{output});
      #$cmd .= " bg $on->{$out}->{bg} fit";
      #if (defined $on->{$out}->{fallback}) {
        #$cmd .= " $on->{$out}->{fallback}";
      #}
    } elsif (defined $on->{$out}->{fallback}) {
      $cmd .= " bg $on->{$out}->{fallback} solid_color";
    }

    # Sway returns status as JSON
    my $res_raw = `$cmd`;
    #print $res_raw . "\n";
    my $res = $json->decode($res_raw)->[0];

    # If failed, print to STDERR
    unless ($res->{success}) {
      print STDERR "Error ($res->{error}) in command " .
        "'$cmd'\n";
    }
  }

  # Skip waybar setup if template failed to be loaded
  if ( (defined $template) &&
    (defined $on->{$out}->{waybar}) &&
    ($on->{$out}->{waybar} =~ m/(top|bottom|left|right)/) )
  {

    # If there's already a display set up, add a comma
    unless ($waybar eq '') {
      $waybar .= ',';
    }

    $waybar .= $template;

    # Replace basic preferences
    $waybar =~ s/__OUTPUT__/"$on->{$out}->{output}"/gg;
    $waybar =~ s/__POSITION__/"$on->{$out}->{waybar}"/gg;
    if (defined $on->{$out}->{width}) {
      my $x = $on->{$out}->{width};
      if (defined $on->{$out}->{scale}) {
        $x = sprintf("%.0d", $x / $on->{$out}->{scale});
      }
      $waybar =~ s/__WIDTH__/$x/gg;
    # If width is not set, comment that line out to use default
    } else {
      $waybar =~ s#([^\s]*\s*)__WIDTH__#// $1__WIDTH__#gg;
    }

  } else {
    print STDERR "Failed to load template\n";
  }
}

# Log active outputs for recovery after crash/reboot
if (open(my $fh, '>', $active_outputs)) {
  print $fh join(' ', @active);
  close($fh);
} else {
  print STDERR "Cannot write active outputs to: $active_outputs\n";
}

# Restore array formatting
$waybar = '[' . $waybar . ']';

# Write wallpaper outputs
my $w;
$w = join(' ', @wallpapers) if (scalar(@wallpapers));
if ($w) {
  if (open(my $fh, '>', $wallpaper_outputs)) {
    my $w = join(' ', @wallpapers);
    print $fh $w;
    close($fh);
  } else {
    print STDERR "Cannot write wallpaper outputs to: $wallpaper_outputs: $!\n";
  }
}

# Start Waybar as fork
my $pid = fork;
unless ($pid) {
  open STDIN,  '/dev/null';
  open STDOUT, '>>/dev/null';
  open STDERR, '>>/dev/null';
  # Write config to a temporary file
  if (open (my $fh, '>', $waybar_config)) {
    print $fh $waybar;
    close $fh;
  } else {
    die "Failed to write configuration file: $waybar_config\n";
  }
  my $waydisplay = $ENV{'WAYLAND_DISPLAY'} || 'wayland-0';
  `WAYLAND_DISPLAY=$waydisplay nohup $waybar_bin -b waybar0 --config=$waybar_config >> $ENV{'HOME'}/.waybar.log`;
}

# Restart wallpaper daemon
`systemctl --user restart wallpapers.service`;
