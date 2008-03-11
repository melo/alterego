package Bot::AlterEgo::AddOns::PubSub;

use strict;
use warnings;
use base qw( Bot::AlterEgo::AddOn );

sub publish {
  my ($self, $args) = @_;
  
  my ($node, $payload) = $self->_req_params($args, qw( node payload ));
  my $ok_cb    = $args->{ok_cb}    || sub {};
  my $error_cb = $args->{error_cb} || sub {};
  
  $payload = {
    node => {
      attrs  => [ xmlns => 'http://jabber.org/protocol/pubsub' ],
      name   => 'pubsub',
      childs => [
        {
          name   => 'publish',
          attrs  => [ node => $node ],
          childs => [
            {
              name   => 'item',
              childs => [ $payload ],
            }
          ],
        },
      ],
    },
  };
  
  $self->bot->con->send_iq(
    'set',
    $payload,
    sub { $self->_publish_result($ok_cb, $error_cb, @_) },
    to => undef,
  );
}

sub _publish_result {
  my ($self, $ok_cb, $error_cb, $result, undef, $error) = @_;
  
  if    ($error  && $error_cb) { $error_cb->($self, $error, $result) }
  elsif (!$error && $ok_cb)    { $ok_cb->($self, $result)            }
}

1;
