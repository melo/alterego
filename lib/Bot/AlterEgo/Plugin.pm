package Bot::AlterEgo::Plugin;

use strict;
use warnings;
use utf8;

sub new {
  my ($class, $bot) = @_;
  my $self = bless { _bot => $bot }, $class;
  
  $self->init;
  
  return $self;
}

sub init {}

sub bot { return $_[0]{_bot} }

1;
