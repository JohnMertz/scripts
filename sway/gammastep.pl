#!/usr/bin/perl

# TODO: If gammastep is already running, allow location to update

use strict;
use warnings;

use LWP::UserAgent;
use JSON::XS;

my $location = "https://papillon.john.me.tz/data/location.json";
my $lat_lon = fetch_lat_lon($location);

my $pid = fork;
unless ($pid) {
  open(my $fh, ">", $ENV{HOME}."/.local/state/gammastep.pid");
  print $fh $$;
  close($fh);
  open($fh, ">", $ENV{HOME}."/.local/state/gammastep.status");
  print $fh 1;
  close($fh);

  open STDIN,  '/dev/null';
  open STDOUT, '>>/dev/null';
  open STDERR, '>>/dev/null';

  exec "exec $ENV{HOME}/.local/bin/gammastep-indicator -l $lat_lon -b 0.7:0.3";
}

sub fetch_lat_lon ($location) {

  my $ua = LWP::UserAgent->new();
  my $json = JSON::XS->new();

  my $raw = $ua->get($location)->content();

  if (defined $raw) {
    my $decoded = $json->decode($raw);
    if (defined $decoded->{lat} && defined $decoded->{lon}) {
      return "$decoded->{lat}:$decoded->{lon}";
    }
  }
  sleep 5;
  return fetch_lat_lon($ua, $json, $location);
}

exit;
