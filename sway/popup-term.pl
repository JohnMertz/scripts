#!/usr/bin/perl

use strict;
use warnings;
use feature ( 'signatures' );
use JSON::MaybeXS;
my $json = JSON::MaybeXS->new();

our ($workspace, $term_id, $term_ws, $ww, $wh, $tw, $th, $tc);
# Desired terminal dimensions (px or %) and corner (top-right, top-left, bottom-right, bottom-left)
$tw = '100%';
$th = '30%';
$tc = 'bottom-right';

# Workspace to push the terminal to when dismissed
my $hidden = 'grave';
# Terminal executable used for pop-up
my $term = 'alacritty';
# App ID
my $app_id = 'Alacritty-grave';

sub search($nodes, $o=undef, $w=undef, $depth=0) {
  my $debug = 0;
  my $term_id;
  $depth++;
  my $prefix = " "x($depth*4);
  foreach my $n (@{$nodes}) {
    print("${prefix}Checking node $n->{id}".(defined($n->{name}) ? " ($n->{name})" : "")."\n") if ($debug);
    print("${prefix}Considering $n->{app_id}...\n") if ($debug && defined($n->{app_id}));
    if ($n->{type} eq "output") {
      $o = $n->{name};
      print("${prefix}Searching output $o\n") if ($debug);
    } elsif ($n->{type} eq "workspace") {
      $w = $n->{name};
      print("${prefix}Searching workspace $w\n") if ($debug);
    } else {
      print("${prefix}Currently on display $o, workspace $w\n") if ($debug);
      if (defined($n->{app_id}) && $n->{app_id} eq $app_id) {
        $term_id = $n->{id};
        $term_ws = $w;
        print("${prefix}Found $app_id with id $term_id on workspace $w\n") if ($debug);
        return $term_id;
      }
    }
    $term_id = search($n->{floating_nodes}, $o, $w, $depth);
    $term_id = search($n->{nodes}, $o, $w, $depth) if ($term_id == 0);
    print("${prefix}Found $term_id on $w\n") if ($debug && $term_id);
    return $term_id if ($term_id);
  }
  print("${prefix}Not found, moving up a node\n") if ($debug);
  return 0;
}

sub resize() {
  my ($d, $r, $h, $w) = (0, 0);
  if (my ($hit) = $tw =~ m/^(100|\d\d?)\%$/) {
    $w = int(($ww * $hit) / 100);
    $r = $ww - $w if ($tc =~ m/right$/);
  } elsif (($tw =~ m/^\d+$/) && (1 < $tw <= $ww)) {
    $d = $wh - $th if ($tc =~ m/^bottom/);
  }
  if (my ($hit) = $th =~ m/^(100|\d\d?)\%$/) {
    $h = int(($wh * $hit) / 100);
    $d = $wh - $h if ($tc =~ m/^bottom/);
  } elsif (($tw =~ m/^\d+$/) && (1 < $tw <= $ww)) {
    $r = $ww - $tw if ($tc =~ m/right$/);
  }
  `swaymsg "[con_id=$term_id]" resize set width ${w}px height ${h}px, move position ${r}px ${d}px`;
}

my $raw = join("\n",`swaymsg -t get_tree`);

my $root = $json->decode($raw);
$term_id = search($root->{nodes}) || undef;

my $focused = $root->{focus}->[0];
foreach my $d (@{$root->{nodes}}) {
  last if (defined($workspace));
  if ($d->{id} eq $focused) {
    foreach my $w (@{$d->{nodes}}) {
      if ($w->{id} eq $d->{focus}->[0]) {
        $workspace = $w->{name};
        $ww = $w->{rect}->{width};
        $wh = $w->{rect}->{height};
        last;
      }
    }
  }
}

#print("Current workspace is $workspace ($ww x $wh)\n");
#print("Found terminal at node $term_id\n") if (defined($term_id));
#print("Found terminal on workspace $term_ws\n") if (defined($term_ws));

# If there is no terminal found, spawn one
my $resize = 0;
if (!defined($term_id)) {
  my $pid = fork();
  if ($pid) {
    print "No term running, starting one with PID $pid\n";
    sleep 1;
    $raw = join("\n",`swaymsg -t get_tree`);
    $root = $json->decode($raw);
    $term_id = search($root->{nodes}) || undef;
    die("Term not found after starting") unless (defined($term_id));
  } else {
    print("Starting in fork...\n");
    `$term --config-file $ENV{HOME}/.dotfiles/.config/alacritty/grave.toml --class $app_id & disown`;
    print("Exitting\n");
    exit(1);
  }
  resize();
}

# If the current workspace is known and terminal isn't on it, bring and focus
if (defined($term_ws) && $workspace ne $term_ws) {
  print "Term not on current workspace, bringing it\n";
  `swaymsg "[con_id=$term_id]" floating enable`;
  resize();
  `swaymsg "[con_id=$term_id]" sticky enable`;
  `swaymsg "[con_id=$term_id]" move workspace $workspace`;
  `swaymsg "[con_id=$term_id]" focus`;
# Otherwise hide it from whereever it is
} else {
  print "Term is on current workspace or lost, moving to $hidden\n";
  `swaymsg "[con_id=$term_id]" sticky disable`;
  `swaymsg "[con_id=$term_id]" move workspace $hidden`;
  `swaymsg "[con_id=$term_id]" floating disable`;
}
