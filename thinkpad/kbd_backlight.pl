#!/usr/bin/perl

use strict;
use warnings;

our $maxfile = "/sys/class/leds/tpacpi\:\:kbd_backlight/max_brightness";
our $current = "/sys/class/leds/tpacpi\:\:kbd_backlight/brightness";
our $sleepfile = "$ENV{HOME}/.local/state/kbd_sleep";
our $idlestate = "$ENV{HOME}/.local/state/idle_current";

sub readFile ($file) {
  my $ret;
  if (open(my $fh, '<', $file)) {
    $ret = readline($fh);
    chomp $ret;
    close($fh);
  } else {
    die "Failed to read $file: $?\n";
  }
  return $ret;
}


sub writeFile ($file, $value) {
  if (open(my $fh, '>', $file)) {
    print $fh $value;
    close($fh);
  } else {
    die "Failed to write $current\n";
  }
}

sub sleepFile ($now) {
  # Only log desired state to sleep file if system is idle
  unless (defined($now)) {
    $now //= readFile($current);
    writeFile($current,0);
  }
  writeFile($sleepfile,$now);
}

sub restoreFile {
  unless (-e $sleepfile) {
    die "Missing '$sleepfile'. Must not have slept prior to restore.\n"
  }
  my $value = readFile($sleepfile);
  writeFile($current,$value);
  unlink($sleepfile);
}

sub rotateFile ($new) {
  unless (defined($new)) {
    my $max = readFile($maxfile);
    my $now = readFile($current);
    $new = (($now+1) % ($max+1));
  }
  writeFile($current,$new);
}

if (defined($ARGV[0])) {
  if ($ARGV[0] eq 'sleep') {
    sleepFile();
    exit(0);
  } elsif ($ARGV[0] eq 'restore') {
    restoreFile();
    exit(0);
  } elsif ($ARGV[0] eq 'rotate') {
    rotateFile();
    exit(0);
  } elsif ($ARGV[0] =~ m/^[0-2]$/) {
    my $idlestate = readFile($idlestate);
    if ($idlestate eq 'awake' || $idlestate eq 'unfade') {
      rotateFile($ARGV[0]);
    }
    sleepFile($ARGV[0]);
    exit(0);
  } else {
    die "Invalid mode '".$ARGV[0]."'. 'rotate', 'sleep', or 'restore'\n";
  }
}

