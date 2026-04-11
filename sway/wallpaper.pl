#!/usr/bin/env perl

# TODO: add option to allow recursive sub-directories (in choose_image())
# TODO: license, etc.

use v5.40;
use POSIX;
use File::Copy;

$ENV{PWD} = '/tmp' unless (defined($ENV{PWD}));

use constant ERROR => {
  LOG_EMERG       => 8,
  LOG_ALERT       => 7,
  LOG_CRIT    => 6,
  LOG_ERR     => 5,
  LOG_WARNING     => 4,
  LOG_NOTICE      => 3,
  LOG_INFO    => 2,
  LOG_DEBUG       => 1
};

our @e;

sub usage($self)
{
  print("$0 [output(s)] [-d|--daemon]\n
Sets a wallpaper by cropping an appropriate sized section of a larger image.\n
All arguments other than the below are assumed to be output names, as defined
in my sway/displays.pl script. If no outputs are provided, all available that
are currently enabled will be set.\n
--path=<path>   Path to wallpaper directory.
-p <path>       Default: $ENV{HOME}/wallpapers\n
--daemon=N      Configures the wallpaper to be periodically rotated for all
-d N            of the given outputs. N indicates the number of seconds between
                each rotation, if provided (default: 300).\n
--nocrop        Don't crop a selection from the image. Instead, pass the whole
-n              image to swaybg and let it handle the scaling\n
--verbose=N     Define minimum log level. Counting from 1: LOG_DEBUG, LOG_INFO,
-v N            LOG_NOTICE, LOG_WARNING, LOG_ERR, LOG_CRIT, LOG_ALERT, LOG_EMERG
                Default: 5; If provided without a value for N then all (1).
--recursive=N   Enumerate images recursively through directories in the path.
-r N            N indicates the directory depth, unlimited if no N is provided.
--help          This menu
-h\n
You can send SIGUSR1 to force the daemon to reload immediately. Rotation timer
will be reset.\n");
  exit(0);
}

sub new($class, %args)
{
  use AnyEvent::I3;
  $args{ipc} = AnyEvent::I3->new();
  use Image::Magick;
  $args{im} = Image::Magick->new();
  $args{error} = ();

  $args{pidfile} = "$ENV{HOME}/.local/state/wallpaper.pid";
  $args{outputfile} = "$ENV{HOME}/.local/state/wallpaper_outputs";

  return bless { %args };
}

my $wp = new("Wallpapers");

if (-e $wp->{pidfile}) {
  if (-r $wp->{pidfile}) {
    if (open(my $fh, '<', $wp->{pidfile})) {
      my $pid = <$fh>;
      chomp($pid);
      use Proc::ProcessTable;
      my $pt = Proc::ProcessTable->new();
      foreach my $p ( @{ $pt->table() } ) {
        if ($p->{pid} eq $pid) {
          my $name = $0;
          $name =~ s/$ENV{PWD}//;
          if ($p->{'cmndline'} =~ m#$name#) {
            $wp->do_log("LOG_CRIT", "Another process is already running with PID: $pid (running and listed in $wp->{pidfile})");
            # Die locally because do_log will remove pidfile that this iteration does not belong to
            exit(1);
          } else {
            $wp->do_log("LOG_CRIT", "Found matching $pid with different cmdline: $p->{cmndline} (not $0)",1);
            # PID in pidfile doesn't look like it is another wallpaper
            unlink($wp->{pidfile});
            last;
          }
          return $p->{'pid'};
        }
      }
    } else {
      $wp->do_log("LOG_CRIT", "Pidfile $wp->{pidfile} exists, but cannot be opened. Assuming it is running already.");
      # Die locally because do_log will remove pidfile that this iteration does not belong to
      exit(1);
    }
  } else {
    $wp->do_log("LOG_CRIT", "Pidfile $wp->{pidfile} exists, but is not readable. Assuming it is running already.");
    # Die locally because do_log will remove pidfile that this iteration does not belong to
    exit(1);
  }
}

# SIGUSR reset the timer, force immediate reload, continue looping
$SIG{USR1} = sub {
  alarm 0;
  $wp->do_log("LOG_INFO", "Reloading due to SIGUSR1");
};

# SIGTERM reset the timer, clean pid, and allow for the main loop to finish run
$SIG{TERM} = sub {
  $wp->do_log("LOG_INFO", "Going down clean due to SIGTERM");
  clean($wp);
  $wp->{daemon} = 0;
};

# SIGKILL clean pid then exit immediately
$SIG{KILL} = sub {
  $wp->do_log("LOG_INFO", "Hard kill with SIGKILL, attempting to remove pidfile");
  clean($wp);
  exit(0);
};

# simply returns the array of hashes provided by swaymsg
sub get_outputs($self)
{
  my $o = $self->{ipc}->get_outputs->recv() || $self->do_log('LOG_WARNING',"Failed to query 'get_outputs'");
  die "No outputs detected.\n" unless (scalar(@$o) > 0);
  return $o;
}

# returns the same as above but with the 'name' as a hash key for easier lookup
sub get_active($self)
{
  if (defined($self->{outputs}) && scalar($self->{outputs})) {
    my %active = ();
    foreach my $o (@{$self->{outputs}}) {
      my $name;
      my %details;
      next unless ($o->{active});
      $active{$o->{name}} = ();
      foreach (keys(%$o)) {
        $active{$o->{name}}->{$_} = $o->{$_} unless ($_ eq 'name');
      }
    }
    $self->do_log('LOG_WARNING',"No outputs detected.") unless (scalar(keys(%active)));
    return \%active;
  } else {
    $self->do_log('LOG_WARNING',"Output list not defined yet. Try 'get_outputs()' first");
    return \{};
  }
}

sub clean($self)
{
  if (-e $self->{pidfile}) {
    open (my $fh, '<', $self->{pidfile});
    my $p = <$fh>;
    close($fh);
    chomp $p;
    kill($p);
    unlink($self->{pidfile});
  }
}

sub dig_dirs($self, $paths_ref, $path, $depth=0)
{
  unless (-e $path) {
    return(undef);
  }
  if ($path =~ m/\/\.\.?$/) {
    return;
  }
  foreach (glob("$path/*"), glob("$path/.*")) {
    if ($path =~ m/\/\.\.?$/) {
      next();
    } elsif (-l $_) {
      push(@$paths_ref, $_);
    } elsif (-d $_ && ($self->{recursive} == '-1' || $depth < $self->{recursive})) {
      $self->dig_dirs($paths_ref,$_,$depth+1);
    } else {
      push(@$paths_ref, $_);
    }
  }
}

sub choose_image($self)
{
  my @i;
  my $depth = 0;
  my @w;
  $self->dig_dirs(\@w,$self->{path});
  return undef unless (scalar(@w));
  $self->do_log("LOG_DEBUG", "Found ".scalar(@w)." files in $self->{path} up to depth $self->{recursive}");
  foreach (@w) {
    if (-d $_) {
      $self->do_log("LOG_DEBUG", "Ignoring sub-directory $_");
      next;
    }
    if ($_ =~ m/\.(png|jpg)$/) {
      push(@i,$_);
    }
  }

  return $i[rand(scalar(@i))] || return undef;
}

sub crop($self, $image, $ow, $oh)
{
  my $cropped = $image;
  $cropped =~ s#^.*/([^/]*)\.([^\.]+)$#$self->{'path'}/$1-cropped.$2#;

  use Image::Magick;
  my $im = Image::Magick->new();
  die "$image is not readable" unless (-r $image);
  my $ret = $im->Read($image);
  return 0 if ($ret);
  my ($iw, $ih) = $im->Get("columns", "rows");
  $self->do_log("LOG_DEBUG", "Image has dimensions ${iw}x${ih}");

  # Return full size if it is smaller in either dimension then the output
  if ($iw <= $ow || $ih <= $oh) {
    $self->do_log("LOG_DEBUG", "Not cropping because ${iw}x${ih} is smaller or equal to the output (${ow}x${oh}) in at least 1 dimension.");
    return undef;
  }

  my ($x, $y);
  $x = int(rand($iw-$ow));
  $y = int(rand($ih-$oh));

  my $err = $im->Crop(geometry=>"${ow}x${oh}+${x}+${y}");
  die "$err" if ($err);
  $err = $im->Write($cropped);
  die "$err" if ($err);
  return $cropped if ( -e $cropped );
}

sub set_background($self, $target, $cropped)
{
  # TODO get fallback from javascript
  my $cmd = "output $target background $cropped fill #000000";
  $self->do_log("LOG_DEBUG", "Running $cmd\n");
  my $ret = $self->{ipc}->message(0,$cmd)->recv;
  if ($ret->[0]->{success}) {
    $self->do_log("LOG_DEBUG", "Success!");
    return undef;
  }
  return "Failed to run Sway IPC command '$cmd'";
}

sub do_log($self, $level, $msg, $die=0)
{
  my $min = $self->{verbose} || 5;

  # Journald module is borked. Just print to STDOUT and SystemD will catch it
  $msg = '(FATAL) ' . $msg if ($die);
  if (ERROR->{$level} >= $min) {
    printf("%11s %s\n", $level, $msg);
  }
  if ($die) {
    $self->clean();
    exit(1);
  }
}

sub run($self)
{
  $self->do_log("LOG_DEBUG", "Fetching outputs from IPC");
  $self->{outputs} = $self->get_outputs();
  # Local copy of targets so that it will re-check active every time
  my @t = @{$self->{targets}} if (scalar(@{$self->{targets}}));
  $self->do_log("LOG_DEBUG", "Removing inactive ouputs");
  my $active = $self->get_active();
  # If specific targets were not defined, use all active
  unless (scalar(@t)) {
    @t = keys(%$active);
    push(@{$self->{error}}, "No target outputs") unless (scalar(@t));
  }
  $self->do_log("LOG_DEBUG", "Looping desired ouputs");
  foreach my $target (@t) {
    $self->do_log("LOG_DEBUG", "Ensuring that desired output is active");
    unless (defined($active->{$target})) {
      $self->do_log('LOG_DEBUG', "Target $target is not an active output");
      next;
    }
    $self->do_log("LOG_DEBUG", "Selecting image for $target");
    my $image = $self->choose_image();
    if (defined($image)) {
      $self->do_log('LOG_DEBUG', "Selected $image");
      if ( -r "$image" ) {
        my $cropped;
        if ($self->{crop}) {
          $self->do_log('LOG_DEBUG',"Cropping image for '$target' using '$image'");
          $cropped = $self->crop(
            $image,
            $active->{$target}->{rect}->{width},
            $active->{$target}->{rect}->{height}
          );
          if (!$cropped) {
            # Create a tmp copy since it will be deleted later
            # If PWD is the wallpaper path, make the tmp in /tmp
            if ($self->{path} eq $ENV{PWD}) {
              $cropped = $image;
              $cropped =~ s%$ENV{PWD}%/tmp%;
            # Else make the tmp in PWD
            } else {
              $cropped = '/'.$image;
              $cropped =~ s%.*/([^/+])%$ENV{PWD}/$1%;
            }
            $self->do_log('LOG_DEBUG',"Creating copy of original: $cropped");
            File::Copy::copy($image,$cropped) || $self->do_log('LOG_WARNING',"Failed to copy to $cropped: $!");
          }
        } else {
          $self->do_log('LOG_DEBUG', "Cropping is disabled");
          $cropped = $image;
        }
        $self->set_background($target,$cropped);
        if ($self->{crop}) {
          # Give swaybg a second, otherwise the file will be missing before it ends
          sleep(1);
          $self->do_log('LOG_DEBUG', "Deleting $cropped");
          unlink($cropped) || $self->do_log("LOG_WARNING", "Failed to delete $cropped after setting: $!");
        }
      } else {
        $self->do_log("LOG_WARNING", "Failed to read $image");
      }
    } else {
      $self->do_log("LOG_WARNING", "Failed to select image from $self->{path}");
    }
  }
}

################################################################################
# Collect arguments
################################################################################
my @targets;
my $daemon;
my $delay;
my $crop;
my $path;
my $verbose;
my $recursive = 0;
while (my $arg = shift(@ARGV)) {
  if ($arg eq '-h' || $arg eq '--help') {
    $wp->usage();
  } elsif ($arg =~ m/^\-\-path=?(.+)$/) {
    die "Redundant argument '$arg'. Wallpaper path already set.\n" if ($path);
    $path = $1;
  } elsif ($arg eq '-p') {
    die "Redundant argument '$arg'. Wallpaper path already set.\n" if ($path);
    $path = shift(@ARGV);
  } elsif ($arg =~ m/^\-\-daemon=?(.+)?$/) {
    die "Redundant argument '$arg'. Daemon mode already set.\n" if ($daemon);
    $delay = $1 || 300;
    $daemon = 1;
  } elsif ($arg eq '-d') {
    die "Redundant argument '$arg'. Daemon mode already set.\n" if ($daemon);
    if (scalar(@ARGV) && $ARGV[0] =~ m/^\d+$/) {
      $delay = shift(@ARGV);
    }
    $daemon = 1;
  } elsif ($arg eq '--nocrop' || $arg eq '-n') {
    die "Redundant argument '$arg'. No-crop already set.\n" if (defined($crop));
    $crop = 0;
  } elsif ($arg =~ m/^\-\-verbose=?(.+)?$/) {
    die "Redundant argument '$arg'. Verbosity already set.\n" if ($verbose);
    $verbose = $1 || 1;
  } elsif ($arg eq '-v') {
    die "Redundant argument '$arg'. Verbosity already set.\n" if ($verbose);
    if (scalar(@ARGV) && $ARGV[0] =~ m/^\d$/) {
      $verbose = shift(@ARGV);
    }
  } elsif ($arg =~ m/^\-\-recursive=?(.+)?$/) {
    die "Redundant argument '$arg'. Recursive search already set.\n" unless ($recursive == 0);
    $recursive = $1 || -1;
  } elsif ($arg eq '-r') {
    die "Redundant argument '$arg'. Recursive search already set.\n" unless ($recursive == 0);
    if (scalar(@ARGV) && $ARGV[0] =~ m/^\d+$/) {
      $recursive = shift(@ARGV);
    } else {
      $recursive = -1;
    }
  } elsif ($arg =~ m/^-/) {
    die "Unrecognized argument: $arg\n";
  } else {
    push(@targets,$arg);
  }
}

################################################################################
# Validate arguments
################################################################################

$wp->do_log("LOG_DEBUG", "Validating arguments");
die "Invalid rotation delay: $delay" if (defined($delay) && $delay !~ m/^\d+$/);
die "Invalid wallpaper path '$path'. Not a directory." if (defined($path) && !-d $path);
die "Invalid verbosity level: '$verbose'\n" if (defined($verbose) && $verbose !~ m/^[1-8]$/);

$wp->do_log("LOG_DEBUG", "Configuring object");
$wp->{targets}  = \@targets || \();
$wp->{daemon}   = $daemon || 0;
$wp->{path}     = $path || "$ENV{HOME}/wallpapers";
$wp->{crop}     = $crop || 1;
$wp->{delay}    = $delay || 300;
$wp->{verbose}  = $verbose || 0;
$wp->{recursive}= $recursive;
$wp->{error}    = [];

unless(defined($wp->{targets})) {
  if (open(my $fh, '<', $wp->{outputfile})) {
    $wp->do_log("LOG_DEBUG", "No outputs requested, using cache file $wp->{outputfile}\n");
    while (my $o = <$fh>) {
      chomp($o);
      push (@{$wp->{targets}}, $o) if ($o);
    }
    $wp->do_log("LOG_DEBUG", "Found cached outputs: ".join(', ', @{$wp->{targets}})."\n") if (scalar(@{$wp->{targets}})."\n");
  } else {
    $wp->do_log("LOG_WARNING", "Failed to load $wp->{outputfile}\n");
  }
  unless (scalar(@{$wp->{targets}})) {
    $wp->{'targets'} = \$wp->get_outputs();
    if (scalar(@{$wp->{targets}})) {
      $wp->do_log("LOG_WARNING", "Using all available outputs ".join(', ', @{$wp->{targets}})."\n");
    } else {
      $wp->do_log("LOG_INFO", "Failed to discover any available outputs.\n", 1);
    }
  }
}

################################################################################
# Fork if daemonized
################################################################################

if ($wp->{daemon}) {
  $wp->do_log("LOG_DEBUG", "Forking daemon");
  my $p = fork();
  if ($p) {
    $wp->do_log("LOG_DEBUG", "Writing PID ($p) to pidfile ($wp->{pidfile})");
    if (open(my $fh, ">", $wp->{pidfile})) {
      print $fh "$p" || die "Failed to write pid ($p) to pidfile ".$wp->{pidfile};
      close($fh);
    } else {
      print "Failed to open pidfile ".$wp->{pidfile}.": $!\n";
    }
    # Short delay necessary for SystemD to find PID
    sleep(1);
    exit(0);
  }
  $wp->do_log("LOG_DEBUG", "Daemon running");
  setpgrp(0, 0);
  umask 0;
}

################################################################################
# Main
################################################################################

my $first = 1;
do {
  $wp->do_log("LOG_INFO", "Reloading wallpaper") unless ($first);
  $wp->run();
  if ($wp->{daemon}) {
    my $normal = "reload wallpaper";
    eval {
      $SIG{ALRM} = sub { return "$normal" };
      alarm $wp->{delay};
      POSIX::pause();
      alarm 0;
    };
    $wp->do_log("LOG_WARNING", "Reload failed: $@") if ($@ && $@ !~ quotemeta($normal));
  }
  $first = 0 if ($first);
} while ($wp->{daemon});

# If we made it to here, it was not daemonized. Output errors and exit
$wp->do_log("LOG_DEBUG", "Finishing") unless ($wp->{daemon});

exit(0);
