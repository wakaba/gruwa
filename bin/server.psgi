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

my $config_path = path ($ENV{CONFIG_FILE} // die "No |CONFIG_FILE|");
my $Config = json_bytes2perl $config_path->slurp;

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
          return $ok->(json_bytes2perl $result->body_bytes);
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

    if ($app->config->{origin} eq $app->http->url->ascii_origin) {
      $app->http->set_response_header
          ('Strict-Transport-Security',
           'max-age=10886400; includeSubDomains; preload');

      my $db = Dongry::Database->new (%$DBSources);
      return promised_cleanup {
        return $db->disconnect;
      } Promise->resolve->then (sub {
        my $path = $app->path_segments;

        # XXX tests
        if ($path->[0] eq 'robots.txt' or
            $path->[0] eq 'favicon.ico' or
            $path->[0] eq 'manifest.json' or
            $path->[0] eq 'css' or
            $path->[0] eq 'js' or
            $path->[0] eq 'images') {
          return StaticFiles->main ($app, $path, $db);
        }

        if ($path->[0] eq 'g' or
            $path->[0] eq 'my' or
            $path->[0] eq 'dashboard') {
          # /g
          # /my
          # /dashboard
          my ($acall, $accounts) = accounts $app;
          #my $with_profile = $app->bare_param ('with_profile');
          #my $with_linked = $app->bare_param ('with_links');
          return promised_cleanup {
            return $accounts->close;
          } $acall->(['info'], {
            sk_context => $app->config->{accounts}->{context},
            sk => $app->http->request_cookies->{sk},
            #with_data => $with_profile ? [] : [],
            #with_linked => $with_linked ? 'name' : undef,
          })->(sub {
            my $account_data = $_[0];
            $account_data->{has_account} = defined $account_data->{account_id};
            if ($path->[0] eq 'my') {
              return AccountPages->mymain ($app, $path, $db, $account_data);
            } else {
              unless ($account_data->{has_account}) {
                if ($app->http->request_method eq 'GET' and
                    not $path->[-1] =~ /\.json\z/) {
                  my $this_url = Web::URL->parse_string ($app->http->url->stringify);
                  my $url = Web::URL->parse_string (q</account/login>, $this_url);
                  $url->set_query_params ({next => $this_url->stringify});
                  return $app->send_redirect ($url->stringify);
                } else {
                  return $app->throw_error (403, reason_phrase => 'No user account');
                }
              }

              if ($path->[0] eq 'g') {
                return GroupPages->main ($app, $path, $db, $account_data);
              } elsif ($path->[0] eq 'dashboard') {
                return $app->throw_error (404) unless @$path == 1;
                return AccountPages->dashboard ($app, $account_data);
              } else {
                die;
              }
            }
          });
        }

        if ($path->[0] eq 'account') {
          # /account (except for /account/info.json)
          my ($acall, $accounts) = accounts $app;
          return promised_cleanup {
            return $accounts->close;
          } AccountPages->main ($app, $path, $db, $acall);
        }
        if ($path->[0] eq 'u') {
          # /u
          my ($acall, $accounts) = accounts $app;
          return promised_cleanup {
            return $accounts->close;
          } AccountPages->user ($app, $path, $acall);
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
