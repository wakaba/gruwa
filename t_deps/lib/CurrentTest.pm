package CurrentTest;
use strict;
use warnings;
use Promise;
use Promised::Flow;
use JSON::PS;
use Web::Encoding;
use Web::URL;
use Web::URL::Encoding;
use Web::Transport::BasicClient;
use ServerSet::ReverseProxyProxyManager;
use Test::More;
use Test::X1;

sub new ($$) {
  return bless $_[1], $_[0];
} # new

sub c ($) {
  return $_[0]->{context};
} # c

sub client ($) {
  my ($self) = @_;
  return $self->client_for ($self->{server_data}->{app_client_url});
} # client

sub client_for ($$) {
  my ($self, $url) = @_;
  $self->{clients}->{$url->get_origin->to_ascii} ||= Web::Transport::BasicClient->new_from_url ($url, {
    proxy_manager => ServerSet::ReverseProxyProxyManager->new_from_envs ($self->{server_data}->{local_envs}),
  });
} # client_for

sub get_html ($$;$%) {
  my ($self, $path, $params, %args) = @_;
  $path = [
    (
      defined $args{group}
        ? ('g', $self->_get_o ($args{group})->{group_id})
        : ()
    ),
    (
      defined $args{index}
        ? ('i', $self->_get_o ($args{index})->{index_id})
        : ()
    ),
    @$path,
  ];
  my $cookies = {%{$args{cookies} or {}}};
  return $self->_account ($args{account})->then (sub {
    $cookies->{sk} = $_[0]->{cookies}->{sk}; # or undef
    return $self->client->request (
      path => $path,
      params => $params,
      cookies => $cookies,
      headers => $args{headers},
      body => $args{body},
    );
  })->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 200;
    my $mime = $res->header ('Content-Type') // '';
    die "Bad MIME type |$mime|"
        unless $mime eq 'text/html; charset=utf-8';
    return {status => $res->status,
            res => $res};
  });
} # get_html

sub get_json ($$;$%) {
  my ($self, $path, $params, %args) = @_;
  $path = [
    (
      defined $args{group}
        ? ('g', $self->_get_o ($args{group})->{group_id})
        : ()
    ),
    (
      defined $args{index}
        ? ('i', $self->_get_o ($args{index})->{index_id})
        : ()
    ),
    @$path,
  ];
  my $cookies = {%{$args{cookies} or {}}};
  return $self->_account ($args{account})->then (sub {
    $cookies->{sk} = $_[0]->{cookies}->{sk}; # or undef
    return $self->client->request (
      path => $path,
      params => $params,
      cookies => $cookies,
      headers => $args{headers},
      body => $args{body},
    );
  })->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 200;
    my $mime = $res->header ('Content-Type') // '';
    die "Bad MIME type |$mime|"
        unless $mime eq 'application/json; charset=utf-8';
    return {status => $res->status,
            json => (json_bytes2perl $res->body_bytes),
            res => $res};
  });
} # get_json

sub get_file ($$;$%) {
  my ($self, $path, $params, %args) = @_;
  $path = [
    (
      defined $args{group}
        ? ('g', $self->_get_o ($args{group})->{group_id})
        : ()
    ),
    (
      defined $args{index}
        ? ('i', $self->_get_o ($args{index})->{index_id})
        : ()
    ),
    @$path,
  ];
  my $cookies = {%{$args{cookies} or {}}};
  return $self->_account ($args{account})->then (sub {
    $cookies->{sk} = $_[0]->{cookies}->{sk}; # or undef
    return $self->client->request (
      path => $path,
      params => $params,
      cookies => $cookies,
      headers => $args{headers},
      body => $args{body},
    );
  })->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 200;
    return {status => $res->status,
            res => $res};
  });
} # get_file

