package TestServers;
use strict;
use warnings;
use Path::Tiny;
use File::Temp;
use JSON::PS;
use Promise;
use Promised::Flow;
use Promised::File;
use Promised::Command;
use Promised::Command::Signals;
use Promised::Mysqld;
use Web::URL;
use Web::Transport::ConnectionClient;

my $RootPath = path (__FILE__)->parent->parent->parent->absolute;

sub mysqld ($$$) {
  my ($db_dir, $db_name, $set_dsn) = @_;
  $db_name = 'test_' . int rand 100000;
  my $mysqld = Promised::Mysqld->new;
  $mysqld->set_db_dir ($db_dir) if defined $db_dir;
  return $mysqld->start->then (sub {
    return promised_for {
      return Promised::File->new_from_path ($_[0])->read_byte_string->then (sub {
        return $mysqld->create_db_and_execute_sqls ($db_name, [grep { length } split /;/, $_[0]]);
      });
    } [sort { $a cmp $b } $RootPath->child ('db')->children (qr/^gruwa-[0-9]+\.sql$/)];
  })->then (sub {
    $set_dsn->($mysqld->get_dsn_string (dbname => $db_name));
    my ($p_ok, $p_ng);
    my $p = Promise->new (sub { ($p_ok, $p_ng) = @_ });
    return [sub {
      return $mysqld->stop->then ($p_ok, $p_ng);
    }, $p];
  });
} # mysqld

sub web ($$$) {
  my ($port, $config_file, $dsn_got) = @_;
  my $command = Promised::Command->new
      ([$RootPath->child ('perl'), $RootPath->child ('bin/server.pl'), $port]);
  my $temp;
  my $wait;
  if (ref $config_file eq 'HASH') {
    $temp = File::Temp->new;
    $command->envs->{CONFIG_FILE} = $temp;
    $wait = Promised::File->new_from_path ($temp)->write_byte_string (perl2json_bytes $config_file);
  } else {
    $command->envs->{CONFIG_FILE} = $config_file;
  }
  my $stop = sub {
    $command->send_signal ('TERM');
    undef $temp;
    return $command->wait;
  }; # $stop
  my ($ready, $failed);
  my $p = Promise->new (sub { ($ready, $failed) = @_ });
  $dsn_got->then (sub {
    $command->envs->{DATABASE_DSN} = $_[0];
    return $wait;
  })->then (sub {
    return $command->run;
  })->then (sub {
    $command->wait->then (sub {
      $failed->($_[0]);
    });
    my $origin = Web::URL->parse_string (qq<http://localhost:$port>);
    return promised_timeout {
      return promised_wait_until {
        my $client = Web::Transport::ConnectionClient->new_from_url ($origin);
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

sub servers ($%) {
  shift;
  my %args = @_;
  my $set_dsn;
  my $dsn_got = Promise->new (sub { $set_dsn = $_[0] });

  return Promise->all ([
    mysqld ($args{db_dir}, $args{db_name}, $set_dsn),
    web ($args{port}, $args{config} // $args{config_file}, $dsn_got),
  ])->then (sub {
    my $stops = $_[0];
    my @stopped = map { $_->[1] } @$stops;
    my @signal;

    my $stop = sub {
      @signal = ();
      return Promise->all ([map {
        my ($stop) = @$_;
        Promise->resolve->then ($stop)->catch (sub {
          warn "ERROR: $_[0]";
        });
      } @$stops]);
    }; # $stop

    push @signal, Promised::Command::Signals->add_handler (INT => $stop);
    push @signal, Promised::Command::Signals->add_handler (TERM => $stop);
    push @signal, Promised::Command::Signals->add_handler (KILL => $stop);

    return [$stop, sub {
      @signal = ();
      return Promise->all ([map {
        $_->catch (sub {
          warn "ERROR: $_[0]";
        });
      } @stopped])
    }];
  });
} # servers

1;

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
