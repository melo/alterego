package Bot::AlterEgo::Plugins::UserLocation;

use strict;
use warnings;
use utf8;
use base qw( Bot::AlterEgo::Plugin );
use Net::DefaultGateway;
use Net::ArpTable;
use Config::Any;
use DateTime;

__PACKAGE__->load_components(qw( PubSub ));


sub init {
  my ($self) = @_;
  my $bot = $self->bot;
  
  $bot->add_listener('on_online', sub { $self->check_location });
  $self->{timer} = $bot->each_interval(60, sub { $self->check_location });
  
  $bot->add_feature('http://jabber.org/protocol/geoloc');
  $bot->add_feature('http://jabber.org/protocol/geoloc+notify');
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
      my @geo;
      my $data = $db->{$mac_addr};
      
      return unless $self->is_new_location($data);
      
      $self->bot->notify('/user_location/changed', $data);
      
      my %geo = %$data;
      $geo{timestamp} = DateTime->now->iso8601."Z";
      while (my ($tag, $value) = each %geo) {
        push @geo, {
          name   => $tag,
          childs => [ $value ],
        };
      }
      
      $self->publish({
        node    => 'http://jabber.org/protocol/geoloc',
        payload => {
          name   => 'geoloc',
          defns  => 'http://jabber.org/protocol/geoloc',
          attrs  => [ 'xml:lang' => 'en' ],
          childs => \@geo,
        },
        ok_cb => sub { print STDERR "GeoLocation was set to $data->{description}!\n" }
      });
    }
  }
}

my $current_location;
sub is_new_location {
  my ($self, $new) = @_;
  my $equal = 1;
  
  if (!$current_location) {
    $current_location = $new;
    return 1;
  }
  
  FIELD:
  foreach my $field (qw( description lat long )) {
    # Catch "one exists, other doesn't"
    if (exists $current_location->{$field} ^ exists $new->{$field}) {
      $equal = 0;
      last FIELD;
    }
    # Catch "Neither exists"
    next FIELD unless exists $new->{$field};
    
    my $c = $current_location->{$field};
    my $n = $new->{$field};
    
    # Catch "one is defined, other isn't"
    if (defined($c) ^ defined($n)) {
      $equal = 0;
      last FIELD;
    }
    # Catch "Neither is defined"
    next FIELD unless defined($c);
    
    # Both exist and are defined, so compare
    if ($c ne $n) {
      $equal = 0;
      last FIELD;
    }
  }
  
  return 0 if $equal;
  
  $current_location = $new;
  return 1;
}

1;
