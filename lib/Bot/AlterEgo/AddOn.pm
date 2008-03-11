package Bot::AlterEgo::AddOn;

use strict;
use warnings;
use base qw( Class::C3::Componentised );
use Carp::Clan qw(^Bot::AlterEgo::AddOn);


sub _req_params {
  my ($self, $args, @params) = @_;
  my @results;

  foreach my $param (@params) {
    croak("FATAL: missing required parameter '$param', ")
      unless exists $args->{$param};
    push @results, $args->{$param};
  }
  
  return @results;
}

1;
