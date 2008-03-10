package
  Net::ArpTable::Methods::Arp;

sub register {
  return {
    order => 'last',
    desc  => 'Use arp command line tool',
  };
}

sub arp_table {
  my ($class) = @_;
  my %arp_table;
  
  my $valid_arp_entry_re = qr{
    (\d+[.]\d+[.]\d+[.]\d+)    # Match IP Address
    .+                         # and further along
    (                          # Match a hardware mac address
      (?:                      #    a set of
        [A-Fa-f0-9]{1,2}       #      one or two chars hexa
        :                      #      followed by a colon
      ){5}                     #    five time of those
      [A-Fa-f0-9]{1,2}         #    and a one or two chars hexa
    )                          #
  }x;
  
  if (open(my $arp, '-|', '/usr/bin/env arp -an')) {
    while (my $entry = <$arp>) {
      next unless $entry =~ m/$valid_arp_entry_re/;
      my ($ip, $mac) = ($1, $2);
      
      # normalize mac address
      $mac = lc($mac);
      $mac =~ s/\b0\b/00/g;
      
      $arp_table{ip2mac}{$ip}  = $mac;
      $arp_table{mac2ip}{$mac} = $ip;
    }
    close($arp);
  }
  
  return \%arp_table;
}

1;
