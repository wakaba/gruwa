package AccountPages;
use strict;
use warnings;
use JSON::PS;
use Web::URL;

use Results;

sub main ($$$$$$) {
  my ($class, $app, $path, $config, $db, $accounts) = @_;

  if (@$path == 2 and $path->[1] eq 'login') {
    # /account/login
    if ($app->http->request_method eq 'POST') {
      $app->requires_same_origin;
      my $server = $app->bare_param ('server') // '';
      return $app->throw_error (400, reason_phrase => 'Bad |server|')
          unless grep { $_ eq $server } @{$config->{accounts}->{servers}};
      return $accounts->request (
        method => 'POST',
        path => ['session'],
        params => {
          ## don't reuse any existing |sk| cookie for security reason
          sk_context => $config->{accounts}->{context},
        },
        bearer => $config->{accounts}->{key},
      )->then (sub {
        my $res = $_[0];
        die $res unless $res->status == 200;
        my $json1 = json_bytes2perl $res->body_bytes;
        return $accounts->request (
          method => 'POST',
          path => ['login'],
          params => {
            sk_context => $config->{accounts}->{context},
            sk => $json1->{sk},
            server => $server,
            callback_url => $app->http->url->resolve_string (q</account/cb>)->stringify,
            #app_data => ...,
          },
          bearer => $config->{accounts}->{key},
        )->then (sub {
          my $res = $_[0];
          die $res unless $res->status == 200;
          my $json2 = json_bytes2perl $res->body_bytes;
          if ($json1->{set_sk}) {
            my $url = Web::URL->parse_string ($config->{origin});
            $app->http->set_response_cookie
                (sk => $json1->{sk},
                 expires => $json1->{sk_expires},
                 path => q</>,
                 domain => $url->host->to_ascii,
                 secure => $url->scheme eq 'https',
                 httponly => 1);
          }
          return $app->send_redirect ($json2->{authorization_url});
        });
      });
    } else { # GET
      $app->http->set_response_header ('X-Frame-Options' => 'sameorigin');
      return temma $app, 'account.login.html.tm', {
        servers => $config->{accounts}->{servers},
      };
    }
  } # /account/login

  if (@$path == 2 and $path->[1] eq 'cb') {
    # /account/cb
    return $accounts->request (
      method => 'POST',
      path => ['cb'],
      params => {
        sk_context => $config->{accounts}->{context},
        sk => $app->http->request_cookies->{sk},
        code => $app->text_param ('code'),
        state => $app->text_param ('state'),
        oauth_token => $app->text_param ('oauth_token'),
        oauth_verifier => $app->text_param ('oauth_verifier'),
      },
      bearer => $config->{accounts}->{key},
    )->then (sub {
      my $res = $_[0];
      if ($res->status == 200) {
        return $app->send_redirect ('/account/done');
      } elsif ($res->status == 400) {
        my $json = json_bytes2perl $res->body_bytes;
        if (defined $json and ref $json eq 'HASH' and defined $json->{reason}) {
          $app->http->set_status (400);
          return $app->send_plain_text ($json->{reason});
        } else {
          die $res;
        }
      } else {
        die $res;
      }
    });
  } # /account/cb

  if (@$path == 2 and $path->[1] eq 'done') {
    # /account/done
    return temma $app, 'account.done.html.tm', {};
  }

  if (@$path == 2 and $path->[1] eq 'info.json') {
    # /account/info.json
    my $with_profile = $app->bare_param ('with_profile');
    my $with_linked = $app->bare_param ('with_links');
    return $accounts->request (
      method => 'POST',
      path => ['info'],
      bearer => $config->{accounts}->{key},
      params => {
        sk_context => $config->{accounts}->{context},
        sk => $app->http->request_cookies->{sk},
        with_data => $with_profile ? [] : [],
        with_linked => $with_linked ? 'name' : undef,
      },
    )->then (sub {
      die $_[0] unless $_[0]->status == 200;
      my $data = json_bytes2perl $_[0]->body_bytes;
      my $json = {
        has_account => $data->{has_account},
        account_id => defined $data->{account_id} ? ''.$data->{account_id} : undef,
        name => $data->{name},
      };
      if ($with_profile) {
        #
      }
      if ($with_linked) {
        for (values %{$data->{links} or {}}) {
          push @{$json->{links}->{$_->{service_name}} ||= []},
              {service_name => $_->{service_name},
               account_link_id => $_->{account_link_id},
               id => $_->{id}, name => $_->{name}};
        }
      }
      return json $app, $json;
    });
  } # /account/info.json

  return $app->send_error (404);
} # main

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
