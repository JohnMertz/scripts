#!/usr/bin/env perl

use strict;
use warnings;

our $debug = 1;  # For testing, will output configuration and errors if true

use AnyEvent::Sway;
our $s = AnyEvent::Sway->new();

our $o = $s->get_outputs->recv();
die "No outputs detected.\n" unless (scalar(@$o) > 1);

sub usage() {
  print("$0 [value] [-p|--plus] [-m|--minus] [-a x|--attribute=x] [-d N|--delay=N]
Fade the opacity of one or more windows via the Sway IPC interface.\n
value          The target opacity or offset between 0 (full transparency) and 1
               (fully opaque). Change will be made in increments of 0.01 with a
               delay between each.\n
--attribute=x  Attribute of window(s) to fade.
-a x           Default: [title="*"]\n
--plus         Increases opacity by increment instead of setting it directly
-p             to that increment.\n
--minus        Decreases opacity by increment instead of setting it directly
-m             to that increment.\n
--delay=N      Change the delay in ms between each percentage point change in
-d N           opacity. Default: 20\n
--help         This menu
-h\n");
  exit(0);
}

sub set_opacity ($attribute, $target) {
  # TODO get fallback from javascript
  my $cmd = "output $attribute opacity $target";
  print "Running $cmd\n";
  my $ret = $s->message(0,$cmd)->recv;
  if ($ret->[0]->{success}) {
    print "Success!\n";
    return undef;
  }
  return "Failed to run Sway IPC command '$cmd'";
}

my @targets;
my $daemon = 0;
my $delay = 300;
my $crop = 1;
my $path;

while (my $arg = shift(@ARGV)) {
  if ($arg eq '-h' || $arg eq '--help') {
    usage();
  } elsif ($arg =~ m/^\-\-path=?(.+)$/) {
    die "Redundant argument '$arg'. Wallpaper path already set.\n" if ($path);
    $path = $1;
  } elsif ($arg eq '-p') {
    die "Redundant argument '$arg'. Wallpaper path already set.\n" if ($path);
    $path = shift(@ARGV);
  } elsif ($arg =~ m/^\-\-daemon=?(.+)$/) {
    die "Redundant argument '$arg'. Daemon mode already set.\n" if ($daemon);
    $delay = $1;
    $daemon = 1;
  } elsif ($arg eq '-d') {
    die "Redundant argument '$arg'. Daemon mode already set.\n" if ($daemon);
    if ($ARGV[0] =~ m/^\d+$/) {
      $delay = shift(@ARGV);
    }
    $daemon = 1;
  } elsif ($arg eq '--nocrop' || $arg eq '-') {
    die "Redundant argument '$arg'. No-crop already set.\n" unless ($crop);
  } else {
    push(@targets,$arg);
  }
}

die "Invalid rotation delay: $delay" unless ($delay =~ m/^\d+$/);

if ($path) {
  die "Invalid wallpaper path '$path'. Not a directory." unless (-d $path);
} else {
  $path = "$ENV{HOME}/wallpapers";
}

if (scalar(@targets)) {
  my @kept;
  foreach my $t (@targets) {
    my $hit = 0;
    foreach (@$o) {
      if ($_->{name} eq $t) {
        push(@kept, $t);
        $hit++;
        last;
      }
    }
    print STDERR "Requested output '$t' not found\n" unless ($hit);
  }
  die "None of the requested outputs are active" unless (scalar(@kept));
  @targets = @kept;
}

if ($daemon) {
  my $p = fork();
  if ($p) {
    print "Daemonized as PID: $p\n";
    exit(0);
  }
}

if ($debug) {
  print "Initial configuration:\n";
  print "  Targets: ( " . ( join(" ",@targets) || "All active" ) . " )\n";
  print "  Daemon:  $daemon\n";
  print "  Path:  $path\n";
}

my @e;
do {
  my @err;
  # Local copy of targets so that it will re-check active every time
  my @t = @targets;
  unless (scalar(@t)) {
    @t = get_active();
    push(@err, "No target outputs") unless (scalar(@t));
  }
  foreach my $a (@t) {
    my $image = choose_image($path);
    if (defined($image)) {
      if ( -r "$image" ) {
      print "selected $image\n";
        my $cropped;
        if ($crop) {
          if ($debug) {
            print "Cropping image for '$a' using '$image'\n";
          }
          my ($ow, $oh) = get_size($a);
          $cropped = crop($image, $ow, $oh);
          unless ($cropped) {
            push(@err, "Failed to generate cropped image") unless ($cropped);
            next;
          }
        } else {
          $cropped = $image;
        }
        my $e = set_background($a,$cropped);
        push(@err, $e) if (defined($e));
        if ($crop) {
          print "Deleting $cropped\n";
          #unlink($cropped) || push(@err, "Failed to delete $cropped after setting: $!");
        }
      } else {
        push(@err, "$a: Unable to read image $image");
      }
    } else {
      push(@err, "$a: Unable to select image from $path");
    }
  }
  if ($debug && $daemon) {
    print STDERR join("\n",@err);
    sleep($delay);
  } else {
    @e = @err;
  }
} while ($daemon);

if (scalar(@e)) {
  die "Failure while not running as daemon:\n" .
    join("\n",@e);
}

exit(0);

