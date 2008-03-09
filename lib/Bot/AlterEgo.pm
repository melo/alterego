package Bot::AlterEgo;

use strict;
use warnings;
use utf8;
use Config::Any;
use Net::XMPP2::IM::Connection;

#############################
# Constructor and bot startup

sub new {
  my ($class) = @_;
  
  my $cfg = $class->_load_config;
  
  # Default values
  $cfg->{connection}{resource} ||= 'AlterEgo';
  $cfg->{connection}{initial_presence} = undef; # Disable automatic initial presence

  my $con = Net::XMPP2::IM::Connection->new(%{$cfg->{connection}});
  my $self = bless { con => $con, ready => 0 }, $class;

  # Std hooks
  $con->reg_cb(
    stream_ready     => sub { $self->on_stream_ready(@_)       },
    initial_presence => sub { $self->send_initial_presence(@_) },
    message          => sub { $self->on_message(@_)            },
  );
  
  # Suport debug cfg option
  $con->reg_cb(
    debug_recv   => sub { print STDERR "IN:  $_[1]\n" },
    debug_send   => sub { print STDERR "OUT: $_[1]\n" },
  ) if $cfg->{debug};

  return $self;
}


############
# Accesssors

sub con      { return $_[0]{con}   }
sub is_ready { return $_[0]{ready} }


#######
# Utils

sub _load_config {
  my ($class) = @_;
  
  my $found = Config::Any->load_stems({
    stems   => [ ".alter_ego_cfg", "$ENV{HOME}/.alter_ego_cfg" ],
    use_ext => 1,
  });
  die "Config file not found, " unless @$found;
  
  # right now we use only the first one, we could use all of them and
  # merge the configs in a future version
  my ($file, $config) = %{$found->[0]};
  
  return $config;
}

1;
