package AccountPages;
use strict;
use warnings;
use Web::URL;

use Results;

sub main ($$$$$) {
  my ($class, $app, $path, $acall) = @_;

  if (@$path == 2 and $path->[1] eq 'login') {
    # /account/login
    if ($app->http->request_method eq 'POST') {
      $app->requires_same_origin;
      my $server = $app->bare_param ('server') // '';
      return $app->throw_error (400, reason_phrase => 'Bad |server|')
          unless grep { $_ eq $server } @{$app->config->{accounts}->{servers}};
      return $acall->(['session'], {
        ## don't reuse any existing |sk| cookie for security reason
        sk_context => $app->config->{accounts}->{context},
      })->(sub {
        my $json1 = $_[0];
        return $acall->(['login'], {
          sk_context => $app->config->{accounts}->{context},
          sk => $json1->{sk},
          server => $server,
          callback_url => $app->http->url->resolve_string (q</account/cb>)->stringify,
          app_data => $app->text_param ('next'),
        })->(sub {
          my $json2 = $_[0];
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
    return $acall->(['cb'], {
      sk_context => $app->config->{accounts}->{context},
      sk => $app->http->request_cookies->{sk},
      code => $app->text_param ('code'),
      state => $app->text_param ('state'),
      oauth_token => $app->text_param ('oauth_token'),
      oauth_verifier => $app->text_param ('oauth_verifier'),
    })->(sub {
      my $json = $_[0];
      my $url = Web::URL->parse_string ($app->http->url->resolve_string ('/dashboard')->stringify);
      my $next = Web::URL->parse_string ($json->{app_data} // '');
      unless (defined $next and
              $next->get_origin->same_origin_as ($url->get_origin)) {
        $next = $url;
      }
      return $app->send_redirect ($next->stringify);
    }, sub {
      my $json = $_[0];
      $app->http->set_status (400, reason_phrase => $json->{reason});
      return $app->send_plain_text ($json->{reason});
    });
  } # /account/cb

  return $app->send_error (404);
} # main

sub mymain ($$$$$) {
  my ($class, $app, $path, $account_data) = @_;

  if (@$path == 2 and $path->[1] eq 'info.json') {
    # /my/info.json
    my $json = {
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

  return $app->throw_error (404);
} # mymain

sub mygroups ($$$) {
  my ($class, $app, $acall) = @_;
  # /my/groups.json
  my $result = {groups => {}, next_ref => $app->text_param ('ref')};
  return $acall->(['info'], {
    sk_context => $app->config->{accounts}->{context},
    sk => $app->http->request_cookies->{sk},
  })->(sub {
    my $account_data = $_[0];
    return unless defined $account_data->{account_id};
    return $acall->(['group', 'byaccount'], {
      context_key => $app->config->{accounts}->{context} . ':group',
      account_id => $account_data->{account_id},
      with_data => ['default_index_id'],
      ref => $result->{next_ref},
    })->(sub {
      $result->{groups} = {map {
        $_->{group_id} => {
          group_id => $_->{group_id},
          member_type => ($_->{owner_status} == 1 ? $_->{member_type} : 0),
          user_status => $_->{user_status},
          owner_status => ($_->{owner_status} == 1 ? $_->{owner_status} : 0),
          default_index_id => ($_->{owner_status} == 1 ? $_->{data}->{default_index_id} ? $_->{data}->{default_index_id} : undef : undef),
        };
      } values %{$_[0]->{memberships}}};
      $result->{next_ref} = $_[0]->{next_ref};
      $result->{has_next} = $_[0]->{has_next};
    });
  })->then (sub {
    my $allowed_groups = [map { $_->{group_id} }
                          grep { $_->{owner_status} == 1 }
                          values %{$result->{groups}}];
    return unless @$allowed_groups;
    return $acall->(['group', 'profiles'], {
      context_key => $app->config->{accounts}->{context} . ':group',
      group_id => $allowed_groups,
      # XXX
      admin_status => 1, # open
      owner_status => 1, # open
      with_data => ['title'],
    })->(sub {
      my $gs = $_[0]->{groups};
      for (values %{$result->{groups}}) {
        $_->{title} = $gs->{$_->{group_id}}->{data}->{title};
        $_->{updated} = $gs->{$_->{group_id}}->{updated};
      }
    });
  })->then (sub {
    return json $app, $result;
  });
} # mygroups

sub dashboard ($$$) {
  my ($class, $app, $account_data) = @_;
  unless (defined $account_data->{account_id}) {
    my $this_url = Web::URL->parse_string ($app->http->url->stringify);
    my $url = Web::URL->parse_string (q</account/login>, $this_url);
    $url->set_query_params ({next => $this_url->stringify});
    return $app->send_redirect ($url->stringify);
  }
  return temma $app, 'dashboard.html.tm', {account => $account_data};
} # dashboard

sub user ($$$$) {
  my ($class, $app, $path, $acall) = @_;

  if (@$path == 2 and $path->[1] eq 'info.json') {
    # /u/info.json
    return $acall->(['profiles'], {
      account_id => $app->bare_param_list ('account_id')->to_a,
      user_status => 1, # ACCOUNT_STATUS_ENABLED,
      admin_status => 1, # ACCOUNT_STATUS_ENABLED,
      #terms_version
      #with_linked => ['id', 'name'],
      with_data => ['name'],
    })->(sub {
      my $json = $_[0];
      return json $app, {accounts => {map {
        my $account = $json->{accounts}->{$_};
        my $name = $account->{name} // '';
        $name = $account->{account_id} unless length $name;
        $_ => {
          account_id => ''.$account->{account_id},
          name => $name,
        };
      } keys %{$json->{accounts}}}};
    });
  } # /u/info.json

  return $app->throw_error (404);
} # user

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
License along with this program, see <http://www.gnu.org/licenses/>.

=cut
