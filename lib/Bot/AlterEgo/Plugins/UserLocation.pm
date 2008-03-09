package Bot::AlterEgo::Plugins::UserLocation;

use strict;
use warnings;
use utf8;
use base qw( Bot::AlterEgo::Plugin );

sub init {
  my ($self) = @_;
  
  print STDERR "Eia, User location is live!\n";
}

1;
