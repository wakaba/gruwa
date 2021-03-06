package CurrentTest;
use strict;
use warnings;
use Path::Tiny;
use Promise;
use Promised::Flow;
use Promised::File;
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
    $cookies->{sk} //= $_[0]->{cookies}->{sk}; # or undef
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
    if ($args{redirected}) {
      die $res unless $res->status == 302;
      my $url = Web::URL->parse_string ($res->header ('location'));
      die $res unless $url and $url->is_http_s;
      return $self->client_for ($url)->request (
        url => $url,
      )->then (sub {
        my $res = $_[0];
        die $res unless $res->status == 200;
        return {status => $res->status,
                res => $res};
      });
    } else {
      die $res unless $res->status == 200;
      return {status => $res->status,
              res => $res};
    }
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
    $cookies->{sk} //= $_[0]->{cookies}->{sk}; # or undef
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

sub generate_domain ($$$) {
  my ($self, $name, $opts) = @_;
  return $self->{objects}->{$name // ''} = rand . '.test';
} # generate_domain

sub generate_email_addr ($$$) {
  my ($self, $name, $opts) = @_;
  return $self->{objects}->{$name // ''} = rand . '@' . $self->generate_domain (undef, {});
} # generate_email_addr

sub generate_url ($$$) {
  my ($self, $name, $opts) = @_;
  return $self->{objects}->{$name // ''} = 'https://' . $self->generate_domain (undef, {}) . '/' . rand;
} # generate_url

sub generate_push_url ($$$) {
  my ($self, $name, $opts) = @_;
  return $self->set_o ($name => 'http://xs.server.test/push/' . rand);
} # generate_push_url

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
    source_page => $opts->{source_page},
    source_site => $opts->{source_site},
    is_file => !!$opts->{file},
  },
    account => ($opts->{account} // die "No |account|"),
    group => ($opts->{group} // die "No |group|"),
  )->then (sub {
    my $result = $_[0];
    $self->{objects}->{$name // 'X'} = $result->{json};
    my %param;
    if (exists $opts->{index}) {
      for (ref $opts->{index} ? @{$opts->{index}} : $opts->{index}) {
        my $index = $self->_get_o ($_);
        push @{$param{index_id} ||= []}, $index->{index_id} if defined $index;
        $param{edit_index_id} = 1;
      }
    }
    for my $key (qw(timestamp user_status owner_status
                    title todo_state author_name author_hatena_id
                    body body_type body_source body_source_type)) {
      $param{$key} = $opts->{$key} if defined $opts->{$key};
    }
    if (defined $opts->{body_data}) {
      $param{body_data} = perl2json_chars $opts->{body_data};
    }
    if (defined $opts->{parent_object}) {
      $param{parent_object_id} = $self->_get_o ($opts->{parent_object})->{object_id};
    }
    if (defined $opts->{called_account}) {
      $param{called_account_id} = [map { $self->_get_o ($_)->{account_id} } ref $opts->{called_account} ? @{$opts->{called_account}} : $opts->{called_account}];
    }
    if (defined $opts->{assigned_account}) {
      $param{assigned_account_id} = [map { $self->_get_o ($_)->{account_id} } ref $opts->{assigned_account} ? @{$opts->{assigned_account}} : $opts->{assigned_account}];
      $param{edit_assigned_account_id} = 1;
    }

    my @p;
    
    if (defined $opts->{file}) {
      my $file = delete $opts->{file};
      $param{mime_type} = $file->{mime_type};
      push @p, Promised::File->new_from_path (path (__FILE__)->parent->parent->parent->child ('t_deps/files', $file->{file}))->read_byte_string->then (sub {
        my $body = $_[0];
        $self->post_json (['o', $result->{json}->{object_id}, 'upload.json'], {
          token => $result->{json}->{upload_token},
        }, account => 'a1', group => 'g1', body => $body);
      });
    }
    
    if (keys %param) {
      push @p, $self->post_json (['o', $result->{json}->{object_id}, 'edit.json'],
                               \%param,
                               group => $opts->{group},
                               account => $opts->{account});
    }

    return Promise->all (\@p);
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

sub add_star ($$) {
  my ($self, $opts) = @_;
  my $object = $self->_get_o ($opts->{object} // die "No |object|");
  return $self->post_json (['star', 'add.json'], {
    object_id => $object->{object_id},
    delta => $opts->{delta} // 1,
  },
    account => ($opts->{account} // die "No |account|"),
    group => ($opts->{group} // die "No |group|"),
  );
} # add_star

sub create_invitation ($$) {
  my ($self, $name, $opts) = @_;
  if (exists $opts->{default_index}) {
    for (ref $opts->{default_index} ? @{$opts->{default_index}} : $opts->{default_index}) {
      my $index = $self->_get_o ($_) // die $_;
      $opts->{default_index_id} = $index->{index_id};
    }
  }
  return $self->post_json (['members', 'invitations', 'create.json'], {
    member_type => $opts->{member_type},
    default_index_id => $opts->{default_index_id},
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
  return Promise->resolve->then (sub {
    my $account = {};
    $self->set_o ($name => $account);
    if ($opts->{xs}) {
      return $self->client->request (path => ['account', 'login'], headers => {
        origin => $self->client->origin->to_ascii,
      }, method => 'POST', params => {
        server => 'test1',
      })->then (sub {
        my $res = $_[0];
        $res->header ('Set-Cookie') =~ /sk=([^;]+)/ or die;
        $account->{cookies}->{sk} = $1;
        my $url = Web::URL->parse_string ($res->header ('Location'));
        my $client = $self->client_for ($url);
        $account->{xs_name} = $self->generate_key (rand, {});
        return $client->request (url => $url, params => {
          name => $account->{xs_name},
        });
      })->then (sub {
        my $res = $_[0];
        die $res unless $res->status == 200;
        my $code = $res->header ('X-Code');
        my $state = $res->header ('X-State');
        return $self->client->request (path => ['account', 'cb'], params => {
          code => $code,
          state => $state,
        }, cookies => $account->{cookies});
      })->then (sub {
        return $self->post_redirect (['account', 'agree'], {
          agree => 1,
        }, cookies => $account->{cookies});
      })->then (sub {
        return $self->get_json (['my', 'info.json'], {
        }, cookies => $account->{cookies});
      })->then (sub {
        $account->{account_id} = $_[0]->{json}->{account_id};
      });
      # $opts->{name}
      # $opts->{terms_version}
    } else { # not xs
      $opts->{name} //= $self->generate_text (rand, {});
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
            terms_version => $opts->{terms_version} // 12,
          },
          bearer => $self->{server_data}->{accounts_key},
        );
      })->then (sub {
        die $_[0] unless $_[0]->status == 200;
        $account->{account_id} = (json_bytes2perl $_[0]->body_bytes)->{account_id};

        if (defined $opts->{email} and $opts->{email} eq 1) {
          $opts->{email} = $self->generate_email_addr (undef, {});
        }
        if (defined $opts->{email}) {
          return promised_for {
            my $addr = shift;
            return $self->accounts_client->request (
              method => 'POST',
              path => ['email', 'input'],
              params => {
                sk_context => $self->{server_data}->{accounts_context},
                sk => $account->{cookies}->{sk},
                addr => $addr,
              },
              bearer => $self->{server_data}->{accounts_key},
            )->then (sub {
              die $_[0] unless $_[0]->status == 200;
              return $self->accounts_client->request (
                method => 'POST',
                path => ['email', 'verify'],
                params => {
                  sk_context => $self->{server_data}->{accounts_context},
                  sk => $account->{cookies}->{sk},
                  key => (json_bytes2perl $_[0]->body_bytes)->{key},
                },
                bearer => $self->{server_data}->{accounts_key},
              );
            })->then (sub {
              die $_[0] unless $_[0]->status == 200;
            });
          } [ref $opts->{email} ? @{$opts->{email}} : $opts->{email}];
        } # email
      });
    }
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
  return $_[0]->{objects}->{$_[1]} = $_[2];
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

sub b_set_xs_name ($$$) {
  my ($current, $name, $oname) = @_;
  return $current->b ($name)->execute (q{
    return fetch ('http://xs.server.test/setname?name=' + encodeURIComponent (arguments[0]), {
      credentials: 'include',
    }).catch (e => {
      return "" + e;
    });
  }, [$current->o ($oname)->{xs_name}])->then (sub {
    #warn $_[0]->json->{value};
  });
} # b_set_xs_name

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

sub b_element_rect ($$$) {
  my ($self, $name, $e) = @_;
  #return $self->b ($name)->http_post (['element', $e->{ELEMENT}, 'rect'], {})->then (sub {
  #  my $res = $_[0];
  #  die $res if $res->is_error;
  #  my $v = $res->json->{value};
  #});
  return $self->b ($name)->execute (q{
    var rect = arguments[0].getClientRects ()[0];
    return rect;
  }, [$e])->then (sub {
    my $res = $_[0];
    die $res if $res->is_error;
    return $res->json->{value};
  });
} # b_element_rect

sub b_pointer_move ($$$) {
  my ($self, $name, $opts) = @_;
  my $id = '' . ($opts->{action_id} // rand);
  return Promise->resolve->then (sub {
    return if defined $self->{has_b_actions};

    ## XXX Recent versions of ChromeDriver has /actions but somewhat
    ## broken...
    return $self->b ($name)->http_post (['moveto'], {
      xoffset => 0,
      yoffset => 0,
    })->then (sub {
      $self->{has_b_actions} = $_[0]->is_error;
    });


    return $self->b ($name)->http_post (['actions'], {
      actions => [],
    })->then (sub {
      my $res = $_[0];
      $self->{has_b_actions} = not $res->is_error;
    });
  })->then (sub {
    if (defined $opts->{element} and not defined $opts->{point}) {
      if ($self->{has_b_actions}) {
        return $self->b ($name)->http_post (['actions'], {
          actions => [{
            type => 'pointer',
            id => $id,
            actions => [
              {
                type => 'pointerMove',
                origin => $opts->{element}, x => 0, y => 0,
              },
            ],
          }],
        })->then (sub {
          die $_[0] if $_[0]->is_error;
        });
      } else {
        return $self->b ($name)->http_post (['moveto'], {
          element => $opts->{element}->{ELEMENT},
        })->then (sub {
          die $_[0] if $_[0]->is_error;
        });
      }
    } elsif (defined $opts->{element} and defined $opts->{point}) {
      if ($self->{has_b_actions}) {
        return $self->b_element_rect (1, $opts->{element})->then (sub {
          my $v = $_[0];
          return $self->b ($name)->http_post (['actions'], {
            actions => [{
              type => 'pointer',
              id => $id,
              actions => [
                {
                  type => 'pointerMove',
                  origin => 'viewport',
                  x => int ($v->{x} + $opts->{point}->[0]),
                  y => int ($v->{y} + $opts->{point}->[1]),
                },
              ],
            }],
          })->then (sub {
            die $_[0] if $_[0]->is_error;
          });
        });
      } else {
        return $self->b ($name)->http_post (['moveto'], {
          element => $opts->{element}->{ELEMENT},
          xoffset => int ($opts->{point}->[0]),
          yoffset => int ($opts->{point}->[1]),
        })->then (sub {
          die $_[0] if $_[0]->is_error;
        });
      }
    } elsif (defined $opts->{delta}) {
      if ($self->{has_b_actions}) {
        return $self->b ($name)->http_post (['actions'], {
          actions => [{
            type => 'pointer',
            id => $id,
            actions => [
              {
                type => 'pointerMove',
                origin => 'pointer',
                x => int ($opts->{delta}->[0]),
                y => int ($opts->{delta}->[1]),
                duration => 500,
              },
            ],
          }],
        })->then (sub {
          die $_[0] if $_[0]->is_error;
        });
      } else {
        return $self->b (1)->http_post (['moveto'], {
          xoffset => int ($opts->{delta}->[0]/2),
          yoffset => int ($opts->{delta}->[1]/2),
        })->then (sub {
          die $_[0] if $_[0]->is_error;
          return $self->b (1)->http_post (['moveto'], {
            xoffset => int ($opts->{delta}->[0]/2),
            yoffset => int ($opts->{delta}->[1]/2),
          })->then (sub {
            die $_[0] if $_[0]->is_error;
          });
        });
      }
    }
    # else, do nothing
  });
} # b_pointer_move

# XXX
sub b_drag ($$$) {
  my ($self, $name, $opts) = @_;
  my $id = '' . rand;
  my $key_id = $id . 2;
  my $primary_button = $opts->{right} ? 2 : 0;
  my $secondary_button = $opts->{right} ? 0 : 2;
  return Promise->resolve->then (sub {
    die "No |start|" unless defined $opts->{start};
    die "No |end|" unless defined $opts->{end};
    return $self->b_pointer_move (1, {
      %{$opts->{start} or {}},
      action_id => $id,
    });
  })->then (sub {
    return $self->b_screenshot (1, [$opts->{screenshot_name}, 'before'])
        if defined $opts->{screenshot_name};
  })->then (sub {
    return unless $opts->{shift};
    if ($self->{has_b_actions}) {
      return $self->b ($name)->http_post (['actions'], {
        actions => [{
          type => 'key',
          id => $key_id,
          actions => [{
            type => 'keyDown',
            value => "\x{E008}", # Shift
          }],
        }],
      })->then (sub {
        die $_[0] if $_[0]->is_error;
      });
    } else {
      return $self->b (1)->http_post (['keys'], {value => [
        "\x{E008}", # Shift
      ]})->then (sub {
        die $_[0] if $_[0]->is_error;
      });
    }
  })->then (sub {
    if ($self->{has_b_actions}) {
      return $self->b ($name)->http_post (['actions'], {
        actions => [{
          type => 'pointer',
          id => $id,
          actions => [{
            type => 'pointerDown',
            button => $primary_button,
          }],
        }],
      })->then (sub {
        die $_[0] if $_[0]->is_error;
      });
    } else {
      return $self->b (1)->http_post (['buttondown'], {
        button => $primary_button,
      })->then (sub {
        die $_[0] if $_[0]->is_error;
      });
    }

  })->then (sub {
    return promised_sleep 2 if $opts->{start}->{hold};

  })->then (sub {
    return unless $opts->{astray};
    return $self->b_pointer_move ($name, {
      delta => [300, 200],
      action_id => $id,
    });
    
  })->then (sub {
    return $self->b_pointer_move ($name, {
      %{$opts->{end} or {}},
      action_id => $id,
    });
  })->then (sub {
    return $self->b_screenshot (1, [$opts->{screenshot_name}, 'dropping'])
        if defined $opts->{screenshot_name};
  })->then (sub {
    return unless $opts->{end}->{cancel};
    if ($self->{has_b_actions}) {
      return $self->b ($name)->http_post (['actions'], {
        actions => [{
          type => 'pointer',
          id => $id,
          actions => [{
            type => 'pointerDown',
            button => $secondary_button,
          }, {
            type => 'pointerUp',
            button => $secondary_button,
          }],
        }],
      })->then (sub {
        die $_[0] if $_[0]->is_error;
      });
    } else {
      return $self->b (1)->http_post (['buttondown'], {
        button => $secondary_button,
      })->then (sub {
        die $_[0] if $_[0]->is_error;
        return $self->b (1)->http_post (['buttonup'], {
          button => $secondary_button,
        });
      })->then (sub {
        die $_[0] if $_[0]->is_error;
      });
    }
  })->then (sub {
    if ($self->{has_b_actions}) {
      return $self->b ($name)->http_post (['actions'], {
        actions => [{
          type => 'pointer',
          id => $id,
          actions => [{
            type => 'pointerUp',
            button => $primary_button,
          }],
        }],
      })->then (sub {
        die $_[0] if $_[0]->is_error;
      });
    } else {
      return $self->b (1)->http_post (['buttonup'], {
        button => $primary_button,
      })->then (sub {
        die $_[0] if $_[0]->is_error;
      });
    }
  })->then (sub {
    return unless $opts->{shift};
    if ($self->{has_b_actions}) {
      return $self->b ($name)->http_post (['actions'], {
        actions => [{
          type => 'key',
          id => $key_id,
          actions => [{
            type => 'keyUp',
            value => "\x{E008}", # Shift
          }],
        }],
      })->then (sub {
        die $_[0] if $_[0]->is_error;
      });
    } else {
      return $self->b (1)->http_post (['keys'], {value => [
        "\x{E008}", # Shift
      ]})->then (sub {
        die $_[0] if $_[0]->is_error;
      });
    }
  })->then (sub {
    return $self->b_screenshot (1, [$opts->{screenshot_name}, 'dropped'])
        if defined $opts->{screenshot_name};
  });
} # b_drag

sub b_screenshot ($$$) {
  my ($self, $name, $hint) = @_;
  if ($ENV{CIRCLECI} and $ENV{TEST_WD_BROWSER} =~ /firefox/) {
    return; # firefox is broken...
  }
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

sub reset_email_count ($$) {
  my ($self, $name) = @_;
  my $addr = $self->o ($name);
  my $url = Web::URL->parse_string ("http://xs.server.test/mailgun/get");
  return $self->client_for ($url)->request (
    url => $url,
    params => {
      addr => $addr,
    },
  )->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 200;
    my $data = json_bytes2perl $res->body_bytes;
    $self->{email_counts}->{$addr} = 0+@$data;
  });
} # reset_email_count

sub get_email ($$;%) {
  my ($self, $name, %args) = @_;
  my $n = $args{n} || 1;
  my $addr = $self->o ($name);
  my $url = Web::URL->parse_string ("http://xs.server.test/mailgun/get");
  my $new;
  return ((promised_wait_until {
    return $self->client_for ($url)->request (
      url => $url,
      params => {
        addr => $addr,
      },
    )->then (sub {
      my $res = $_[0];
      die $res unless $res->status == 200;
      my $data = json_bytes2perl $res->body_bytes;
      my $new_count = 0+@$data;
      unless ($new_count >= ($self->{email_counts}->{$addr} || 0) + $n) {
        return $self->post_json (['reports', 'heartbeat'], {})->then (sub {
          return not 'done';
        });
      }
      $new = [@$data[$self->{email_counts}->{$addr}..($self->{email_counts}->{$addr}+$n-1)]];
      if (defined $args{pattern}) {
        unless ($new->[0]->{message} =~ /$args{pattern}/) {
          $self->{email_counts}->{$addr}++;
          return $self->post_json (['reports', 'heartbeat'], {})->then (sub {
            return not 'done';
          });
        }
      }
      $self->{email_counts}->{$addr} += $n;
      return 'done';
    });
  } timeout => 62, name => 'waiting for email')->then (sub {
    return $n == 1 ? $new->[0] : $new;
  }));
} # get_email

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