sub get_redirect ($$;$%) {
  my ($self, $path, $params, %args) = @_;
  $path = [
    (
      defined $args{group}
        ? ('g', $self->_get_o ($args{group})->{group_id})
        : ()
    ),
    (
      defined $args{index}
        ? ('i', $self->_get_o ($args{index})->{index_id})
        : ()
    ),
    @$path,
  ];
  my $cookies = {%{$args{cookies} or {}}};
  return $self->_account ($args{account})->then (sub {
    $cookies->{sk} = $_[0]->{cookies}->{sk}; # or undef
    return $self->client->request (
      path => $path,
      params => $params,
      cookies => $cookies,
      headers => $args{headers},
      body => $args{body},
    );
  })->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 302;
    return {status => $res->status,
            res => $res};
  });
} # get_redirect

sub post_json ($$$;%) {
  my ($self, $path, $params, %args) = @_;
  $path = [
    (
      defined $args{group}
        ? ('g', $self->_get_o ($args{group})->{group_id})
        : ()
    ),
    (
      defined $args{index}
        ? ('i', $self->_get_o ($args{index})->{index_id})
        : ()
    ),
    @$path,
  ];
  my $cookies = {%{$args{cookies} or {}}};
  return $self->_account ($args{account})->then (sub {
    $cookies->{sk} = $_[0]->{cookies}->{sk}; # or undef
    return $self->client->request (
      path => $path,
      method => 'POST',
      params => $params,
      headers => {
        %{$args{headers} or {}},
        origin => $self->client->origin->to_ascii,
      },
      cookies => $cookies,
      body => $args{body},
    );
  })->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 200;
    my $mime = $res->header ('Content-Type') // '';
    die "Bad MIME type |$mime|"
        unless $mime eq 'application/json; charset=utf-8';
    return {status => $res->status,
            json => (json_bytes2perl $res->body_bytes),
            res => $res};
  });
} # post_json

sub post_redirect ($$$;%) {
  my ($self, $path, $params, %args) = @_;
  $path = [
    (
      defined $args{group}
        ? ('g', $self->_get_o ($args{group})->{group_id})
        : ()
    ),
    (
      defined $args{index}
        ? ('i', $self->_get_o ($args{index})->{index_id})
        : ()
    ),
    @$path,
  ];
  my $cookies = {%{$args{cookies} or {}}};
  return $self->_account ($args{account})->then (sub {
    $cookies->{sk} = $_[0]->{cookies}->{sk}; # or undef
    return $self->client->request (
      path => $path,
      method => 'POST',
      params => $params,
      headers => {
        %{$args{headers} or {}},
        origin => $self->client->origin->to_ascii,
      },
      cookies => $cookies,
      body => $args{body},
    );
  })->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 302;
    return {status => $res->status, res => $res};
  });
} # post_redirect

sub generate_key ($$$) {
  my ($self, $name, $opts) = @_;
  my $length = $opts->{length} || int rand ($opts->{max_length} || 200) || 1;
  $length = $opts->{min_length} if defined $opts->{min_length} and $length < $opts->{min_length};
  my $bytes = '';
  $bytes .= ['0'..'9','A'..'Z','a'..'z']->[rand 36] for 1..$length;
  return $self->{objects}->{$name} = $bytes;
} # generate_key

