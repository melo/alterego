package
  Net::DefaultGateway::Methods::Netstat;

sub register {
  return {
    order => 'last',
    desc  => 'Use netstat command line tool',
  };
}

sub default_gateway {
  my ($class) = @_;
  my ($gateway, $error);
  
  if (open(my $netstat, '-|', '/usr/bin/env netstat -rn')) {
    while (my $route = <$netstat>) {
      next unless $route =~ m/^(?:default|0[.]0[.]0[.]0)\s+(\d+[.]\d+[.]\d+[.]\d+)\s+/;
      $gateway = $1;
      last;
    }
    close($netstat);
  }
  
  return $gateway;
}

1;
