#!/usr/bin/perl

sub usage {
  print("usage: $0 [mute|unmute|sleep|wake]\n\n");
  print("mute    mute any 'Speaker' output\n");
  print("unmute  mute any 'Speaker' output\n");
  print("sleep   mute if currently unmuted and log prior state\n");
  print("wake    unmute if prior logged state was unmuted\n");
}

my $sleep_dir = "$ENV{HOME}/.local/state/mute_sleep";
mkdir $sleep_dir unless (-d $sleep_dir);

my $action;
if (!scalar(@ARGV) || scalar(@ARGV) != 1) {
  die ("Requires exactly one argument: 'mute', 'unmute', 'sleep', 'wake'\n");
} elsif ($ARGV[0] eq 'mute' || $ARGV[0] eq 'unmute' || $ARGV[0] eq 'sleep' || $ARGV[0] eq 'wake') {
  $action = $ARGV[0];
} else {
  die ("Invalid argument $ARGV[0]\n");
}

my (%sinks, $id);
foreach (split(/\n/, `pactl list sinks`)) {
  if ($_ =~ m/Sink #(\d+)/) {
    $id = $1;
    $sinks{$id} = ( 'speaker' => 0, 'muted' => 0 );
  } elsif ($_ =~ m/Mute: yes/) {
    $sinks{$id}{muted} = 1;
  } elsif ($_ =~ m/Active Port:.*Speaker/) {
    $sinks{$id}{speaker} = 1;
  }
}

foreach my $id (keys(%sinks)) {
  my $prev = 0;
  if ($action eq 'wake') {
    if (-e "$sleep_dir/$id") {
      if (open(my $fh, '<', $sleep_file)) {
        $prev = <$fh>;
        chomp $prev;
        close($fh);
      }
    }
    unlink("$sleep_dir/$id");
  }
  if ($sinks{$id}{speaker}) {
    my $set = 0;
    $set = 1 if ($action eq 'sleep' || $action eq 'mute');
    $set = 1 if ($action eq 'wake' && $prev);
    `pactl set-sink-mute $id $set` if ($sinks{$id}{muted} != $set);
    if ($action eq 'sleep') {
      if (open(my $fh, '>', $sleep_file)) {
        print $fh 1;
        close $fh;
      }
    }
  }
}