sub generate_url ($$$) {
  my ($self, $name, $opts) = @_;
  return $self->{objects}->{$name // ''} = 'https://' . rand . '.test/' . rand;
} # generate_url

sub generate_text ($;$) {
  my $v = rand;
  $v .= chr int rand 0x10FFFF for 1..rand 10;
  return $_[0]->{objects}->{$_[1] // ''} = decode_web_utf8 encode_web_utf8 $v;
} # generate_text

sub create ($;@) {
  my $self = shift;
  return promised_for {
    my ($name, $type, $opts) = @{$_[0]};
    my $method = 'create_' . $type;
    return $self->$method ($name => $opts);
  } [@_];
} # create

sub create_group ($$$) {
  my ($self, $name, $opts) = @_;
  my @owner = @{$opts->{owners} or []};
  push @owner, $opts->{owner} if defined $opts->{owner};
  push @owner, '' unless @owner;
  my $owner = shift @owner;
  return Promise->resolve->then (sub {
    if ($owner eq '') {
      $owner = rand;
      return $self->create_account ($owner => {});
    }
  })->then (sub {
    return $self->post_json (['g', 'create.json'], {
      title => $opts->{title} // rand,
    }, account => $owner);
  })->then (sub {
    my $o = $self->{objects}->{$name // 'X'} = $_[0]->{json};
    return promised_for {
      return $self->_account (shift)->then (sub {
        my $account = $_[0];
        return $self->post_json (['g', $o->{group_id}, 'members', 'status.json'], {
          account_id => $account->{account_id},
          member_type => 1, # member
          owner_status => 1, # open
        }, account => $owner)->then (sub {
          return $self->post_json (['g', $o->{group_id}, 'members', 'status.json'], {
            account_id => $account->{account_id},
            user_status => 1, # open
          }, account => $account);
        });
      });
    } $opts->{members} || [];
  })->then (sub {
    my $o = $self->{objects}->{$name // 'X'};
    return promised_for {
      return $self->_account (shift)->then (sub {
        my $account = $_[0];
        return $self->post_json (['g', $o->{group_id}, 'members', 'status.json'], {
          account_id => $account->{account_id},
          member_type => 2, # owner
          owner_status => 1, # open
        }, account => $owner)->then (sub {
          return $self->post_json (['g', $o->{group_id}, 'members', 'status.json'], {
            account_id => $account->{account_id},
            user_status => 1, # open
          }, account => $account);
        });
      });
    } \@owner;
  })->then (sub {
    return unless defined $opts->{theme};
    my $o = $self->{objects}->{$name // 'X'};
    return $self->post_json (['g', $o->{group_id}, 'edit.json'], {
      theme => $opts->{theme},
    }, account => $owner);
  });
} # create_group

sub create_index ($$$) {
  my ($self, $name, $opts) = @_;
  return $self->post_json (['i', 'create.json'], {
    title => $opts->{title} // rand,
    index_type => $opts->{index_type} // 1,
    subtype => $opts->{subtype}, # or undef
  },
    account => ($opts->{account} // die "No |account|"),
    group => ($opts->{group} // die "No |group|"),
  )->then (sub {
    $self->{objects}->{$name} = $_[0]->{json};
    my %edit;
    for (qw(theme color deadline)) {
      $edit{$_} = $opts->{$_} if defined $opts->{$_};
    }
    return unless keys %edit;
    return $self->post_json (['i', $_[0]->{json}->{index_id}, 'edit.json'], {
      %edit,
    }, account => $opts->{account}, group => $opts->{group});
  })->then (sub {
    return unless $opts->{is_default_wiki};
    return $self->post_json (['edit.json'], {
      default_wiki_index_id => $self->{objects}->{$name}->{index_id},
    }, account => $opts->{account}, group => $opts->{group});
  });
} # create_index

sub index ($$;%) {
  my ($self, $index, %args) = @_;
  return $self->get_json (['i', $index->{index_id}, 'info.json'], {}, account => $args{account}, group => $index)->then (sub {
    return $_[0]->{json};
  });
} # index

sub create_object ($$$) {
  my ($self, $name, $opts) = @_;
  return $self->post_json (['o', 'create.json'], {
  },
    account => ($opts->{account} // die "No |account|"),
    group => ($opts->{group} // die "No |group|"),
  )->then (sub {
    $self->{objects}->{$name // 'X'} = $_[0]->{json};
    my %param;
    if (exists $opts->{index}) {
      my $index = $self->_get_o ($opts->{index});
      push @{$param{index_id} ||= []}, $index->{index_id} if defined $index;
      $param{edit_index_id} = 1;
    }
    for my $key (qw(timestamp body_type user_status owner_status
                    title body todo_state author_name author_hatena_id)) {
      $param{$key} = $opts->{$key} if defined $opts->{$key};
    }
    if (defined $opts->{parent_object}) {
      $param{parent_object_id} = $self->_get_o ($opts->{parent_object})->{object_id};
    }
    if (defined $opts->{called_account}) {
      $param{called_account_id} = [map { $self->_get_o ($_)->{account_id} } ref $opts->{called_account} ? @{$opts->{called_account}} : $opts->{called_account}];
    }
    if (keys %param) {
      return $self->post_json (['o', $_[0]->{json}->{object_id}, 'edit.json'],
                               \%param,
                               group => $opts->{group},
                               account => $opts->{account});
    }
  });
} # create_object

sub object ($$%) {
  my ($self, $obj, %args) = @_;
  return $self->get_json (['o', 'get.json'], {
    object_id => $obj->{object_id},
    ($args{revision} ? (object_revision_id => $obj->{object_revision_id}) : ()),
    (defined $args{revision_id} ? (object_revision_id => $args{revision_id}) : ()),
    with_data => 1,
  }, group => $obj, account => $args{account})->then (sub {
    return $_[0]->{json}->{objects}->{$obj->{object_id}};
  });
} # object

sub create_invitation ($$) {
  my ($self, $name, $opts) = @_;
  return $self->post_json (['members', 'invitations', 'create.json'], {
    member_type => $opts->{member_type},
  }, account => $opts->{account}, group => $opts->{group})->then (sub {
    $self->{objects}->{$name} = $_[0]->{json};
  });
} # create_invitation

sub accounts_client ($) {
  my $self = $_[0];
  return $self->client_for ($self->{server_data}->{accounts_client_url});
} # accounts_client

sub create_account ($$$) {
  my ($self, $name => $opts) = @_;
  $opts->{name} //= "\x{6322}" . rand;
  my $account = {};
  return $self->accounts_client->request (
    method => 'POST',
    path => ['session'],
    params => {
      sk_context => $self->{server_data}->{accounts_context},
    },
    bearer => $self->{server_data}->{accounts_key},
  )->then (sub {
    die $_[0] unless $_[0]->status == 200;
    $account->{cookies}->{sk} = (json_bytes2perl $_[0]->body_bytes)->{sk};
    return $self->accounts_client->request (
      method => 'POST',
      path => ['create'],
      params => {
        sk_context => $self->{server_data}->{accounts_context},
        sk => $account->{cookies}->{sk},
        name => $opts->{name},
      },
      bearer => $self->{server_data}->{accounts_key},
    );
  })->then (sub {
    die $_[0] unless $_[0]->status == 200;
    $account->{account_id} = (json_bytes2perl $_[0]->body_bytes)->{account_id};
    $self->{objects}->{$name} = $account;
  });
} # create_account

## account => undef - no account
## account => ''    - new account
## account => $hash - account object
## account => $name - account object by name
sub _account ($$) {
  my ($self, $account) = @_;
  if (defined $account) {
    if (ref $account) {
      return Promise->resolve ($account);
    } elsif ($account eq '') {
      my $name = rand;
      return $self->create_account ($name, {})->then (sub {
        return $self->o ($name);
      });
    } else {
      return Promise->resolve ($self->o ($account));
    }
  } else {
    return Promise->resolve (undef);
  }
} # _account

sub app_rev ($) {
  return $_[0]->{server_data}->{app_rev};
} # app_rev

sub resolve ($$) {
  my $self = shift;
  return Web::URL->parse_string (shift, $self->{server_data}->{app_client_url});
} # resolve

sub o ($$) {
  return $_[0]->{objects}->{$_[1]} // die "No object |$_[1]|", Carp::longmess;
} # o

sub _get_o ($$) {
  my $self = $_[0];
  if (not defined $_[1]) {
    return undef;
  } elsif (ref $_[1]) {
    return $_[1];
  } else {
    return $self->o ($_[1]);
  }
} # _get_o

sub set_o ($$$) {
  $_[0]->{objects}->{$_[1]} = $_[2];
} # set_o

sub pages_ok ($$$$;$) {
  my $self = $_[0];
  my ($path, $params, %args) = @{$_[1]};
  my $items = [@{$_[2]}];
  my $field = $_[3];
  my $name = $_[4];
  my $count = int (@$items / 2) + 3;
  my $page = 1;
  my $ref;
  my $has_error = 0;
  return promised_cleanup {
    return if $has_error;
    note "no error (@{[$page-1]} pages)";
    return $self->are_errors (
      ['GET', $path, $params, %args],
      [
        {params => {%$params, ref => rand}, status => 400, name => 'Bad |ref|'},
        {params => {%$params, ref => '+5353,350000'}, status => 400, name => 'Bad |ref| offset'},
        {params => {%$params, limit => 40000}, status => 400, name => 'Bad |limit|'},
      ],
      $name,
    );
  } promised_wait_until {
    return $self->get_json ($path, {%$params, limit => 2, ref => $ref}, %args)->then (sub {
      my $result = $_[0];
      my $expected_length = (@$items > 2 ? 2 : 0+@$items);
      my $actual_length = 0+@{$result->{json}->{items}};
      if ($expected_length == $actual_length) {
        if ($expected_length >= 1) {
          unless ($result->{json}->{items}->[0]->{$field} eq $self->o ($items->[-1])->{$field}) {
            test {
              is $result->{json}->{items}->[0]->{$field},
                 $self->o ($items->[-1])->{$field}, "page $page, first item";
            } $self->c, name => $name;
            $count = 0;
            $has_error = 1;
          }
        }
        if ($expected_length >= 2) {
          unless ($result->{json}->{items}->[1]->{$field} eq $self->o ($items->[-2])->{$field}) {
            test {
              is $result->{json}->{items}->[1]->{$field},
                 $self->o ($items->[-2])->{$field}, "page $page, second item";
            } $self->c, name => $name;
            $count = 0;
            $has_error = 1;
          }
        }
        pop @$items;
        pop @$items;
      } else {
        test {
          is $actual_length, $expected_length, "page $page length";
        } $self->c, name => $name;
        $count = 0;
        $has_error = 1;
      }
      if (@$items) {
        unless ($result->{json}->{has_next} and
                defined $result->{json}->{next_ref}) {
          test {
            ok $result->{json}->{has_next}, 'has_next';
            ok $result->{json}->{next_ref}, 'next_ref';
          } $self->c, name => $name;
          $count = 0;
          $has_error = 1;
        }
      } else {
        if ($result->{json}->{has_next}) {
          test {
            ok ! $result->{json}->{has_next}, 'no has_next';
          } $self->c, name => $name;
          $count = 0;
          $has_error = 1;
        }
      }
      $ref = $result->{json}->{next_ref};
    })->then (sub {
      $page++;
      return not $count >= $page;
    });
  };
} # pages_ok

sub are_errors ($$$) {
  my ($self, $base, $tests) = @_;
  my ($base_method, $base_path, $base_params, %base_args) = @$base;

  my $has_error = 0;
  my @p;
  
  for my $test (@$tests) {
    my %opt = (
      method => $base_method,
      path => $base_path,
      params => $base_params,
      basic_auth => [key => 'test'],
      origin => $self->client->origin->to_ascii,
      %base_args,
      %$test,
    );
    $opt{path} = [
      (
        defined $opt{group} # not |exists|
          ? ('g', $self->_get_o ($opt{group})->{group_id})
          : ()
      ),
      @{$opt{path} or []},
    ];
    $opt{headers} = {%{$opt{headers} or {}}};
    $opt{headers}->{Origin} = $opt{origin} if exists $opt{origin};
    $opt{cookies} = {%{$opt{cookies} or {}}};
    push @p, $self->_account ($opt{account})->then (sub {
      $opt{cookies}->{sk} = $_[0]->{cookies}->{sk}; # or undef
    })->then (sub {
      return $self->client->request (
        method => $opt{method}, path => $opt{path}, params => $opt{params},
        basic_auth => $opt{basic_auth},
        headers => $opt{headers}, cookies => $opt{cookies},
        body => $opt{body},
      );
    })->then (sub {
      my $res = $_[0];
      unless ($opt{status} == $res->status) {
        test {
          is $res->status, $opt{status}, $res;
        } $self->c, name => $opt{name};
        $has_error = 1;
      }
      for my $name (keys %{$opt{response_headers} or {}}) {
        my $expected_value = $opt{response_headers}->{$name};
        my $actual_value = $res->header ($name);
        if (defined $actual_value and defined $expected_value and
            $actual_value eq $expected_value) {
          #
        } elsif (not defined $actual_value and not defined $expected_value) {
          #
        } else {
          test {
            is $actual_value, $expected_value, "Response header $name:";
          } $self->c;
          $has_error = 1;
        }
      }
    });
  }

  return Promise->all (\@p)->then (sub {
    unless ($has_error) {
      test {
        ok 1, 'no error';
      } $self->c;
    }
  });
} # are_errors

sub create_browser ($$$) {
  my ($self, $name, $opts) = @_;
  die "No |browser| option for |Test|"
      if not defined $self->{server_data}->{wd_local_url};
  die "Duplicate browser |$name|" if defined $self->{browsers}->{$name};
  $self->{browsers}->{$name} = '';
  require Web::Driver::Client::Connection;
  my $wd = Web::Driver::Client::Connection->new_from_url
      ($self->{server_data}->{wd_local_url});
  push @{$self->{wds} ||= []}, $wd;
  return $wd->new_session (
    desired => {},
    http_proxy_url => Web::URL->parse_string ($self->{server_data}->{docker_envs}->{http_proxy}) || die,
  )->then (sub {
    $self->{browsers}->{$name} = $_[0];
    return $self->b_set_account ($name, $opts->{account})
        if defined $opts->{account};
  })->then (sub {
    return $self->b_go ($name, $opts->{url}, params => $opts->{params}, fragment => $opts->{fragment})
        if defined $opts->{url};
  });
} # create_browser

sub b ($$) {
  my ($self, $name) = @_;
  return $self->{browsers}->{$name} || die "No browser |$name|";
} # b

sub b_go ($$$;%) {
  my ($self, $name, $url, %args) = @_;
  if (ref $url eq 'ARRAY') {
    $url = join '/', map { percent_encode_c $_ } '', @$url;
  }
  $url .= '#' . $args{fragment} if defined $args{fragment};
  $url = $self->resolve ($url);
  if (defined $args{params}) {
    $url->set_query_params ($args{params});
  }
  return $self->b ($name)->go ($url);
} # b_go

sub b_set_account ($$$) {
  my ($self, $name, $user) = @_;
  return $self->b_go ($name, '/robots.txt')->then (sub {
    return $self->_account ($user);
  })->then (sub {
    return $self->b ($name)->set_cookie
        (sk => defined $_[0] ? $_[0]->{cookies}->{sk} : '', path => '/');
  });
} # b_set_account

sub b_wait ($$$) {
  my ($self, $name, $for) = @_;
  my $i = 0;
  return promised_wait_until {
    return Promise->resolve->then (sub {
      return $self->b_screenshot ($name, $for->{name} // $for->{selector})
          if $i++ > 5;
    })->then (sub {
      return $self->b_save_source ($name, $for->{name} // $for->{selector})
          if $i++ > 5;
    })->then (sub {
      return Promise->all ([
        (defined $for->{element} ? Promise->resolve ([1, $for->{element}]) : defined $for->{selector} ? $self->b ($name)->execute (q{
          return document.querySelector (arguments[0]);
        }, [$for->{selector}])->then (sub {
          return [1, $_[0]->json->{value}];
        }) : Promise->resolve ([0, undef]))->then (sub {
          return 1 unless $_[0]->[0];
          my $selected = $_[0]->[1];
          return 0 unless $selected;
          
          return Promise->resolve->then (sub {
            if ($for->{shown}) {
              return $self->b_is_hidden ($name, $selected)->then (sub {
                if ($_[0]) {
                  return 0;
                } else {
                  return 1;
                }
              });
            }
            return 1;
          })->then (sub {
            return $_[0] if not $_[0] or not $for->{scroll};
            return $self->b ($name)->execute (q{
              arguments[0].scrollIntoView (false);
            }, [$selected]);
            return 1;
          })->then (sub {
            return $_[0] if not $_[0] or not defined $for->{text};
            return $self->b ($name)->execute (q{
              return arguments[0].textContent;
            }, [$selected])->then (sub {
              my $res = $_[0];
              return $res->json->{value} =~ /\Q@{[$for->{text}]}\E/;
            });
          })->then (sub {
            return $_[0] if not $_[0] or not defined $for->{html};
            return $self->b ($name)->execute (q{
              return arguments[0].outerHTML;
            }, [$selected])->then (sub {
              my $res = $_[0];
              return $res->json->{value} =~ /\Q@{[$for->{html}]}\E/;
            });
          })->then (sub {
            return $_[0] if not $_[0] or not $for->{disabled};
            return $self->b ($name)->execute (q{
              return arguments[0].disabled;
            }, [$selected])->then (sub {
              my $res = $_[0];
              return $res->json->{value};
            });
          })->then (sub {
            return $_[0] if not $_[0] or not $for->{enabled};
            return $self->b ($name)->execute (q{
              return arguments[0].disabled;
            }, [$selected])->then (sub {
              my $res = $_[0];
              return ! $res->json->{value};
            });
          });
        }),
        (defined $for->{code} ? Promise->resolve->then ($for->{code}) : 1),
      ])->then (sub {
        my @has_false = grep { ! $_ } @{$_[0]};
        if ($for->{not}) {
          return !!@has_false;
        } else {
          return ! @has_false;
        }
      });
    })->catch (sub {
      my $err = $_[0];
      warn $err; # e.g. stale element reference (after navigation)
      return 0;
    });
  } timeout => 60*2;
} # b_wait

sub b_screenshot ($$$) {
  my ($self, $name, $hint) = @_;
  return $self->b ($name)->screenshot->then (sub {
    return $self->save_artifact ($_[0], [$name, 'screenshot', ref $hint eq 'ARRAY' ? @$hint : $hint], 'png');
  });
} # b_screenshot

sub b_save_source ($$$) {
  my ($self, $name, $hint) = @_;
  return $self->b ($name)->execute (q{
    return document.documentElement.outerHTML;
  })->then (sub {
    my $res = $_[0];
    die $res if $res->is_error;
    return $self->save_artifact
        (encode_web_utf8 $_[0]->json->{value},
         [$name, 'source', ref $hint eq 'ARRAY' ? @$hint : $hint], 'html');
  });
} # b_save_source

sub save_artifact ($$$$) {
  my ($self, $data, $name, $ext) = @_;
  $name = [
    $self->{test_script_path},
    $self->c->test_name,
    map { ref $_ eq 'ARRAY' ? @$_ : $_ } @$name,
  ];
  $name = join '-', map {
    my $v = $_ // '';
    $v =~ s/[^A-Za-z0-9_]/_/g;
    $v;
  } @$name;
  my $path = $self->{server_data}->{artifacts_path}->child ($name . '.' . $ext);
  warn "Save artifact file |$path|...\n";
  my $file = Promised::File->new_from_path ($path);
  return $file->write_byte_string ($data);
} # save_artifact

# XXX WD
sub b_is_hidden ($$$) {
  my ($self, $name, $element) = @_;
    return $self->b ($name)->execute (q{
    return [arguments[0].offsetWidth, arguments[0].offsetHeight];
  }, [$element])->then (sub {
    return ! ($_[0]->json->{value}->[0] && $_[0]->json->{value}->[1]);
  });
} # b_is_hidden

sub done ($) {
  my $self = $_[0];
  delete $self->{client};
  return Promise->all ([
    (map { $_->close } values %{delete $self->{client_for} or {}}),
    (map { $_->close } values %{delete $self->{browsers} or {}}),
  ])->then (sub {
    return Promise->all ([
      (map { $_->close } @{delete $self->{wds} or []}),
    ]);
  })->finally (sub {
    (delete $self->{context})->done;
  });
} # done

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
