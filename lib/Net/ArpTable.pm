package
  Net::ArpTable; # Hide from PAUSE - we'll move this to a proper module eventually

use strict;
use warnings;
use Module::Pluggable
  search_path => [qw(  Net::ArpTable::Methods )],
  require     => 1,
  sub_name    => '_raw_methods',
  ;


my $init_done;
my @methods;
my %orders = (
  'first'  => 1,
  'normal' => 50,
  'last'   => 100,
);

sub _init_method_list {
  my ($class) = @_;
  
  return if $init_done;
  my @new_methods;
  
  METHOD:
  foreach my $method ($class->_raw_methods) {
    my $method_info = $method->register;
    next METHOD unless defined $method_info;
    
    $method_info->{class} ||= $method;
    $method_info->{order} ||= 'normal';
    
    if (my $level = $method_info->{order} !~ /^\d+$/) {
      $method_info->{order} = exists $orders{$level}? $orders{$level} : 50;
    }
    
    push @new_methods, $method_info;
  }
  
  @methods = sort { $a->{order} <=> $b->{order} } @new_methods;
  
  $init_done++;
}


sub methods {
  my ($class) = @_;
  
  $class->_init_method_list;
  
  return wantarray? @methods : \@methods;
}


my $arp_table;
sub _init_arp_table {
  my ($class) = @_;
  
  return if defined $arp_table;
  
  METHOD:
  foreach my $method ($class->methods) {
    $arp_table = $method->{class}->arp_table;
    last METHOD if defined $arp_table;
  }

  $arp_table ||= {};
  
  return;
}


sub _find {
  my ($class, $type, $key) = @_;

  $class->_init_arp_table;

  return $arp_table->{$type}{$key} if exists $arp_table->{$type}{$key};
  return undef;
}


sub mac_for_ip { my $class = shift; return $class->_find('ip2mac', @_) }
sub ip_for_mac { my $class = shift; return $class->_find('mac2ip', @_) }

1;
