package GruwaSS;
use strict;
use warnings;
use Path::Tiny;
use Promise;
use Promised::File;
use ServerSet;

my $RootPath = path (__FILE__)->parent->parent->parent->absolute;

sub run ($%) {
  ## Arguments:
  ##   app_port       The port of the main application server.  Optional.
  ##   data_root_path Path::Tiny of the root of the server's data files.  A
  ##                  temporary directory (removed after shutdown) if omitted.
  ##   mysqld_database_name_suffix Name's suffix used in mysql database.
  ##                  Optional.
  ##   signal         AbortSignal canceling the server set.  Optional.
  my $class = shift;
  return ServerSet->run ({
    proxy => {
      handler => 'ServerSet::ReverseProxyHandler',
      prepare => sub {
        my ($handler, $self, $args, $data) = @_;
        return {
          client_urls => [],
        };
      }, # prepare
    }, # proxy
    mysqld => {
      handler => 'ServerSet::MySQLServerHandler',
    },
    storage => {
      handler => 'ServerSet::MinioHandler',
    },
    accounts => {
      handler => 'ServerSet::AccountsHandler',
      requires => ['mysqld', 'storage'],
      debug => 1,
    },
    apploach => {
      handler => 'ServerSet::ApploachHandler',
      requires => ['mysqld', 'storage'],
    },
    app_config => {
      requires => ['mysqld', 'storage', 'accounts', 'apploach'],
      keys => {
        accounts_context => 'key:,20',
        accounts_group_context => 'key:,20',
        apploach_app_id => 'id',
      },
      start => sub ($$%) {
        my ($handler, $self, %args) = @_;
        my $data = {};
        return Promise->all ([
          $self->read_json (\($args{app_config_path})),
          $args{receive_storage_data},
          $args{receive_mysqld_data},
        ])->then (sub {
          my ($config, $storage_data, $mysqld_data) = @{$_[0]};
          $data->{config} = $config;

          if ($args{has_accounts}) {
            $config->{accounts}->{key} = $self->key ('accounts_key');
            $config->{accounts}->{context} = $self->key ('accounts_context');
          }

          if ($args{has_apploach}) {
            $config->{apploach}->{key} = $self->key ('apploach_bearer');
            $config->{apploach}->{app_id} = $self->key ('apploach_app_id');
          }
          
          $data->{app_docker_image} = $args{app_docker_image}; # or undef
          my $use_docker = defined $data->{app_docker_image};

          my $dsn_key = $use_docker ? 'docker_dsn' : 'local_dsn';
          $data->{dsn} = $mysqld_data->{$dsn_key}->{gruwa};

          $config->{storage}->{aws4} = $storage_data->{aws4};
          ##"s3_sts_role_arn"
          $config->{storage}->{bucket} = $storage_data->{bucket_domain};
          #$config->{s3_form_url} = $storage_data->{form_client_url}->stringify;
          #$config->{s3_file_url_prefix} = $storage_data->{file_root_client_url}->stringify;
          $config->{storage}->{url} = $self->client_url ('storage');
          $config->{storage}->{client_url_prefix} =~ s{\@\@PORT\@\@}{ $self->local_url ('storage')->port }ge;

          $data->{envs} = my $envs = {};
          if ($use_docker) {
            $self->set_docker_envs ('proxy' => $envs);
          } else {
            $self->set_local_envs ('proxy' => $envs);
          }

          $data->{config_path} = $self->path ('app-config.json');
          return $self->write_json ('app-config.json', $config);
        })->then (sub {
          return [$data, undef];
        });
      },
    }, # app_envs
    app => {
      handler => 'ServerSet::SarzeProcessHandler',
      requires => ['app_config', 'proxy'],
      prepare => sub {
        my ($handler, $self, $args, $data) = @_;
        return Promise->resolve ($args->{receive_app_config_data})->then (sub {
          my $config_data = shift;
          return {
            envs => {
              %{$config_data->{envs}},
              CONFIG_FILE => $config_data->{config_path},
              DATABASE_DSN => $config_data->{dsn},
            },
            command => [
              $RootPath->child ('perl'),
              $RootPath->child ('bin/server.pl'),
              $self->local_url ('app')->port,
            ],
            local_url => $self->local_url ('app'),
          };
        });
      }, # prepare
    }, # app
    app_docker => {
      handler => 'ServerSet::DockerHandler',
      requires => ['app_config', 'proxy'],
      prepare => sub {
        my ($handler, $self, $args, $data) = @_;
        return Promise->resolve ($args->{receive_app_config_data})->then (sub {
          my $config_data = shift;
          my $net_host = $args->{docker_net_host};
          my $port = $self->local_url ('app')->port; # default: 8080
          return {
            image => $config_data->{app_docker_image},
            volumes => [
              $config_data->{config_path}->absolute . ':/app-config.json',
            ],
            net_host => $net_host,
            ports => ($net_host ? undef : [
              $self->local_url ('app')->hostport . ":" . $port,
            ]),
            environment => {
              %{$config_data->{envs}},
              PORT => $port,
              CONFIG_FILE => '/app-config.json',
              DATABASE_DSN => $config_data->{dsn},
            },
            command => ['/server'],
          };
        });
      }, # prepare
      wait => sub {
        my ($handler, $self, $args, $data, $signal) = @_;
        return $self->wait_for_http (
          $self->local_url ('app'),
          signal => $signal, name => 'wait for app',
          check => sub {
            return $handler->check_running;
          },
        );
      }, # wait
    }, # app_docker
    xs => {
      handler => 'ServerSet::SarzeHandler',
      prepare => sub {
        my ($handler, $self, $args, $data) = @_;
        return {
          hostports => [
            [$self->local_url ('xs')->host->to_ascii,
             $self->local_url ('xs')->port],
          ],
          psgi_file_name => $RootPath->child ('t_deps/bin/xs.psgi'),
          max_worker_count => 1,
          #debug => 2,
        };
      }, # prepare
    }, # xs
    wd => {
      handler => 'ServerSet::WebDriverServerHandler',
    },
    _ => {
      requires => ['app_config'],
      start => sub {
        my ($handler, $self, %args) = @_;
        my $data = {};

        ## app_client_url Web::URL of the main application server for clients.
        ## app_local_url Web::URL the main application server is listening.
        ## local_envs   Environment variables setting proxy for /this/ host.
        
        $data->{app_local_url} = $self->local_url ('app');
        $data->{app_client_url} = $self->client_url ('app');
        $self->set_local_envs ('proxy', $data->{local_envs} = {});
        $self->set_docker_envs ('proxy', $data->{docker_envs} = {});

        if ($args{has_accounts}) {
          $data->{accounts_key} = $self->key ('accounts_key');
          $data->{accounts_context} = $self->key ('accounts_context');
          $data->{accounts_client_url} = $self->client_url ('accounts');
        }

        $data->{wd_local_url} = $self->local_url ('wd');
        $data->{artifacts_path} = $self->artifacts_path (undef);

        my $rev_path = $RootPath->child ('rev');
        return Promised::File->new_from_path ($rev_path)->read_byte_string->then (sub {
          $data->{app_rev} = $_[0];
          $data->{app_rev} =~ s/[\x0D\x0A]//g;
          return [$data, undef];
        });
      },
    }, # _
  }, sub {
    my ($ss, $args) = @_;
    my $result = {};

    $result->{exposed} = {
      proxy => [$args->{proxy_host}, $args->{proxy_port}],
      app => [$args->{app_host}, $args->{app_port}],
    };

    my $app_docker_image = $args->{app_docker_image} // '';
    $result->{server_params} = {
      proxy => {
      },
      mysqld => {
        databases => {
          gruwa => $RootPath->child ('db/gruwa.sql'),
          accounts => $RootPath->child ('local/accounts.sql'),
          apploach => $RootPath->child ('local/apploach.sql'),
        },
        database_name_suffix => $args->{mysqld_database_name_suffix},
      },
      storage => {
        docker_net_host => $args->{docker_net_host},
        no_set_uid => $args->{no_set_uid},
        public_prefixes => [],
      },
      accounts => {
        disabled => $args->{dont_run_accounts},
        config_path => $args->{accounts_config_path}, # or undef
        servers_path => $args->{accounts_servers_path}, # or undef
        docker_net_host => $args->{docker_net_host},
      },
      apploach => {
        disabled => $args->{dont_run_apploach},
        config_path => $args->{apploach_config_path}, # or undef
        docker_net_host => $args->{docker_net_host},
      },
      app_config => {
        app_config_path => $args->{app_config_path},
        app_docker_image => $app_docker_image || undef,
        has_accounts => ! $args->{dont_run_accounts},
        has_apploach => ! $args->{dont_run_apploach},
      },
      app => {
        disabled => !! $app_docker_image,
      },
      app_docker => {
        disabled => ! $app_docker_image,
        docker_net_host => $args->{docker_net_host},
      },
      xs => {
        disabled => $args->{dont_run_xs},
      },
      wd => {
        disabled => ! $args->{need_browser},
        browser_type => $args->{browser_type},
      },
      _ => {
        has_accounts => ! $args->{dont_run_accounts},
      },
    }; # $result->{server_params}

    return $result;
  }, @_);
} # run

1;

=head1 LICENSE

Copyright 2016-2019 Wakaba <wakaba@suikawiki.org>.

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
