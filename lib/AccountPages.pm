package AccountPages;
use strict;
use warnings;
use Web::URL;
use Web::URL::Encoding;
use Promise;
use JSON::PS;

use Pager;
use Results;

sub main ($$$$$) {
  my ($class, $app, $path, $acall) = @_;

  if (@$path == 2 and $path->[1] eq 'login') {
    # /account/login
    if ($app->http->request_method eq 'POST') {
      $app->requires_same_origin_or_referer_origin;
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
          create_email_link => 1,
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
                 httponly => 1,
                 samesite => 1);
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
      return $app->accounts (['info'], {
        sk_context => $app->config->{accounts}->{context},
        sk => $app->http->request_cookies->{sk},
      })->then (sub {
        my $account = $_[0];
        if (defined $account->{terms_version} and
            $account->{terms_version} >= $app->config->{accounts}->{terms_version}) {
          return $app->send_redirect ($next->stringify);
        } else {
          return $app->send_redirect (sprintf '/account/agree?next=%s', percent_encode_c $next->stringify);
        }
      });
    }, sub {
      my $json = $_[0];
      $app->http->set_status (400, reason_phrase => $json->{reason});
      return $app->send_plain_text ($json->{reason});
    });
  } # /account/cb

  if (@$path == 2 and $path->[1] eq 'done') {
    # /account/done
    $app->http->set_response_header ('X-Frame-Options' => 'sameorigin');
    return temma $app, 'account.done.html.tm', {};
  }

  if (@$path == 2 and $path->[1] eq 'agree') {
    # /account/agree
    $app->http->set_response_header ('X-Frame-Options' => 'sameorigin');
    if ($app->http->request_method eq 'POST') {
      $app->requires_same_origin;
      my $agree;
      if ($app->bare_param ('disagree')) {
        $agree = {
          version => 1,
          downgrade => 1,
        };
      } elsif ($app->bare_param ('agree')) {
        $agree = {
          version => $app->config->{accounts}->{terms_version},
        };
      }
      return Promise->resolve->then (sub {
        return $app->accounts (['agree'], {
          sk_context => $app->config->{accounts}->{context},
          sk => $app->http->request_cookies->{sk},
          %$agree,
        }) if keys %$agree;
      })->then (sub {
        my $url = Web::URL->parse_string ($app->http->url->resolve_string ('/dashboard')->stringify);
        my $next = Web::URL->parse_string ($app->text_param ('next') // '');
        unless (defined $next and
                $next->get_origin->same_origin_as ($url->get_origin)) {
          $next = $url;
        }
        return $app->send_redirect ($next->stringify);
      });
    } else {
      return temma $app, 'account.agree.html.tm', {};
    }
  }

  if ($path->[1] eq 'push') {
    return $app->accounts (['info'], {
      sk_context => $app->config->{accounts}->{context},
      sk => $app->http->request_cookies->{sk},
      terms_version => $app->config->{accounts}->{terms_version},
    })->then (sub {
      my $account = $_[0];
      $account->{has_account} = !! $account->{account_id};
      return $class->account_push ($app, $path, $account);
    });
  }

  if ($path->[1] eq 'email') {
    return $class->account_email ($app, $path);
  }

  if (@$path == 2 and $path->[1] eq 'unlink.json') {
    # /account/unlink.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;
    my $server = $app->bare_param ('server') // '';
    return $app->throw_error (400, reason_phrase => 'Bad |server|')
        unless $server eq 'email';
    return $app->accounts (['link', 'delete'], {
      sk_context => $app->config->{accounts}->{context},
      sk => $app->http->request_cookies->{sk},
      account_link_id => $app->bare_param ('account_link_id') // '',
      server => $server,
    })->then (sub {
      return json $app, {};
    });
  } # /account/unlink.json

  if (@$path == 2 and $path->[1] eq 'configsummary.json') {
    # /account/configsummary.json
    return $app->accounts (['info'], {
      sk_context => $app->config->{accounts}->{context},
      sk => $app->http->request_cookies->{sk},
      terms_version => $app->config->{accounts}->{terms_version},
      with_linked => 'email',
    })->then (sub {
      my $account = $_[0];
      my $result = {};
      return $result unless defined $account->{account_id};
      for (values %{$account->{links} or {}}) {
        next unless $_->{service_name} eq 'email';
        $result->{email} = 1;
        last;
      }
      return $app->apploach (['notification', 'hook', 'list.json'], {
        subscriber_nobj_key => 'account-' . $account->{account_id},
        type_nobj_key => 'apploach-push',
        limit => 1,
      })->then (sub {
        my $v = $_[0];
        $result->{push} = 1 if @{$v->{items}};
        return $result;
      });
    })->then (sub {
      return json $app, $_[0];
    });
  }

  return $app->send_error (404);
} # main

