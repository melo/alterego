package Bot::AlterEgo::Plugins::UserLocation;

use strict;
use warnings;
use utf8;
use base qw( Bot::AlterEgo::Plugin );
use Net::DefaultGateway;
use Net::ArpTable;
use Config::Any;

sub init {
  my ($self) = @_;
  my $bot = $self->bot;
  
  $bot->add_listener('on_online', sub { $self->check_location });
#  $bot->each_interval(60, sub { $self->check_location });
}

sub check_location {
  my ($self) = @_;
  
  # Not connected, forget about it
  return unless $self->bot->is_ready;
  
  my $gateway = Net::DefaultGateway->find;
  return unless $gateway;
  print "UserLocation: found gateway $gateway\n";
  $| = 1;
  my $mac_addr = Net::ArpTable->mac_for_ip($gateway);
  return unless $mac_addr;
  print "UserLocation: found mac $mac_addr for gateway $gateway\n";
  
  my $location_dbs = Config::Any->load_stems({
    stems   => [ ".location_db", "$ENV{HOME}/.location_db" ],
    use_ext => 1,
  });
  
  foreach my $db_spec (@$location_dbs) {
    my ($file, $db) = %$db_spec;
    
    if (exists $db->{$mac_addr}) {
      use Data::Dumper; print STDERR ">>>>>> FOUND LOCATION ", Dumper($db->{$mac_addr});
    }
  }
}


1;
