# -*- Perl -*-
use strict;
use warnings;
use Path::Tiny;
use Promise;
use Promised::Flow;
use JSON::PS;
use Wanage::HTTP;
use Dongry::Database;
use Web::URL;
use Web::Transport::ConnectionClient;

use AppServer;
use StaticFiles;
use CommonPages;
use AccountPages;
use GroupPages;
use JumpPages;
use ImportPages;

my $config_path = path ($ENV{CONFIG_FILE} // die "No |CONFIG_FILE|");
my $Config = json_bytes2perl $config_path->slurp;

if ($Config->{x_forwarded}) {
  $Wanage::HTTP::UseXForwardedScheme = 1;
  $Wanage::HTTP::UseXForwardedHost = 1;
}

$Config->{git_sha} = path (__FILE__)->parent->parent->child ('rev')->slurp;
$Config->{git_sha} =~ s/[\x0D\x0A]//g;

my $dsn = $ENV{DATABASE_DSN} // die "No |DATABASE_DSN|";
my $DBSources = {sources => {
  master => {dsn => $dsn, anyevent => 1, writable => 1},
  default => {dsn => $dsn, anyevent => 1},
}};

sub accounts ($) {
  my $app = $_[0];
  my $accounts = Web::Transport::ConnectionClient->new_from_url
      (Web::URL->parse_string ($app->config->{accounts}->{url}));
  my $acall = sub {
    my ($path, $params) = @_;
    my $p = $accounts->request (
      method => 'POST',
      path => $path,
      bearer => $app->config->{accounts}->{key},
      params => $params,
    );
    return sub {
      my ($ok, $ng, $exception) = @_;
      return $p->then (sub {
        my $result = $_[0];
        if ($result->status == 200) {
          return $ok->(json_bytes2perl $result->body_bytes) if defined $ok;
          return;
        } elsif (defined $ng and
                 not $result->is_network_error and
                 ($result->header ('Content-Type') // '') =~ m{^application/json}) {
          my $json = json_bytes2perl $result->body_bytes;
          if (defined $json and ref $json eq 'HASH' and
              defined $json->{reason}) {
            return $ng->($json);
          }
        }
        return $exception->($result) if defined $exception;
        die $result;
      }, $exception);
    };
  }; # $acall
  return ($acall, $accounts);
} # accounts

return sub {
  my $http = Wanage::HTTP->new_from_psgi_env ($_[0]);
  my $app = AppServer->new_from_http_and_config ($http, $Config);
  $app->execute_by_promise (sub {
    warn sprintf "ACCESS: [%s] %s %s FROM %s %s\n",
        scalar gmtime,
        $app->http->request_method, $app->http->url->stringify,
        $app->http->client_ip_addr->as_text,
        $app->http->get_request_header ('User-Agent') // '';

    $app->config->{git_sha} = 'local-' . rand if $app->config->{is_local};

    if ($app->config->{origin} eq $app->http->url->ascii_origin) {
      $app->http->set_response_header
          ('Strict-Transport-Security',
           'max-age=10886400; includeSubDomains; preload');

      my $path = $app->path_segments;

      if ($path->[0] eq 'robots.txt' or
          #$path->[0] eq 'favicon.ico' or
          #$path->[0] eq 'manifest.json' or
          $path->[0] eq 'css' or
          $path->[0] eq 'images' or
          $path->[0] eq 'js') {
        return StaticFiles->main ($app, $path);
      }

      my $db = Dongry::Database->new (%$DBSources);
      my ($acall, $accounts) = accounts $app;
      return promised_cleanup {
        return Promise->all ([
          $db->disconnect,
          $accounts->close,
        ]);
      } Promise->resolve->then (sub {

        if (@$path == 4 and
            $path->[0] eq 'g' and
            $path->[1] =~ /\A[1-9][0-9]*\z/ and
            $path->[2] eq 'members' and
            $path->[3] eq 'list.json') {
          # /g/{group_id}/members/list.json
          return GroupPages->group_members_list ($app, $path->[1], $acall);
        }

        if (@$path == 4 and
            $path->[0] eq 'g' and
            $path->[1] =~ /\A[1-9][0-9]+\z/ and
            $path->[2] eq 'members' and
            $path->[3] eq 'status.json') {
          # /g/{group_id}/members/status.json
          return GroupPages->group_members_status ($app, $path->[1], $acall);
        }

        if (@$path >= 3 and $path->[0] eq 'g' and
            $path->[1] =~ /\A[1-9][0-9]*\z/) {
          # /g/{group_id}/...
          return GroupPages->main ($app, $path, $db, $acall);
        }

        if (@$path == 2 and
            $path->[0] eq 'g' and $path->[1] eq 'create.json') {
          # /g/create.json
          return GroupPages->create ($app, $db, $acall);
        }

        if (@$path == 1 and $path->[0] eq 'dashboard') {
          # /dashboard
          return $acall->(['info'], {
            sk_context => $app->config->{accounts}->{context},
            sk => $app->http->request_cookies->{sk},
          })->(sub {
            my $account_data = $_[0];
            return AccountPages->dashboard ($app, $account_data);
          });
        }

        if ($path->[0] eq 'jump') {
          # /jump
          return $acall->(['info'], {
            sk_context => $app->config->{accounts}->{context},
            sk => $app->http->request_cookies->{sk},
          })->(sub {
            my $account_data = $_[0];
            unless (defined $account_data->{account_id}) {
              if ($app->http->request_method eq 'POST') {
                return $app->send_error (403, reason_phrase => 'No user account');
              } else {
                my $this_url = Web::URL->parse_string ($app->http->url->stringify);
                my $url = Web::URL->parse_string (q</account/login>, $this_url);
                $url->set_query_params ({next => $this_url->stringify});
                return $app->send_redirect ($url->stringify);
              }
            }

            return JumpPages->main ($app, $path, $db, $account_data);
          });
        }

        if (@$path == 2 and
            $path->[0] eq 'my' and $path->[1] eq 'groups.json') {
          # /my/groups.json
          return AccountPages->mygroups ($app, $acall);
        }

        if ($path->[0] eq 'my') {
          # /my
          return $acall->(['info'], {
            sk_context => $app->config->{accounts}->{context},
            sk => $app->http->request_cookies->{sk},
          })->(sub {
            my $account_data = $_[0];
            return AccountPages->mymain ($app, $path, $account_data);
          });
        }

        if ($path->[0] eq 'account') {
          # /account (except for /account/info.json)
          return AccountPages->main ($app, $path, $acall);
        }

        if ($path->[0] eq 'import') {
          # /import
          return ImportPages->main ($app, $path);
        }

        if ($path->[0] eq 'invitation') {
          # /invitation/...
          return GroupPages->invitation ($app, $path, $acall);
        }

        if (@$path == 2 and $path->[0] eq 'theme' and $path->[1] eq 'list.json') {
          # /theme/list.json
          return StaticFiles->main ($app, $path);
        }
        
        if (@$path == 1) {
          return CommonPages->main ($app, $path, $db);
        }

        return $app->send_error (404, reason_phrase => 'Page not found');
      })->catch (sub {
        return if UNIVERSAL::isa ($_[0], 'Warabe::App::Done');
        warn "ERROR: $_[0]\n";
        return $app->send_error (500);
      });
    } else {
      # XXX tests
      return $app->send_redirect ($app->config->{origin});
    }
  });
};

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