sub account_email ($$$) {
  my ($class, $app, $path) = @_;
  # /account/email/...

  if (@$path == 3 and $path->[2] eq 'list.json') {
    # /account/email/list.json
    return $app->accounts (['info'], {
      sk_context => $app->config->{accounts}->{context},
      sk => $app->http->request_cookies->{sk},
      terms_version => $app->config->{accounts}->{terms_version},
      with_linked => 'email',
    })->then (sub {
      my $account = $_[0];
      return [] unless defined $account->{account_id};
      my $email_addrs = [];
      for (values %{$account->{links} or {}}) {
        next unless $_->{service_name} eq 'email';
        push @$email_addrs, {addr => $_->{email}, account_link_id => $_->{account_link_id}};
      }
      return $email_addrs;
    })->then (sub {
      return json $app, {items => $_[0]};
    });
  }

  if (@$path == 3 and $path->[2] eq 'add.json') {
    # /account/email/add.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;
    my $to_addr = $app->text_param ('addr');
    return $app->accounts (['email', 'input'], {
      sk_context => $app->config->{accounts}->{context},
      sk => $app->http->request_cookies->{sk},
      addr => $to_addr,
    })->then (sub {
      my $json = $_[0];
      if (defined $json->{key}) {
        return $app->temma_email ('email-verify.html.tm', {
          url => $app->http->url->resolve_string ('/account/email/verify?key=' . $json->{key})->stringify, # key is URL safe
          #to_account
        }, undef, undef, $to_addr)->then (sub {
          return json $app, {sent => 1};
        });
      } else { # verified
        return json $app, {};
      }
    }, sub {
      return $app->throw_error (400, reason_phrase => $_[0]->{reason})
          if ref $_[0] eq 'HASH';
      die $_[0];
    });
  } elsif (@$path == 3 and $path->[2] eq 'verify') {
    # /account/email/verify
    return $app->accounts (['email', 'verify'], {
      sk_context => $app->config->{accounts}->{context},
      sk => $app->http->request_cookies->{sk},
      key => $app->text_param ('key'),
    })->then (sub {
      my $json = $_[0];
      return $app->send_redirect ('/dashboard/receive#emails');
    }, sub {
      return $app->throw_error (400, reason_phrase => $_[0]->{reason})
          if ref $_[0] eq 'HASH';
      die $_[0];
    });
  } # /account/email/verify
  
  return $app->send_error (404);
} # account_email

