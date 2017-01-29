package TestServers;
use strict;
use warnings;
use Path::Tiny;
use lib path (__FILE__)->parent->parent->parent->child ('local/accounts/t_deps/lib')->stringify;
use lib path (__FILE__)->parent->parent->parent->child ('local/accounts/t_deps/modules/promised-plackup/lib')->stringify;
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

sub mysqld ($$$$$$) {
  my ($db_dir, $db_name, $migration_status_file, $dumped_file, $set_dsn, $set_mysqld) = @_;
  $db_name = 'test_' . int rand 100000 unless defined $db_name;
  my $mysqld = Promised::Mysqld->new;
  $mysqld->set_db_dir ($db_dir) if defined $db_dir;
  return $mysqld->start->then (sub {
    $set_mysqld->($mysqld);
    if (defined $migration_status_file) {
      my $file = Promised::File->new_from_path ($migration_status_file);
      return $file->is_file->then (sub {
        return unless $_[0];
        return $file->read_byte_string->then (sub {
          return json_bytes2perl $_[0];
        });
      });
    } else {
      return {};
    }
  })->then (sub {
    my $status = $_[0];
    my $changed = 0;
    return Promise->resolve->then (sub {
      return promised_for {
        return Promised::File->new_from_path ($_[0])->read_byte_string->then (sub {
          $changed = 1;
          return $mysqld->create_db_and_execute_sqls ($db_name, [grep { length } split /;/, $_[0]]);
        });
      } [sort { $a cmp $b } grep { not $status->{$_}++ } $RootPath->child ('db')->children (qr/^gruwa-[0-9]+\.sql$/)];
    })->then (sub {
      if (defined $migration_status_file) {
        return Promised::File->new_from_path ($migration_status_file)->write_byte_string (perl2json_bytes $status);
      }
    })->then (sub {
      return unless defined $dumped_file;
      return unless $changed;
      my $opts = $mysqld->get_dsn_options;
      my @opt = ('--no-data');
      push @opt, '-u' . $opts->{user} if defined $opts->{user};
      push @opt, '-p' . $opts->{password} if defined $opts->{password};
      push @opt, '-h' . $opts->{host} if defined $opts->{host};
      push @opt, '-P' . $opts->{port} if defined $opts->{port};
      push @opt, '-S' . $opts->{mysql_socket} if defined $opts->{mysql_socket};
      my $cmd = Promised::Command->new ([
        'mysqldump',
        @opt,
        $db_name,
      ]);
      $cmd->stdout (\my $dumped);
      return $cmd->run->then (sub {
        return $cmd->wait;
      })->then (sub {
        die $_[0] unless $_[0]->exit_code == 0;
        return Promised::File->new_from_path ($dumped_file)->write_byte_string ($dumped);
      });
    });
  })->then (sub {
    $set_dsn->($mysqld->get_dsn_string (dbname => $db_name));
    my ($p_ok, $p_ng);
    my $p = Promise->new (sub { ($p_ok, $p_ng) = @_ });
    return [sub {
      return $mysqld->stop->then ($p_ok, $p_ng);
    }, $p];
  });
} # mysqld

sub web ($$$$) {
  my ($port, $config, $adata_got, $dsn_got) = @_;
  my $command = Promised::Command->new
      ([$RootPath->child ('perl'), $RootPath->child ('bin/server.pl'), $port]);
  my $temp = File::Temp->new;
  $command->envs->{CONFIG_FILE} = $temp;
  my $wait = Promise->resolve ($adata_got)->then (sub {
    my $adata = $_[0];
    $config->{accounts} = $adata if defined $adata;
    return Promised::File->new_from_path ($temp)->write_byte_string
        (perl2json_bytes $config);
  });
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
    return promised_wait_until {
      my $client = Web::Transport::ConnectionClient->new_from_url ($origin);
      return $client->request (path => ['robots.txt'])->then (sub {
        return not $_[0]->is_network_error;
      });
    } timeout => 60*2;
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

sub accounts ($$) {
  my ($set_adata, $mysqld_got) = @_;
  return $mysqld_got->then (sub {
    require Test::AccountServer;
    my $as = Test::AccountServer->new;
    $as->set_mysql_server ($_[0]);
    $as->onbeforestart (sub {
      my ($self, $args) = @_;
      #
    });
    return $as->start->then (sub {
      my $account_data = $_[0];
      my $adata = {
        url => Web::URL->parse_string ("http://$account_data->{host}")->stringify,
        key => $account_data->{keys}->{'auth.bearer'},
        context => rand,
        servers => ['test1'],
      };
      $set_adata->($adata);

      my $stop;
      my $stopped = Promise->new (sub { $stop = $_[0] });
      return [sub { return &promised_cleanup ($stop, $as->stop) }, $stopped];
    });
  });
} # accounts

sub servers ($%) {
  shift;
  my %args = @_;
  my $set_dsn;
  my $dsn_got = Promise->new (sub { $set_dsn = $_[0] });
  my $set_mysqld;
  my $mysqld_got = Promise->new (sub { $set_mysqld = $_[0] });
  my $set_adata;
  my $adata_got = Promise->new (sub { $set_adata = $_[0] });
  $adata_got->then ($args{onaccounts}) if defined $args{onaccounts};

  return Promise->all ([
    mysqld ($args{db_dir}, $args{db_name}, $args{migration_status_file}, $args{dumped_file}, $set_dsn, $set_mysqld),
    web ($args{port}, $args{config}, $adata_got, $dsn_got),
    defined $args{onaccounts} ? accounts ($set_adata, $mysqld_got) : $set_adata->(undef),
  ])->then (sub {
    my $stops = $_[0];
    my @stopped = grep { defined } map { $_->[1] } @$stops;
    my @signal;

    my $stop = sub {
      @signal = ();
      return Promise->all ([map {
        my ($stop) = @$_;
        Promise->resolve->then ($stop)->catch (sub {
          warn "ERROR: $_[0]";
        });
      } grep { defined } @$stops]);
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
