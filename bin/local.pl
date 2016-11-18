use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
BEGIN {
  $ENV{WEBUA_DEBUG} //= 1;
  $ENV{WEBSERVER_DEBUG} //= 1;
  $ENV{PROMISED_COMMAND_DEBUG} //= 1;
}
use Promise;
use Promised::Flow;
use Promised::Command;
use Promised::Command::Signals;
use Promised::Mysqld;
use Web::URL;
use Web::Transport::ConnectionClient;

my $RootPath = path (__FILE__)->parent->parent->absolute;
my $Port = 5521;
my $Origin = Web::URL->parse_string (qq<http://localhost:$Port>);

sub web () {
  my $command = Promised::Command->new
      ([$RootPath->child ('perl'), $RootPath->child ('bin/server.pl'), $Port]);
  $command->envs->{CONFIG_FILE} = $RootPath->child ('config/local.json');
  my $stop = sub {
    $command->send_signal ('TERM');
    return $command->wait;
  }; # $stop
  my ($ready, $failed);
  my $p = Promise->new (sub { ($ready, $failed) = @_ });
  $command->run->then (sub {
    $command->wait->then (sub {
      $failed->($_[0]);
    });
    return promised_timeout {
      return promised_wait_until {
        my $client = Web::Transport::ConnectionClient->new_from_url ($Origin);
        return $client->request (path => ['robots.txt'])->then (sub {
          return not $_[0]->is_network_error;
        });
      };
    } 60*2;
  })->then (sub {
    $ready->([$stop, $command->wait]);
  }, sub {
    my $error = $_[0];
    return $stop->()->catch (sub {
      warn "ERROR: $_[0]";
    })->then (sub { $failed->($error) });
  });
  return $p;
} # web

Promise->all ([
  web,
])->then (sub {
  my $stops = $_[0];
  my @stopped = map { $_->[1] } @$stops;
  my @signal;
  warn "Server is ready!\n";
  warn $Origin->stringify . "\n";

  my $stop = sub {
    @signal = ();
    return Promise->all ([map {
      my ($stop) = @$_;
      Promise->resolve->then ($stop)->catch (sub {
        warn "ERROR: $_[0]";
      });
    } @$stops]);
  };

  push @signal, Promised::Command::Signals->add_handler (INT => $stop);
  push @signal, Promised::Command::Signals->add_handler (TERM => $stop);
  push @signal, Promised::Command::Signals->add_handler (KILL => $stop);

  return Promise->all ([map {
    $_->catch (sub {
      warn "ERROR: $_[0]";
    });
  } @stopped]);
})->to_cv->recv;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You does not have received a copy of the GNU Affero General Public
License along with this program, see <http://www.gnu.org/licenses/>.

=cut
