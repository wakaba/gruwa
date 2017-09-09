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
use Sarze;

my $RootPath = path (__FILE__)->parent->parent->parent->absolute;

{
  use Socket;
  my $EphemeralStart = 1024;
  my $EphemeralEnd = 5000;

  sub is_listenable_port ($) {
    my $port = $_[0];
    return 0 unless $port;
    
    my $proto = getprotobyname('tcp');
    socket(my $server, PF_INET, SOCK_STREAM, $proto) || die "socket: $!";
    setsockopt($server, SOL_SOCKET, SO_REUSEADDR, pack("l", 1)) || die "setsockopt: $!";
    bind($server, sockaddr_in($port, INADDR_ANY)) || return 0;
    listen($server, SOMAXCONN) || return 0;
    close($server);
    return 1;
  } # is_listenable_port

  my $using = {};
  sub find_listenable_port () {
    for (1..10000) {
      my $port = int rand($EphemeralEnd - $EphemeralStart);
      next if $using->{$port}++;
      return $port if is_listenable_port $port;
    }
    die "Listenable port not found";
  } # find_listenable_port
}

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

sub storage (%) {
  my %args = @_;

  my $data_path = $args{data_path} // $args{work_path}->child ('minio-data');
  my $config_path = $args{config_path} // $args{work_path}->child ('minio-config');
  my $host = '127.0.0.1';
  my $port = find_listenable_port;

  my $cmd = Promised::Command->new
      ([$RootPath->child ('local/bin/minio'), 'server',
        '--address', $host . ':' . $port,
        '--config-dir', $config_path,
        $data_path]);
  my $data = {aws4 => [undef, undef, undef, 's3'],
              url => "http://$host:$port"};
  return $cmd->run->then (sub {
    return promised_wait_until {
      return Promised::File->new_from_path ($config_path->child ('config.json'))->read_byte_string->then (sub {
        my $config = json_bytes2perl $_[0];
        $data->{aws4}->[0] = $config->{credential}->{accessKey};
        $data->{aws4}->[1] = $config->{credential}->{secretKey};
        $data->{aws4}->[2] = $config->{region};
        return defined $data->{aws4}->[0] &&
               defined $data->{aws4}->[1] &&
               defined $data->{aws4}->[2];
      })->catch (sub { return 0 });
    } timeout => 60*3;
  })->then (sub {
    $args{send_data}->($data);
    return [sub {
      $cmd->send_signal ('TERM');
      return $cmd->wait;
    }, $cmd->wait];
  });
} # storage

sub web ($$$$%) {
  my ($port, $config, $adata_got, $dsn_got, %args) = @_;
  my $command = Promised::Command->new
      ([$RootPath->child ('perl'), $RootPath->child ('bin/server.pl'), $port]);
  my $temp = File::Temp->new;
  $command->envs->{CONFIG_FILE} = $temp;
  my $wait = Promise->all ([
    $adata_got,
    $args{receive_storage_data},
  ])->then (sub {
    my ($adata, $sdata) = @{$_[0]};
    $config->{accounts} = $adata if defined $adata;
    if (defined $sdata) {
      $config->{storage}->{aws4} = $sdata->{aws4};
      $config->{storage}->{url} = $sdata->{url};
    }
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

sub accounts ($$$) {
  my ($set_adata, $mysqld_got, $ext_url_got) = @_;
  require Test::AccountServer;
  my $as = Test::AccountServer->new;
  return $mysqld_got->then (sub {
    $as->set_mysql_server ($_[0]);
    return $ext_url_got;
  })->then (sub {
    my $ext_url = $_[0];
    $as->onbeforestart (sub {
      my ($self, %args) = @_;
      $args{servers}->{test1} = {
        name => 'test1',
        url_scheme => $ext_url->scheme,
        host => $ext_url->hostport,
        auth_endpoint => '/authorize',
        token_endpoint => '/token',
        linked_id_field => 'access_token',
      };
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

sub ext_server ($) {
  my ($set_url) = @_;
  my $host = '127.0.0.1';
  my $port = find_listenable_port;
  $set_url->(Web::URL->parse_string ("http://$host:$port"));
  return Sarze->start (
    hostports => [[$host, $port]],
    eval => q{
      use strict;
      use warnings;
      use Wanage::HTTP;
      use Warabe::App;
      use JSON::PS;
      my $Tokens = {};
      sub psgi_app {
        my $http = Wanage::HTTP->new_from_psgi_env (shift);
        my $app = Warabe::App->new_from_http ($http);
        $app->execute_by_promise (sub {
          if ($app->http->url->{path} eq '/authorize') {
            my $state = $app->bare_param ('state');
            my $code = rand;
            my $token = rand;
            $Tokens->{$code} = $token;
            $app->http->set_response_header ('X-Code', $code);
            $app->http->set_response_header ('X-State', $state);
            return $app->send_error (200);
          } elsif ($app->http->url->{path} eq '/token') {
            my $code = $app->bare_param ('code');
            my $token = delete $Tokens->{$code};
            return $app->send_error (404) unless defined $token;
            my $result = {access_token => $token, token_type => 'bearer'};
            $app->http->set_response_header ('Content-Type', 'application/json');
            $app->http->send_response_body_as_ref (\perl2json_bytes $result);
            return $app->http->close_response_body;
          }
          return $app->send_error (404);
        });
      }
    },
    max_worker_count => 1,
  )->then (sub {
    my $sarze = $_[0];
    return [sub { return $sarze->stop }, $sarze->completed];
  });
} # ext_server

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
  my $set_ext_url;
  my $ext_url_got = Promise->new (sub { $set_ext_url = $_[0] });
  my ($r_storage, $s_storage) = promised_cv;
  my $port = $args{port} ? $args{port} : find_listenable_port;
  my $url = Web::URL->parse_string ("http://localhost:$port");
  if (not defined $args{port}) {
    $args{config}->{origin} = $url->get_origin->to_ascii;
  }

  return Promise->all ([
    mysqld ($args{db_dir}, $args{db_name}, $args{migration_status_file}, $args{dumped_file}, $set_dsn, $set_mysqld),
    storage (
      work_path => $args{work_path},
      data_path => $args{storage_data_path},
      config_path => $args{storage_config_path},
      send_data => $s_storage,
    ),
    web ($port, $args{config}, $adata_got, $dsn_got,
      receive_storage_data => $r_storage,
    ),
    defined $args{onaccounts} ? accounts ($set_adata, $mysqld_got, $ext_url_got) : $set_adata->(undef),
    ext_server ($set_ext_url),
    Promise->resolve ($url)->then ($args{onurl})->then (sub { [] }),
  ])->then (sub {
    my $stops = $_[0];
    my @stopped = grep { defined } map { $_->[1] } @$stops;
    my @signal;

    my $stop = sub {
      my $cancel = $_[0] || sub { };
      $cancel->();
      @signal = ();
      return Promise->all ([map {
        my ($stop) = @$_;
        Promise->resolve->then ($stop)->catch (sub {
          warn "$$: ERROR: $_[0]";
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
          warn "$$: ERROR: $_[0]";
        });
      } @stopped])
    }];
  });
} # servers

1;

=head1 LICENSE

Copyright 2016-2017 Wakaba <wakaba@suikawiki.org>.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You does not have received a copy of the GNU Affero General Public
License along with this program, see <https://www.gnu.org/licenses/>.

=cut