sub account_push ($$$$) {
  my ($class, $app, $path, $account) = @_;
  # /account/push/...

  if (@$path == 3 and $path->[2] eq 'list.json') {
    # /account/push/list.json
    return Promise->resolve->then (sub {
      return [] unless $account->{has_account};
      return $app->apploach (['notification', 'hook', 'list.json'], {
        subscriber_nobj_key => 'account-' . $account->{account_id},
        type_nobj_key => 'apploach-push',
        limit => 100,
      })->then (sub {
        my $v = $_[0];
        return [map {
          +{
            url_sha => $_->{url_sha},
            ua => $_->{data}->{ua},
            created => $_->{created},
            expires => $_->{expires},
          };
        } @{$v->{items}}];
      });
      ## Apploach supports paging but there should not be many push
      ## destinations.
    })->then (sub {
      return json $app, {items => $_[0]};
    });
  } elsif (@$path == 3 and $path->[2] eq 'add.json') {
    # /account/push/add.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;
    return $app->throw_error (403) unless $account->{has_account};
    my $sub = json_bytes2perl ($app->bare_param ('sub') // '{}');
    return $app->throw_error (400, reason_phrase => 'Bad |sub|')
        unless defined $sub and ref $sub eq 'HASH';
    my $u = $sub->{endpoint} // '';
    my $url = Web::URL->parse_string ($u);
    if ($app->config->{is_test_script}) {
      return $app->throw_error (400, reason_phrase => 'Bad |sub|.endpoint')
          unless defined $url and $url->is_http_s;
    } else {
      return $app->throw_error (400, reason_phrase => 'Bad |sub|.endpoint')
          unless defined $url and $url->scheme eq 'https';
    }
    return $app->apploach (['notification', 'hook', 'subscribe.json'], {
      subscriber_nobj_key => 'account-' . $account->{account_id},
      type_nobj_key => 'apploach-push',
      url => $url->stringify,
      status => 2, # enabled
      data => {
        apploach_subscription => $sub,
        ua => $app->http->get_request_header ('user-agent'),
        ip => $app->http->client_ip_addr->as_text,
      },
    })->then (sub {
      return json $app, {};
    });
  } elsif (@$path == 3 and $path->[2] eq 'delete.json') {
    # /account/push/delete.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;
    return Promise->resolve->then (sub {
      return $app->throw_error (403) unless $account->{has_account};
      return $app->apploach (['notification', 'hook', 'delete.json'], {
        subscriber_nobj_key => 'account-' . $account->{account_id},
        type_nobj_key => 'apploach-push',
        url => $app->bare_param ('url'),
        url_sha => $app->bare_param ('url_sha'),
      });
    })->then (sub {
      return json $app, {};
    });
  }

  return $app->send_error (404);
} # account_push

sub mymain ($$$$$) {
  my ($class, $app, $path, $acall, $db) = @_;

  if (@$path == 2 and $path->[1] eq 'groups.json') {
    # /my/groups.json
    return $class->mygroups ($app, $acall);
  }

  if (@$path == 2 and $path->[1] eq 'info.json') {
    # /my/info.json
    return $acall->(['info'], {
      sk_context => $app->config->{accounts}->{context},
      sk => $app->http->request_cookies->{sk},
    })->(sub {
      my $account_data = $_[0];
      my $json = {
        account_id => defined $account_data->{account_id} ? ''.$account_data->{account_id} : undef,
        name => $account_data->{name},
        terms_version => $account_data->{terms_version},
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
    });
  } # info

  if (@$path == 2 and $path->[1] eq 'calls.json') {
    # /my/calls.json
    my $page = Pager::this_page ($app, limit => 30, max_limit => 100);
    return $acall->(['info'], {
      sk_context => $app->config->{accounts}->{context},
      sk => $app->http->request_cookies->{sk},
      terms_version => $app->config->{accounts}->{terms_version},
    })->(sub {
      my $account_data = $_[0];
      return [] unless defined $account_data->{account_id};

      my $where = {
        to_account_id => Dongry::Type->serialize ('text', $account_data->{account_id}),
      };
      $where->{timestamp} = $page->{value} if defined $page->{value};
      return $db->select ('object_call', $where, fields => [
        'group_id', 'object_id', 'from_account_id', 'timestamp', 'read',
        'thread_id', 'reason',
      ],
        offset => $page->{offset}, limit => $page->{limit},
        order => ['timestamp', $page->{order_direction}],
      )->then (sub {
        return $_[0]->all->to_a;
      });
    })->then (sub {
      my $items = $_[0];
      for (@$items) {
        $_->{group_id} .= '';
        $_->{object_id} .= '';
        $_->{thread_id} .= '';
        $_->{from_account_id} .= '';
      }
      my $next_page = Pager::next_page $page, $items, 'timestamp';
      return json $app, {items => $items, %$next_page};
    });
  }

  return $app->throw_error (404);
} # mymain

sub mygroups ($$$) {
  my ($class, $app, $acall) = @_;
  # /my/groups.json
  my $result = {groups => {}, next_ref => $app->text_param ('ref')};
  return $acall->(['info'], {
    sk_context => $app->config->{accounts}->{context},
    sk => $app->http->request_cookies->{sk},
    terms_version => $app->config->{accounts}->{terms_version},
  })->(sub {
    my $account_data = $_[0];
    return unless defined $account_data->{account_id};
    return $acall->(['group', 'byaccount'], {
      context_key => $app->config->{accounts}->{context} . ':group',
      account_id => $account_data->{account_id},
      owner_status => 1, # open
      with_data => ['default_index_id'],
      with_group_updated => 1,
      with_group_data => ['title'],
      ref => $result->{next_ref},
    })->(sub {
      $result->{groups} = {map {
        $_->{group_id} => {
          group_id => $_->{group_id},
          member_type => ($_->{owner_status} == 1 ? $_->{member_type} : 0),
          user_status => $_->{user_status},
          owner_status => ($_->{owner_status} == 1 ? $_->{owner_status} : 0),
          default_index_id => ($_->{owner_status} == 1 ? $_->{data}->{default_index_id} ? $_->{data}->{default_index_id} : undef : undef),
          title => $_->{group_data}->{title} // '',
          updated => $_->{group_updated},
        };
      } values %{$_[0]->{memberships}}};
      $result->{next_ref} = $_[0]->{next_ref};
      $result->{has_next} = $_[0]->{has_next};
    });
  })->then (sub {
    return json $app, $result;
  });
} # mygroups

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

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
<https://www.gnu.org/licenses/>.

=cut
