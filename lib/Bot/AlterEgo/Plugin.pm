package Bot::AlterEgo::Plugin;

use strict;
use warnings;
use base qw( Class::C3::Componentised );

sub new {
  my ($class, $bot) = @_;
  my $self = bless { _bot => $bot }, $class;
  
  $self->init;
  
  return $self;
}

sub init {}

sub bot { return $_[0]{_bot} }

sub component_base_class { "Bot::AlterEgo::AddOns" }

1;
