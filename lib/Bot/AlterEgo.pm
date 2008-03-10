package Bot::AlterEgo;

use strict;
use warnings;
use utf8;
use Config::Any;
use Net::XMPP2::IM::Connection;
use Net::XMPP2::Ext::Disco;
use Data::Dumper;
use Module::Pluggable
  search_path => [qw( Bot::AlterEgo::Plugins )],
  require     => 1,
  ;


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
    session_ready => sub { shift; $self->_on_online(@_)  },
    disconnect    => sub { shift; $self->_on_offline(@_) },
    message       => sub { shift; $self->_on_message(@_) },
  );
  
  # Suport debug cfg option
  $con->reg_cb(
    debug_recv   => sub { print STDERR "IN:  $_[1]\n" },
    debug_send   => sub { print STDERR "OUT: $_[1]\n" },
  ) if $cfg->{debug};
  
  # Support XEP-0030: Disco
  my $disco = $self->{disco} = Net::XMPP2::Ext::Disco->new;
  $con->add_extension ($disco);
  $disco->set_identity('client', 'bot', 'Alter Ego');
  
  # Load all of our plugins
  $self->init_plugins;
  
  return $self;
}

sub connect {
  my ($self) = @_;
  
  return if $self->is_ready;
  
  # Connect and init
  my $con = $self->con;
  my $connected;
  do {
    $connected = $con->connect;
  } while (!$connected && $con->may_try_connect);
  die "Could not connect to server: $!, " if !$connected;
  
  $con->init;
}

sub start {
  my ($self) = @_;
  
  $self->connect;
  AnyEvent->condvar->wait;
}

sub init_plugins {
  my ($self) = @_;
  
  my $plugins = $self->{plugins} = [];
  foreach my $plugin ($self->plugins) {
    push @$plugins, $plugin->new($self);
  }
  
  return;
}

###############
# Our own Hooks

sub _on_online {
  my ($self) = @_;
  
  $self->{ready} = 1;
  print STDERR "ONLINE! :)\n";
  $self->notify('on_online');
  $self->_initial_presence;
}

sub _on_offline {
  my ($self) = @_;
  
  $self->{ready} = 0;
  print STDERR "OFFLINE! :(\n";
  $self->notify('on_offline');
}

sub _initial_presence {
  my ($self) = @_;
  
  my $con = $self->con;
  $con->send_presence(undef, undef,
    status   => 'AlterEgo bot is here!',
    priority => -1,
  );
  print STDERR "INITIAL presence sent\n";

  $self->notify('on_presence_set');
}

sub _on_message {
  my ($self, $message) = @_;
  
  my $handled = 0;
  $self->notify('on_message', $message, \$handled);
  
  print STDERR "Unhandled message received\n" unless $handled;
}


########################
# API for plugins to use

sub hooks {
  my ($self, $hook) = @_;
  
  croak("FATAL: requires 'hook' parameter, ") unless defined $hook;
  
  return $self->{hooks}{$hook} ||= [];
}

sub add_listener {
  my ($self, $hook, $cb) = @_;
  
  my $hooks = $self->hooks($hook);
  push @$hooks, $cb;
  
  return;
}

sub notify {
  my ($self, $hook, @params) = @_;

  my $listeners = $self->hooks($hook);
  foreach my $listener (@$listeners) {
    eval { $listener->(@params) };
    if (my $e = $@) {
      print STDERR "Listener of '$hook' dieed: $e";
      die $e;
    }
  }
  
  return;
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
