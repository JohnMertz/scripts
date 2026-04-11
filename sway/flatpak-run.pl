#!/usr/bin/env perl
# Simplify `flatpak run`

use strict;
use warnings;
use v5.40;

my ($all, $debug) = ('', '');
my @list = split(/\n/, `flatpak list`);
while (scalar(@ARGV) && $ARGV[0] =~ m/^\-[adh]$/) {
  usage() if ($ARGV[0] eq '-h');
  $all = shift(@ARGV) if ($ARGV[0] eq '-a');
  $debug = shift(@ARGV) if ($ARGV[0] eq '-d');
}

my %apps;
for my $line (@list) {
  my ($name, $id, $version, $branch) = split(/\t/, $line);
  next if ($id =~ /\b(Platform|Codecs)\b/ && !$all);
  $apps{$name} = $id;
}

my $input = shift(@ARGV) || run(choice(sort(map { $apps{$_} } keys(%apps), @ARGV)));

my @candidates;

# Exact id match
foreach my $key (keys(%apps)) {
  if ($apps{$key} eq $input) {
    print("Exact id match: $apps{$key}\n") if ($debug);
    run($input, @ARGV) unless ($all);
    push(@candidates, $input);
  }
}

# Exact name match
if (defined($apps{$input})) {
  print("Exact name match: $input\n") if ($debug);
  run($apps{$input}, @ARGV) unless ($all);
  push(@candidates, $apps{$input});
}

# Case-insensitive name match
foreach my $key (keys(%apps)) {
  print("Case-insensitive name match: $key\n") if ($key =~ m/^$input$/i && !scalar(grep(/^$apps{$key}$/, @candidates)) && $debug);
  push(@candidates, $apps{$key}) if ($key =~ m/^$input$/i && !scalar(grep(/^$apps{$key}$/, @candidates)));
}
run(choice(@candidates), @ARGV) if (scalar(@candidates) && !$all);

# Exact final id stanza
foreach my $key (keys(%apps)) {
  print("Exact final id stanza match: $apps{$key}\n") if ($apps{$key} =~ m/\.$input$/ && !scalar(grep(/^$apps{$key}$/, @candidates)) && $debug);
  push(@candidates, $apps{$key}) if ($apps{$key} =~ m/\.$input$/ && !scalar(grep(/^$apps{$key}$/, @candidates)));
}
run(choice(@candidates), @ARGV) if (scalar(@candidates) && !$all);

# Case-insensitive final id stanza
foreach my $key (keys(%apps)) {
  print("Case-insensitive final id match: $apps{$key}\n") if ($apps{$key} =~ m/\.$input$/i && !scalar(grep(/^$apps{$key}$/, @candidates)) && $debug);
  push(@candidates, $apps{$key}) if ($apps{$key} =~ m/\.$input$/i && !scalar(grep(/^$apps{$key}$/, @candidates)));
}
run(choice(@candidates), @ARGV) if (scalar(@candidates) && !$all);

# Fuzzy name match
foreach my $key (keys(%apps)) {
  print("Fuzzy name match: $key\n") if ($key =~ m/$input/i && !scalar(grep(/^$apps{$key}$/, @candidates)) && $debug);
  push(@candidates, $apps{$key}) if ($key =~ m/$input/i && !scalar(grep(/^$apps{$key}$/, @candidates)));
}
run(choice(@candidates), @ARGV) if (scalar(@candidates) && !$all);

# Fuzzy id match
foreach my $key (keys(%apps)) {
  print("Fuzzy id match: $apps{$key}\n") if ($apps{$key} =~ m/$input/i && !scalar(grep(/^$apps{$key}$/, @candidates)) && $debug);
  push(@candidates, $apps{$key}) if ($apps{$key} =~ m/$input/i && !scalar(grep(/^$apps{$key}$/, @candidates)));
}
run(choice(@candidates), @ARGV) if (scalar(@candidates));

print("Failed to match an application for '$input'\nAvailable applications are: ".join("\n",keys(%apps))."\n");

sub usage() {
  print("Usage: $0 [-a|-d|-h] <search>\n\n".
    "Simplified flatpak run script. Accepts a search word and will run the best-matching application, or provide a selection for multiple best-matches\n".
    "\n".
    "  search\n".
    "    Term to search for in flatpak name or id. If omitted, all flatpaks will be provide as selections.\n".
    "  -a\n".
    "    Perform all search types and display all matches as options. As opposed to the 'best-match' method described below. Also include 'Platform' and 'Codecs' results.\n".
    "  -d\n".
    "    Print DEBUG information. Displays match information by type while searching.\n".
    "  -h\n".
    "    This menu.\n".
    "\n".
    "The 'best-match' search methods will be tried in order:\n".
    "  * Exact id match\n".
    "  * Exact name match\n".
    "  * Case-insensitive name match\n".
    "  * Exact id last stanza match\n".
    "  * Case-insensitive last id match\n".
    "  * Fuzzy name match\n".
    "  * Fuzzy id match\n".
    "\n".
    "Except when '-a' is used, flatpaks containing 'Platform' or 'Codecs' will be ignored.\n"
  );
  exit();
}

sub choice(@list) {
  return $list[0] if (scalar(@list) == 1);
  print("Multiple matches:\n");
  for (my $i = 1; $i <= scalar(@list); $i++) {
    print("$i : $list[$i-1]\n");
  }
  print("Enter your selection: [1-".scalar(@list)."]: ");
  my $choice;
  until ($choice) {
    $choice = <STDIN>;
    chomp($choice);
    unless ($choice =~ m/^\d+$/ && $choice <= scalar(@list)) {
      print("Invalid selection: '$choice'. Try again. [1-".scalar(@list)."]: ");
      $choice = undef;
    }
  }
  return $list[$choice-1];
}

sub run($id, @args) {
  printf("Running $id ".join(' ',@args)."\n");
  my $pid = fork();
  if ($pid) {
    exit();
  } else {
    system("/usr/bin/flatpak run $id ".join(' ', @args));
    exit();
  }
}
