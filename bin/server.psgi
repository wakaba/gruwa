# -*- Perl -*-
use strict;
use warnings;
use Path::Tiny;
use Promise;
use Promised::Flow;
use JSON::PS;
use Wanage::HTTP;
use Warabe::App;
use Dongry::Database;
use Web::URL;
use Web::Transport::ConnectionClient;

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

my $AccountsURL = Web::URL->parse_string ($Config->{accounts}->{url});

return sub {
  my $http = Wanage::HTTP->new_from_psgi_env ($_[0]);
  my $app = Warabe::App->new_from_http ($http);
  $app->execute_by_promise (sub {
    warn sprintf "ACCESS: [%s] %s %s FROM %s %s\n",
        scalar gmtime,
        $app->http->request_method, $app->http->url->stringify,
        $app->http->client_ip_addr->as_text,
        $app->http->get_request_header ('User-Agent') // '';

    if ($Config->{origin} eq $app->http->url->ascii_origin) {
      $app->http->set_response_header
          ('Strict-Transport-Security',
           'max-age=10886400; includeSubDomains; preload');

      my $db = Dongry::Database->new (%$DBSources);
      return promised_cleanup {
        return $db->disconnect;
      } Promise->resolve->then (sub {
        my $path = $app->path_segments;

        if ($path->[0] eq 'robots.txt' or
            $path->[0] eq 'favicon.ico' or
            $path->[0] eq 'manifest.json' or
            $path->[0] eq 'css' or
            $path->[0] eq 'js' or
            $path->[0] eq 'images') {
          return StaticFiles->main ($app, $path, $Config, $db);
        }

        if ($path->[0] eq 'g' or
            (@$path == 2 and $path->[0] eq 'account' and $path->[1] eq 'info.json')) {
          # /g
          # /account/info.json
          my $accounts = Web::Transport::ConnectionClient->new_from_url
              ($AccountsURL);

          #my $with_profile = $app->bare_param ('with_profile');
          #my $with_linked = $app->bare_param ('with_links');
          return promised_cleanup {
            return $accounts->close;
          } $accounts->request (
            method => 'POST',
            path => ['info'],
            bearer => $Config->{accounts}->{key},
            params => {
              sk_context => $Config->{accounts}->{context},
              sk => $app->http->request_cookies->{sk},
              #with_data => $with_profile ? [] : [],
              #with_linked => $with_linked ? 'name' : undef,
            },
          )->then (sub {
            die $_[0] unless $_[0]->status == 200;
            my $account_data = json_bytes2perl $_[0]->body_bytes;

            if ($path->[0] eq 'account') {
              return AccountPages->info ($app, $account_data);
            } elsif ($path->[0] eq 'g') {
              return GroupPages->main ($app, $path, $Config, $db, $account_data);
            } else {
              die;
            }
          });
        }

        if ($path->[0] eq 'account') {
          # /account (except for /account/info.json)
          my $accounts = Web::Transport::ConnectionClient->new_from_url
              ($AccountsURL);
          return promised_cleanup {
            return $accounts->close;
          } AccountPages->main ($app, $path, $Config, $db, $accounts);
        }

        if (@$path == 1) {
          return CommonPages->main ($app, $path, $Config, $db);
        }

        return $app->send_error (404, reason_phrase => 'Page not found');
      })->catch (sub {
        return if UNIVERSAL::isa ($_[0], 'Warabe::App::Done');
        warn "ERROR: $_[0]\n";
        return $app->send_error (500);
      });
    } else {
      return $app->send_redirect ($Config->{origin});
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
