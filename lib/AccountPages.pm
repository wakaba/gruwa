package AccountPages;
use strict;
use warnings;
use JSON::PS;
use Web::URL;
use Dongry::Type;

use Results;

sub main ($$$$$) {
  my ($class, $app, $path, $db, $accounts) = @_;

  if (@$path == 2 and $path->[1] eq 'login') {
    # /account/login
    if ($app->http->request_method eq 'POST') {
      $app->requires_same_origin;
      my $server = $app->bare_param ('server') // '';
      return $app->throw_error (400, reason_phrase => 'Bad |server|')
          unless grep { $_ eq $server } @{$app->config->{accounts}->{servers}};
      return $accounts->request (
        method => 'POST',
        path => ['session'],
        params => {
          ## don't reuse any existing |sk| cookie for security reason
          sk_context => $app->config->{accounts}->{context},
        },
        bearer => $app->config->{accounts}->{key},
      )->then (sub {
        my $res = $_[0];
        die $res unless $res->status == 200;
        my $json1 = json_bytes2perl $res->body_bytes;
        return $accounts->request (
          method => 'POST',
          path => ['login'],
          params => {
            sk_context => $app->config->{accounts}->{context},
            sk => $json1->{sk},
            server => $server,
            callback_url => $app->http->url->resolve_string (q</account/cb>)->stringify,
            app_data => $app->text_param ('next'),
          },
          bearer => $app->config->{accounts}->{key},
        )->then (sub {
          my $res = $_[0];
          die $res unless $res->status == 200;
          my $json2 = json_bytes2perl $res->body_bytes;
          if ($json1->{set_sk}) {
            my $url = Web::URL->parse_string ($app->config->{origin});
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
        servers => $app->config->{accounts}->{servers},
      };
    }
  } # /account/login

  if (@$path == 2 and $path->[1] eq 'cb') {
    # /account/cb
    return $accounts->request (
      method => 'POST',
      path => ['cb'],
      params => {
        sk_context => $app->config->{accounts}->{context},
        sk => $app->http->request_cookies->{sk},
        code => $app->text_param ('code'),
        state => $app->text_param ('state'),
        oauth_token => $app->text_param ('oauth_token'),
        oauth_verifier => $app->text_param ('oauth_verifier'),
      },
      bearer => $app->config->{accounts}->{key},
    )->then (sub {
      my $res = $_[0];
      if ($res->status == 200) {
        my $json = json_bytes2perl $res->body_bytes;
        my $url = Web::URL->parse_string ($app->http->url->resolve_string ('/dashboard')->stringify);
        my $next = Web::URL->parse_string ($json->{app_data} // '');
        unless (defined $next and
                $next->get_origin->same_origin_as ($url->get_origin)) {
          $next = $url;
        }
        return $app->send_redirect ($next->stringify);
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

  return $app->send_error (404);
} # main

sub mymain ($$$$$) {
  my ($class, $app, $path, $db, $account_data) = @_;

  if (@$path == 2 and $path->[1] eq 'info.json') {
    # /my/info.json
    my $json = {
      has_account => $account_data->{has_account},
      account_id => defined $account_data->{account_id} ? ''.$account_data->{account_id} : undef,
      name => $account_data->{name},
    };
  #if ($with_profile) {
  #  #
  #}
  #if ($with_linked) {
  #  for (values %{$account_data->{links} or {}}) {
  #    push @{$json->{links}->{$_->{service_name}} ||= []},
  #        {service_name => $_->{service_name},
  #         account_link_id => $_->{account_link_id},
  #         id => $_->{id}, name => $_->{name}};
  #  }
  #}
    return json $app, $json;
  } # info

  if (@$path == 2 and $path->[1] eq 'groups.json') {
    # /my/groups.json
    return Promise->resolve->then (sub {
      return {} unless $account_data->{has_account};
      return $db->select ('group_member', {
        account_id => Dongry::Type->serialize ('text', $account_data->{account_id}),
      }, fields => ['group_id', 'member_type', 'user_status', 'owner_status'])->then (sub {
        return {map {
          $_->{group_id} => {
            group_id => ''.$_->{group_id},
            member_type => ($_->{owner_status} == 1 ? $_->{member_type} : 0),
            user_status => $_->{user_status},
            owner_status => ($_->{owner_status} == 1 ? $_->{owner_status} : 0),
          };
        } @{$_[0]->all}};
      });
    })->then (sub {
      my $groups = $_[0];
      my $allowed_groups = [map { $_->{group_id} }
                            grep { $_->{owner_status} == 1 } values %$groups];
      return $groups unless @$allowed_groups;
      return $db->select ('group', {
        group_id => {-in => $allowed_groups},
        # XXX admin_status
      }, fields => ['title', 'group_id'])->then (sub {
        my %title;
        for (@{$_[0]->all}) {
          $title{$_->{group_id}} = Dongry::Type->parse ('text', $_->{title});
        }
        for (values %$groups) {
          $_->{title} = $title{$_->{group_id}};
        }
        return $groups;
      });
    })->then (sub {
      return json $app, {groups => $_[0]};
    });
  } # groups.json

  return $app->throw_error (404);
} # mymain

sub dashboard ($$$) {
  my ($class, $app, $account_data) = @_;
  return temma $app, 'dashboard.html.tm', {account => $account_data};
} # dashboard

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
