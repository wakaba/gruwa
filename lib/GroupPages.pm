package GroupPages;
use strict;
use warnings;
use Time::HiRes qw(time);
use Promise;
use Promised::Flow;
use Dongry::Type;
use Dongry::Type::JSONPS;
use Dongry::SQL qw(where);
use Digest::SHA qw(sha1_hex);
use Web::DateTime::Parser;
use Web::MIME::Type;
use Web::URL;
use Web::URL::Encoding;
use Web::DOM::Document;

use Pager;
use Results;

sub get_index ($$$) {
  my $db = shift;
  return Promise->resolve (undef) unless defined $_[1];
  return $db->select ('index', {
    group_id => Dongry::Type->serialize ('text', $_[0]),
    index_id => Dongry::Type->serialize ('text', $_[1]),

    # XXX
    owner_status => 1,
    user_status => 1,
  }, fields => ['index_id', 'index_type', 'title', 'created', 'updated', 'options'])->then (sub {
    my $index = $_[0]->first;
    return undef unless defined $index;
    $index->{title} = Dongry::Type->parse ('text', $index->{title});
    $index->{options} = Dongry::Type->parse ('json', $index->{options});
    return $index;
  });
} # get_index

sub create ($$$) {
  my ($class, $app, $acall) = @_;

  # /g/create.json
  $app->requires_request_method ({POST => 1});
  $app->requires_same_origin;

  return $acall->(['info'], {
    sk_context => $app->config->{accounts}->{context},
    sk => $app->http->request_cookies->{sk},
  })->(sub {
    my $account_data = $_[0];
    return $app->throw_error (403, reason_phrase => 'No user account')
        unless defined $account_data->{account_id};

    my $title = $app->text_param ('title') // '';
    return $app->throw_error (400, reason_phrase => 'Bad |title|')
        unless length $title;

    my $group_id;
    return $acall->(['group', 'create'], {
      context_key => $app->config->{accounts}->{context} . ':group',
      owner_status => 1, # open
      admin_status => 1, # open
    })->(sub {
      $group_id = $_[0]->{group_id};
      return $acall->(['group', 'data'], {
        context_key => $app->config->{accounts}->{context} . ':group',
        group_id => $group_id,
        name => ['title', 'theme'],
        value => [$title, 'green'],
      })->();
    })->then (sub {
      return $acall->(['group', 'member', 'status'], {
        context_key => $app->config->{accounts}->{context} . ':group',
        group_id => $group_id,
        account_id => $account_data->{account_id},
        member_type => 2, # owner
        user_status => 1, # open
        owner_status => 1, # open
      })->();
    })->then (sub {
      # XXX group log
      #     ipaddr
      return json $app, {
        group_id => $group_id,
      };
    });
  });
} # create

sub main ($$$$$) {
  my ($class, $app, $path, $db, $acall) = @_;
  # /g/{group_id}/...
  return $acall->(['info'], {
    sk_context => $app->config->{accounts}->{context},
    sk => $app->http->request_cookies->{sk},

    context_key => $app->config->{accounts}->{context} . ':group',
    group_id => $path->[1],
    # XXX
    admin_status => 1,
    owner_status => 1,
    with_group_data => ['title', 'theme', 'default_wiki_index_id'],
    with_group_member_data => ['default_index_id'],
  })->(sub {
    my $account_data = $_[0];
    unless (defined $account_data->{account_id}) {
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

    my $group = $account_data->{group};
    return $app->throw_error (404, reason_phrase => 'Group not found')
        unless defined $group;

    my $membership = $account_data->{group_membership};
    return $app->throw_error (403, reason_phrase => 'Not a group member')
        if not defined $membership or
           not ($membership->{member_type} == 1 or # member
                $membership->{member_type} == 2) or # owner
           $membership->{user_status} != 1 or # open
           $membership->{owner_status} != 1; # open

    return $class->group ($app, $path, {
      account => $account_data,
      db => $db, group => $group, group_member => $membership,
      acall => $acall,
    });
  });
} # main

sub group ($$$$) {
  my ($class, $app, $path, $opts) = @_;
  my $db = $opts->{db};

  if (@$path >= 4 and $path->[2] eq 'i') {
    # /g/{group_id}/i/...
    return $class->group_index ($app, $path, $opts);
  }

  if (@$path >= 4 and $path->[2] eq 'o') {
    # /g/{group_id}/o/...
    return $class->group_object ($app, $path, $opts);
  }

  if (@$path == 4 and $path->[2] eq 'wiki') {
    # /g/{group_id}/wiki/{wiki_name}
    return get_index ($db, $path->[1], $opts->{group}->{data}->{default_wiki_index_id})->then (sub {
      return $class->wiki ($app, $opts, $_[0], $path->[3]);
    });
  }

  if (@$path == 3 and $path->[2] eq '') {
    # /g/{group_id}/
    return temma $app, 'group.index.html.tm', {
      account => $opts->{account},
      group => $opts->{group},
      group_member => $opts->{group_member},
    };
  } elsif (@$path == 3 and $path->[2] eq 'info.json') {
    # /g/{group_id}/info.json
    my $g = $opts->{group};
    return json $app, {
      group_id => ''.$g->{group_id},
      title => $g->{data}->{title},
      created => $g->{created},
      updated => $g->{updated},
      theme => $g->{data}->{theme},
      default_wiki_index_id => $g->{data}->{default_wiki_index_id},
    };
  }

  if (@$path == 3 and $path->[2] eq 'search') {
    # /g/{}/search
    return temma $app, 'group.search.html.tm', {
      account => $opts->{account},
      group => $opts->{group},
      group_member => $opts->{group_member},
    };
  }

  if (@$path == 3 and $path->[2] eq 'members') {
    # /g/{}/members
    return temma $app, 'group.members.html.tm', {
      account => $opts->{account},
      group => $opts->{group},
      group_member => $opts->{group_member},
    };
  }

  if (@$path == 3 and $path->[2] eq 'config') {
    # /g/{}/config
    return temma $app, 'group.config.html.tm', {
      account => $opts->{account},
      group => $opts->{group},
      group_member => $opts->{group_member},
    };
  }

  if (@$path == 3 and $path->[2] eq 'edit.json') {
    # /g/{group_id}/edit.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;
    my @name;
    my @value;
    my $title = $app->text_param ('title') // '';
    if (length $title) {
      push @name, 'title';
      push @value, $title;
    }
    my $theme = $app->text_param ('theme') // '';
    if (length $theme) {
      push @name, 'theme';
      push @value, $theme;
    }
    return Promise->resolve->then (sub {
      my $wiki_id = $app->bare_param ('default_wiki_index_id');
      return unless defined $wiki_id;
      return $db->select ('index', {
        group_id => Dongry::Type->serialize ('text', $path->[1]),
        index_id => $wiki_id,
        user_status => 1, # open
        owner_status => 1, # open
      }, fields => ['index_id'])->then (sub {
        return $app->throw_error (400, reason_phrase => 'Bad |default_wiki_index_id|')
            unless $_[0]->first;
        push @name, 'default_wiki_index_id';
        push @value, $wiki_id;
      });
    })->then (sub {
      return $opts->{acall}->(['group', 'data'], {
        context_key => $app->config->{accounts}->{context} . ':group',
        group_id => $path->[1],
        name => \@name,
        value => \@value,
      })->();
      # XXX logging
    })->then (sub {
      return unless @name;
      return $opts->{acall}->(['group', 'touch'], {
        context_key => $app->config->{accounts}->{context} . ':group',
        group_id => $path->[1],
      });
    })->then (sub {
      return json $app, {};
    });
  }

  if (@$path == 5 and $path->[2] eq 'imported' and $path->[4] eq 'list.json') {
    # /g/{group_id}/imported/{site}/list.json
    my $site = Web::URL->parse_string ($path->[3]);
    return $app->throw_error (404, reason_phrase => 'Bad site URL')
        unless defined $site;
    my $page = Pager::this_page ($app, limit => 100, max_limit => 100);
    my $where = {
      group_id => Dongry::Type->serialize ('text', $path->[1]),
      source_site_sha => sha1_hex (Dongry::Type->serialize ('text', $site->stringify)),
    };
    $where->{created} = $page->{value} if defined $page->{value};
    return $db->select ('imported', $where,
      fields => ['source_page', 'created', 'updated', 'type', 'dest_id', 'sync_info'],
      offset => $page->{offset}, limit => $page->{limit},
      order => ['created', $page->{order_direction}],
    )->then (sub {
      my $items = $_[0]->all->to_a;
      for (@$items) {
        $_->{sync_info} = Dongry::Type->parse ('json', $_->{sync_info});
        $_->{dest_id} .= '';
      }
      my $next_page = Pager::next_page $page, $items, 'created';
      return json $app, {items => $items, %$next_page};
    });
  }

  return $app->throw_error (404);
} # group

sub group_members_json ($$$$) {
  my ($class, $app, $group_id, $acall) = @_;
  # /g/{group_id}/members.json
  if ($app->http->request_method eq 'POST') {
    $app->requires_same_origin;
    return $acall->(['info'], {
      sk_context => $app->config->{accounts}->{context},
      sk => $app->http->request_cookies->{sk},

      context_key => $app->config->{accounts}->{context} . ':group',
      group_id => $group_id,
      # XXX
      group_admin_status => 1,
      group_owner_status => 1,
    })->(sub {
      my $account_data = $_[0];

      return $app->throw_error (403, reason_phrase => 'No user account')
          unless defined $account_data->{account_id};

      my $group = $account_data->{group};
      return $app->throw_error (404, reason_phrase => 'Group not found')
          unless defined $group;

      my $membership = $account_data->{group_membership};

      my $is_owner = (
        defined $membership and
        $membership->{member_type} == 2 and # owner
        $membership->{user_status} == 1 and # open
        $membership->{owner_status} == 1 # open
      );

      my $account_id = $app->bare_param ('account_id') // '';
      return $app->throw_error (400, reason_phrase => 'Bad |account_id|')
          unless $account_id =~ /\A[1-9][0-9]*\z/;

      my %update;
      if ($account_id eq $account_data->{account_id}) {
        unless ($is_owner) {
          $update{user_status} = $app->bare_param ('user_status');
          delete $update{user_status} unless defined $update{user_status};
        }
      } else {
        return $app->throw_error (403, reason_phrase => 'Not an owner')
            unless $is_owner;
        for my $key (qw(owner_status member_type)) {
          $update{$key} = $app->bare_param ($key);
          delete $update{$key} unless defined $update{$key};
        }
      }

      return $acall->(['group', 'member', 'status'], {
        context_key => $app->config->{accounts}->{context} . ':group',
        group_id => $group_id,
        account_id => $account_id,
        %update,
      })->(sub {
        return unless $is_owner;
        my $desc = $app->text_param ('desc');
        return unless defined $desc;
        return $acall->(['group', 'member', 'data'], {
          context_key => $app->config->{accounts}->{context} . ':group',
          group_id => $group_id,
          account_id => $account_id,
          name => 'desc',
          value => $desc,
        })->();
      });
    })->then (sub {
      return json $app, {};
    });
  } else { # GET
    return $acall->(['info'], {
      sk_context => $app->config->{accounts}->{context},
      sk => $app->http->request_cookies->{sk},

      context_key => $app->config->{accounts}->{context} . ':group',
      group_id => $group_id,
      # XXX
      group_admin_status => 1,
      group_owner_status => 1,
    })->(sub {
      my $account_data = $_[0];

      return $app->throw_error (403, reason_phrase => 'No user account')
          unless defined $account_data->{account_id};

      my $group = $account_data->{group};
      return $app->throw_error (404, reason_phrase => 'Group not found')
          unless defined $group;

      my $membership = $account_data->{group_membership};

      my $is_member = (
        defined $membership and
        ($membership->{member_type} == 2 or # owner
         $membership->{member_type} == 1) and # member
        $membership->{owner_status} == 1 and # open
        $membership->{user_status} == 1 # open
      );

      return json $app, {members => {
        $account_data->{account_id} => {
          account_id => $account_data->{account_id},
          member_type => 0,
          owner_status => $membership->{owner_status} || 0,
          user_status => $membership->{user_status} || 0,
          default_index_id => undef,
          desc => '',
        },
      }} unless $is_member;

      return $acall->(['group', 'members'], {
        context_key => $app->config->{accounts}->{context} . ':group',
        group_id => $group_id,
        with_data => ['default_index_id', 'desc'],
        ref => $app->text_param ('ref'),
      })->(sub {
        my $members = {map {
          $_->{account_id} => {
            account_id => ''.$_->{account_id},
            member_type => $_->{member_type},
            owner_status => $_->{owner_status},
            user_status => $_->{user_status},
            default_index_id => ($_->{data}->{default_index_id} ? $_->{data}->{default_index_id} : undef),
            desc => $_->{data}->{desc} // '',
          };
        } values %{$_[0]->{memberships}}};
        return json $app, {members => $members,
                           next_ref => $_[0]->{next_ref},
                           has_next => $_[0]->{has_next}};
      });
    });
  } # GET
} # group_members_json

sub source_urls ($) {
  my $app = $_[0];

  my $source_url = $app->text_param ('source_page');
  if (defined $source_url) {
    $source_url = Web::URL->parse_string ($source_url);
    return $app->throw_error (400, reason_phrase => 'Bad |source_page|')
        if not defined $source_url or
           not $source_url->is_http_s;
  }

  my $source_site_url = $app->text_param ('source_site');
  if (defined $source_site_url) {
    $source_site_url = Web::URL->parse_string ($source_site_url);
    return $app->throw_error (400, reason_phrase => 'Bad |source_site|')
        if not defined $source_site_url or
           not $source_site_url->is_http_s;
  }
  return $app->throw_error (400, reason_phrase => 'Bad |source_site|')
      if (defined $source_url and not defined $source_site_url) or
         (not defined $source_url and defined $source_site_url) or
         (defined $source_url and defined $source_site_url and
          not $source_url->get_origin->same_origin_as ($source_site_url->get_origin));

  return ($source_site_url, $source_url);
} # source_urls

sub group_index ($$$$) {
  my ($class, $app, $path, $opts) = @_;
  my $db = $opts->{db};

  if (@$path == 4 and $path->[3] eq 'list.json') {
    # /g/{group_id}/i/list.json
    my $i_types = $app->bare_param_list ('index_type');
    return $db->select ('index', {
      group_id => Dongry::Type->serialize ('text', $path->[1]),
      owner_status => 1,
      user_status => 1,
      (@$i_types ? (index_type => {-in => $i_types}) : ()),
    }, fields => ['index_id', 'index_type', 'title', 'updated', 'options'])->then (sub {
      my $subtypes = {map { $_ => 1 } @{$app->bare_param_list ('subtype')}};
      return json $app, {index_list => {map {
        $_->{index_id} => {
          group_id => $path->[1],
          index_id => ''.$_->{index_id},
          title => Dongry::Type->parse ('text', $_->{title}),
          updated => $_->{updated},
          index_type => $_->{index_type},
          theme => $_->{options}->{theme},
          color => $_->{options}->{color},
          deadline => $_->{options}->{deadline},
        };
      } grep {
        keys %$subtypes ? $subtypes->{$_->{options}->{subtype}} : 1;
      } map {
        $_->{options} = Dongry::Type->parse ('json', $_->{options});
        $_;
      } @{$_[0]->all}}};
    });
  }

  if (@$path >= 4 and $path->[3] =~ /\A[0-9]+\z/) {
    # /g/{group_id}/i/{index_id}
    return get_index ($db, $path->[1], $path->[3])->then (sub {
      my $index = $_[0];
      return $app->throw_error (404, reason_phrase => 'Index not found')
          unless defined $index;
      if (@$path == 5 and $path->[4] eq '') {
        # /g/{group_id}/i/{index_id}/
        return temma $app, 'group.index.index.html.tm', {
          account => $opts->{account},
          group => $opts->{group},
          group_member => $opts->{group_member},
          index => $index,
        };
      } elsif (@$path == 5 and $path->[4] eq 'info.json') {
        # /g/{group_id}/i/{index_id}/info.json
        return json $app, {
          group_id => $path->[1],
          index_id => ''.$index->{index_id},
          title => $index->{title},
          created => $index->{created},
          updated => $index->{updated},
          index_type => $index->{index_type},
            ## 1 blog
            ## 2 wiki
            ## 3 todo list
            ## 4 label
            ## 5 milestone
            ## 6 fileset
          theme => $index->{options}->{theme},
          color => $index->{options}->{color},
          deadline => $index->{options}->{deadline},
          subtype => $index->{options}->{subtype},
        };
      } elsif (@$path == 5 and $path->[4] eq 'edit.json') {
        # /g/{group_id}/i/{index_id}/edit.json
        $app->requires_request_method ({POST => 1});
        $app->requires_same_origin;
        my %update = (updated => time);
        my $title = $app->text_param ('title') // '';
        $update{title} = Dongry::Type->serialize ('text', $title)
            if length $title;
        my $options = $index->{options};
        my $options_modified;
        for my $key (qw(theme color)) {
          my $value = $app->text_param ($key) // '';
          if (length $value) {
            $options->{$key} = $value;
            $options_modified = 1;
          }
        }
        {
          my $value = $app->bare_param ('deadline');
          if (defined $value) {
            my $parser = Web::DateTime::Parser->new;
            $parser->onerror (sub { });
            my $dt = $parser->parse_date_string ($value);
            if (defined $dt) {
              $options->{deadline} = $dt->to_unix_number;
            } else {
              delete $options->{deadline};
            }
            $options_modified = 1;
          }
        }
        if ($options_modified) {
          $update{options} = Dongry::Type->serialize ('json', $options);
          # XXX need transaction for editing options :-<
        }
        my $index_type = $app->bare_param ('index_type');
        if (defined $index_type) {
          $update{index_type} = 0+$index_type;
        }
        return Promise->resolve->then (sub {
          return unless 1 < keys %update;
          return $db->update ('index', \%update, where => {
            group_id => Dongry::Type->serialize ('text', $path->[1]),
            index_id => Dongry::Type->serialize ('text', $path->[3]),
          });
          # XXX logging
        })->then (sub {
          return json $app, {};
        });
      } elsif (@$path == 5 and $path->[4] eq 'my.json') {
        # /g/{group_id}/i/{index_id}/my.json
        $app->requires_request_method ({POST => 1});
        $app->requires_same_origin;
        my @p;
        my $is_default = $app->bare_param ('is_default');
        if (defined $is_default) {
          push @p, $opts->{acall}->(['group', 'member', 'data'], {
            context_key => $app->config->{accounts}->{context} . ':group',
            group_id => $path->[1],
            account_id => $opts->{account}->{account_id},
            name => 'default_index_id',
            value => ($is_default ? $path->[3] : 0),
            # XXX touch
          })->();
        }
        return Promise->all (\@p)->then (sub {
          return json $app, {};
        });
      } elsif (@$path == 5 and $path->[4] eq 'config') {
        # /g/{group_id}/i/{index_id}/config
        return temma $app, 'group.index.config.html.tm', {
          account => $opts->{account},
          group => $opts->{group},
          group_member => $opts->{group_member},
          index => $index,
        };
      } elsif (@$path == 6 and $path->[4] eq 'wiki') {
        # /g/{group_id}/i/{index_id}/wiki/{wiki_name}
        return $class->wiki ($app, $opts, $index, $path->[5]);
      } else {
        return $app->throw_error (404);
      }
    });
  }

  if (@$path == 4 and $path->[3] eq 'create.json') {
    # /g/{group_id}/i/create.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;

    my $title = $app->text_param ('title') // '';
    return $app->throw_error (400, reason_phrase => 'Bad |title|')
        unless length $title;

    my ($source_site_url, $source_page_url) = source_urls $app;

    my $time = time;
    return $db->execute ('select uuid_short() as uuid')->then (sub {
      my $index_id = $_[0]->first->{uuid};
      my $index_type = 0+($app->bare_param ('index_type') || 0);
      my $options = {};
      if ($index_type == 1 or $index_type == 2 or $index_type == 3) {
        $options->{theme} = 'green';
      } elsif ($index_type == 4) {
        $options->{color} = sprintf '#%02X%02X%02X',
            int rand 256,
            int rand 256,
            int rand 256;
      }
      my $subtype = $app->bare_param ('subtype');
      $options->{subtype} = $subtype if defined $subtype;
      return $db->insert ('index', [{
        group_id => Dongry::Type->serialize ('text', $path->[1]),
        index_id => $index_id,
        title => Dongry::Type->serialize ('text', $title),
        created => $time,
        updated => $time,
        owner_status => 1, # open
        user_status => 1, # open
        index_type => $index_type,
        options => Dongry::Type->serialize ('json', $options),
      }])->then (sub {
        return unless defined $source_site_url;
        my $page = Dongry::Type->serialize ('text', $source_page_url->stringify);
        my $site = Dongry::Type->serialize ('text', $source_site_url->stringify);
        return $db->insert ('imported', [{
          group_id => Dongry::Type->serialize ('text', $path->[1]),
          source_page_sha => sha1_hex ($page),
          source_page => $page,
          source_site_sha => sha1_hex ($site),
          source_site => $site,
          created => $time,
          updated => $time,
          type => 1, # index
          dest_id => $index_id,
          sync_info => Dongry::Type->serialize ('json', {}),
        }], duplicate => {
          source_site => $db->bare_sql_fragment ('values(`source_site`)'),
          source_site_sha => $db->bare_sql_fragment ('values(`source_site_sha`)'),
          updated => $db->bare_sql_fragment ('values(`updated`)'),
          type => $db->bare_sql_fragment ('values(`type`)'),
          dest_id => $db->bare_sql_fragment ('values(`dest_id`)'),
          sync_info => $db->bare_sql_fragment ('values(`sync_info`)'),
        });
      })->then (sub {
        return json $app, {
          group_id => $path->[1],
          index_id => ''.$index_id,
        };
        # XXX logging
        # touch group
      });
    });
  }

  return $app->throw_error (404);
} # group_index

## body_type
##   1 html
##   2 plain text
##   3 data
##   4 file

my @TokenAlpha = ('0'..'9','A'..'Z','a'..'z');

sub create_object ($%) {
  my ($db, %args) = @_;
  my $time = time;
  return $db->execute ('select uuid_short() as uuid1,
                               uuid_short() as uuid2')->then (sub {
    my $ids = $_[0]->first;
    my $object_id = ''.$ids->{uuid1};
    my $data = {timestamp => $time,
                object_revision_id => ''.$ids->{uuid2},
                user_status => 1, # open
                owner_status => 1}; # open
    my $rev_data = {changes => {action => 'new'}};
    ## This does not touch `group`.

    if (defined $args{body_type}) {
      $data->{body_type} = $args{body_type};
      $data->{body_data} = $args{body_data} if defined $args{body_data};
      if ($data->{body_type} == 4) { # file
        my $token = '';
        $token .= $TokenAlpha[rand @TokenAlpha] for 1..10;
        $data->{upload_token} = $token;
      }
    } else {
      $data->{body_type} = 2; # plain text
      $data->{body} = '';
    }

    if (defined $args{parent_object_id}) {
      $data->{parent_object_id} = ''.$args{parent_object_id};
      $data->{thread_id} = ''.$args{thread_id};
    } else {
      $data->{thread_id} = $object_id;
    }

    my $sdata = Dongry::Type->serialize ('json', $data);
    return $db->insert ('object', [{
      group_id => Dongry::Type->serialize ('text', $args{group_id}),
      object_id => $object_id,
      title => '',
      data => $sdata,
      search_data => '',
      created => $time,
      updated => $time,
      timestamp => $time,
      owner_status => $data->{owner_status},
      user_status => $data->{user_status},
      thread_id => 0+$data->{thread_id},
      parent_object_id => 0+($data->{parent_object_id} || 0),
    }])->then (sub {
      return $db->insert ('object_revision', [{
        group_id => Dongry::Type->serialize ('text', $args{group_id}),
        object_id => $object_id,
        data => $sdata,

        object_revision_id => $data->{object_revision_id},
        revision_data => Dongry::Type->serialize ('json', $rev_data),
        author_account_id => Dongry::Type->serialize ('text', $args{author_account_id}),
        created => $time,

        owner_status => $data->{owner_status},
        user_status => $data->{user_status},
      }]);
    })->then (sub {
      return {object_id => $object_id,
              object_revision_id => $data->{object_revision_id},
              upload_token => $data->{upload_token}};
    });
  });
} # create_object

sub group_object ($$$$) {
  my ($class, $app, $path, $opts) = @_;
  my $db = $opts->{db};

  if (@$path >= 4 and $path->[3] =~ /\A[0-9]+\z/) {
    # /g/{group_id}/o/{object_id}
    return $db->select ('object', {
      group_id => Dongry::Type->serialize ('text', $path->[1]),
      object_id => Dongry::Type->serialize ('text', $path->[3]),
    }, fields => ['object_id', 'data', 'owner_status', 'user_status'])->then (sub {
      my $object = $_[0]->first;
      return $app->throw_error (404, reason_phrase => 'Object not found')
          unless defined $object;
      $object->{data} = Dongry::Type->parse ('json', $object->{data});

      if (@$path == 5 and $path->[4] eq '') {
        # /g/{group_id}/o/{object_id}/
        if ($object->{user_status} != 1 or # open
            $object->{owner_status} != 1) { # open
          return $app->throw_error (410, reason_phrase => 'Object not found');
        }

        return Promise->resolve->then (sub {
          my $index_ids = [map { Dongry::Type->serialize ('text', $_) }
                           keys %{$object->{data}->{index_ids} || {}}];
          if (@$index_ids) {
            return $db->select ('index', {
              group_id => Dongry::Type->serialize ('text', $path->[1]),
              index_id => {-in => $index_ids},
              index_type => {-in => [1, 2, 3]}, # blog wiki todo
              user_status => 1, # open
              owner_status => 1, # open
            }, fields => ['index_id', 'title', 'options'], limit => 1)->then (sub {
              my $index = $_[0]->first // return undef;
              $index->{title} = Dongry::Type->parse ('text', $index->{title});
              $index->{options} = Dongry::Type->parse ('json', $index->{options});
              return $index;
            });
          }
          return undef;
        })->then (sub {
          return temma $app, 'group.index.index.html.tm', {
            account => $opts->{account},
            group => $opts->{group},
            group_member => $opts->{group_member},
            object => $object,
            index => $_[0],
          };
        });
      } elsif (@$path == 5 and $path->[4] eq 'embed') {
        # /g/{group_id}/o/{object_id}/embed
        if ($object->{user_status} != 1 or # open
            $object->{owner_status} != 1) { # open
          return $app->throw_error (410, reason_phrase => 'Object not found');
        }

        return temma $app, 'group.object.embed.html.tm', {
          account => $opts->{account},
          group => $opts->{group},
          group_member => $opts->{group_member},
          object => $object,
        };
      } elsif (@$path == 5 and $path->[4] eq 'edit.json') {
        # /g/{group_id}/o/{object_id}/edit.json
        $app->requires_request_method ({POST => 1});
        $app->requires_same_origin;

        my $changes = {};
        my $reactions = {};
        my $trackbacks = {};
        my $trackback_count = 0;
        for my $key (qw(title body body_source file_name)) {
          my $value = $app->text_param ($key);
          if (defined $value) {
            $object->{data}->{$key} = $value;
            $changes->{fields}->{$key} = 1;
          }
        }
        for my $key (qw(timestamp body_type body_source_type
                        user_status owner_status
                        todo_state file_size file_closed)) {
          my $value = $app->bare_param ($key);
          if (defined $value) {
            my $old = $object->{data}->{$key} || 0;
            if ($old != $value) {
              if ($key eq 'todo_state') {
                $reactions->{old}->{$key} = $old;
                $reactions->{new}->{$key} = $value;
              }
              $object->{data}->{$key} = 0+$value;
              $changes->{fields}->{$key} = 1;
            }
          }
        }
        for my $key (qw(mime_type)) {
          my $value = $app->text_param ($key);
          if (defined $value) {
            my $type = Web::MIME::Type->parse_web_mime_type ($value);
            if (defined $type) {
              $object->{data}->{$key} = $type->as_valid_mime_type;
              $changes->{fields}->{$key} = 1;
            }
          }
        }
        if ($object->{data}->{file_closed}) {
          delete $object->{data}->{upload_token};
        }
        # XXX owner_status only can be changed by group owners

        my $search_data;
        if ($changes->{fields}->{title} or
            $changes->{fields}->{body} or
            $changes->{fields}->{body_type}) {
          my $body = '';
          my @keyword;
          my @url;
          if ($object->{data}->{body_type} == 1) { # html
            my $doc = new Web::DOM::Document;
            $doc->manakai_is_html (1);
            $doc->manakai_set_url ($app->http->url->stringify);
            $doc->inner_html ($object->{data}->{body});
            $body = $doc->document_element->text_content;
            for ($doc->links->to_list) {
              my $name = $_->get_attribute ('data-wiki-name');
              if (defined $name) { # keyword link
                $body .= "\n" . $name;
                push @keyword, $name;
              } else {
                my $url = Web::URL->parse_string ($_->href);
                push @url, $url if defined $url;
              }
            }
            for ($doc->query_selector_all ('img[src], iframe[src]')->to_list) {
              my $url = Web::URL->parse_string ($_->src);
              push @url, $url if defined $url;
            }
            my $x = 0;
            my $y = 0;
            for ($doc->query_selector_all ('input[type=checkbox /* XXX i */]:not([hidden])')->to_list) {
              $x++;
              $y++ if $_->has_attribute ('checked');
            }
            $object->{data}->{all_checkbox_count} = $x;
            $object->{data}->{checked_checkbox_count} = $y;
          } elsif ($object->{data}->{body_type} == 2) { # plain text
            $body = $object->{data}->{body};
          }
          $search_data = join "\n",
              $body,
              $object->{data}->{title};
          {
            my $index_id = $opts->{group}->{data}->{default_wiki_index_id};
            if (defined $index_id) {
              for (@keyword) {
                unless ($object->{data}->{trackbacked}->{wiki_names}->{$index_id}->{$_}) {
                  $trackbacks->{wiki_names}->{$index_id}->{$_} = 1;
                  $object->{data}->{trackbacked}->{wiki_names}->{$index_id}->{$_} = 1;
                  last if 50 < $trackback_count++;
                }
              }
            }
          }
          my $self_url = Web::URL->parse_string ($app->http->url->stringify);
          for my $url (@url) {
            if ($url->get_origin->same_origin_as ($self_url->get_origin)) {
              my $path = [map { percent_decode_c $_ } split m{/}, $url->path, -1];
              if (@$path >= 5) {
                if ($path->[1] eq 'g' and
                    $path->[2] eq $opts->{group}->{group_id}) {
                  if ($path->[3] eq 'o' and
                      $path->[4] =~ /\A[0-9]+\z/ and
                      not $path->[4] eq $object->{object_id}) {
                    unless ($object->{data}->{trackbacked}->{objects}->{$path->[4]}) {
                      $trackbacks->{objects}->{$path->[4]} = 1;
                      $object->{data}->{trackbacked}->{objects}->{$path->[4]} = 1;
                      last if 50 < $trackback_count++;
                    }
                  } elsif ($path->[3] eq 'wiki' and
                           length $path->[4]) {
                    my $index_id = $opts->{group}->{data}->{default_wiki_index_id};
                    if (defined $index_id and
                        not $object->{data}->{trackbacked}->{wiki_names}->{$index_id}->{$path->[4]}) {
                      $trackbacks->{wiki_names}->{$index_id}->{$path->[4]} = 1;
                      $object->{data}->{trackbacked}->{wiki_names}->{$index_id}->{$path->[4]} = 1;
                      last if 50 < $trackback_count++;
                    }
                  } elsif (@$path >= 7 and
                           $path->[3] eq 'i' and
                           $path->[4] =~ /\A[0-9]+\z/ and
                           $path->[5] eq 'wiki' and
                           length $path->[6]) {
                    my $index_id = $path->[4];
                    unless ($object->{data}->{trackbacked}->{wiki_names}->{$index_id}->{$path->[4]}) {
                      $trackbacks->{wiki_names}->{$index_id}->{$path->[6]} = 1;
                      $object->{data}->{trackbacked}->{wiki_names}->{$index_id}->{$path->[4]} = 1;
                      last if 50 < $trackback_count++;
                    }
                  }
                }
              }
            }
          }
        } # title/body modified

        if ($app->bare_param ('edit_assigned_account_id')) {
          my $ids = $app->bare_param_list ('assigned_account_id');
          my $new = {map { $_ => 1 } @$ids};
          my $old = {%{$object->{data}->{assigned_account_ids} || {}}};
          my $changed;
          for (keys %$new) {
            unless (delete $old->{$_}) {
              $reactions->{new}->{assigned_account_ids}->{$_} = 1;
              $changed = 1;
            }
          }
          for (keys %$old) {
            $reactions->{old}->{assigned_account_ids}->{$_} = 1;
            $changed = 1;
          }
          if ($changed) {
            $object->{data}->{assigned_account_ids} = $new;
            $changes->{fields}->{assigned_account_ids} = 1;
          }
        }

        my $time = time;
        return Promise->resolve->then (sub {
          my $value = $app->bare_param ('parent_object_id');
          return unless defined $value;
          my $old = $object->{data}->{parent_object_id} || 0;
          return if $old == $value;
          if ($value) {
            return $db->select ('object', {
              group_id => Dongry::Type->serialize ('text', $path->[1]),
              object_id => $value,
            }, fields => ['thread_id'])->then (sub {
              my $v = $_[0]->first;
              return $app->throw_error
                  (404, reason_phrase => 'Bad |parent_object_id|')
                      unless defined $v;
              $object->{data}->{parent_object_id} = ''.$value;
              $changes->{fields}->{parent_object_id} = 1;
              if ($v->{thread_id} != $object->{data}->{thread_id}) {
                $object->{data}->{thread_id} = ''.$v->{thread_id};
                $changes->{fields}->{thread_id} = 1;
              }
              return $app->throw_error (409, reason_phrase => 'Bad |parent_object_id|')
                  if (my $x = $object->{data}->{thread_id}) == $object->{object_id} ||
                     (my $y = $object->{data}->{parent_object_id}) == $object->{object_id};
            });
          } else {
            delete $object->{data}->{parent_object_id};
            $changes->{fields}->{parent_object_id} = 1;
            $changes->{fields}->{thread_id} = 1;
            $object->{data}->{thread_id} = ''.$object->{object_id};
          }
        })->then (sub {
          return unless $app->bare_param ('edit_index_id');
          ## Note that, even when |$changes->{fields}->{timestamp}| or
          ## |$changes->{fields}->{title}| is true, `index_object`'s
          ## `updated` is not updated...

          my $index_ids = $app->bare_param_list ('index_id');
          my $new = {map { $_ => 1 } @$index_ids};
          my $old = {%{$object->{data}->{index_ids} or {}}};
          my $changed;
          my @new_id;
          for (keys %$new) {
            unless (delete $old->{$_}) {
              $reactions->{new}->{index_ids}->{$_} = 1;
              $changed = 1;
              push @new_id, $_;
            }
          }
          for (keys %$old) {
            $reactions->{old}->{index_ids}->{$_} = 1;
            $changed = 1;
          }

          return unless $changed or $changes->{fields}->{timestamp};

          $object->{data}->{index_ids} = $new;
          $changes->{fields}->{index_ids} = 1;

          my $index_id_to_type = {};
          return Promise->resolve->then (sub {
            return unless @new_id;
            return $db->select ('index', {
              group_id => Dongry::Type->serialize ('text', $path->[1]),
              index_id => {-in => \@new_id},
              owner_status => 1, # open
              user_status => 1, # open
            }, fields => ['index_id', 'index_type'])->then (sub {
              $index_id_to_type = {map {
                $_->{index_id} => $_->{index_type};
              } @{$_[0]->all}};
              for (@new_id) {
                return $app->throw_error (400, reason_phrase => 'Bad |index_id| ('.$_.')')
                    unless exists $index_id_to_type->{$_};
                if ($index_id_to_type->{$_} == 3) { # todo
                  unless (defined $object->{data}->{todo_state}) {
                    $object->{data}->{todo_state} = 1; # open
                    $changes->{fields}->{todo_state} = 1;
                  }
                }
              }
            });

    ## Before this line, don't write anything to the database.
    ## After this line, don't throw without completing the edit.

          })->then (sub {
            if (@$index_ids) {
              my $wiki_name_key = sha1_hex +Dongry::Type->serialize ('text', $object->{data}->{title});
              return Promise->all ([
                $db->insert ('index_object', [map {
                  +{
                    group_id => Dongry::Type->serialize ('text', $path->[1]),
                    index_id => $_,
                    object_id => Dongry::Type->serialize ('text', $path->[3]),
                    created => $time,
                    timestamp => $object->{data}->{timestamp},
                    wiki_name_key => $wiki_name_key,
                  };
                } @$index_ids], duplicate => {
                  timestamp => $db->bare_sql_fragment ('values(`timestamp`)'),
                  wiki_name_key => $db->bare_sql_fragment ('values(`wiki_name_key`)'),
                }),
                $db->delete ('index_object', {
                  group_id => Dongry::Type->serialize ('text', $path->[1]),
                  index_id => {-not_in => $index_ids},
                  object_id => Dongry::Type->serialize ('text', $path->[3]),
                }),
              ]);
            } else { # no $index_ids
              return $db->delete ('index_object', {
                group_id => Dongry::Type->serialize ('text', $path->[1]),
                object_id => Dongry::Type->serialize ('text', $path->[3]),
              });
            }
          });
        })->then (sub {
          delete $changes->{fields} unless keys %{$changes->{fields} or {}};
          return unless keys %$changes;

          my $sdata;
          my $rev_data = {changes => $changes};
          return $db->execute ('select uuid_short() as uuid')->then (sub {
            $object->{data}->{object_revision_id} = ''.$_[0]->first->{uuid};
            $sdata = Dongry::Type->serialize ('json', $object->{data});
            return $db->insert ('object_revision', [{
              group_id => Dongry::Type->serialize ('text', $path->[1]),
              object_id => Dongry::Type->serialize ('text', $path->[3]),
              data => $sdata,

              object_revision_id => $object->{data}->{object_revision_id},
              revision_data => Dongry::Type->serialize ('json', $rev_data),
              author_account_id => Dongry::Type->serialize ('text', $opts->{account}->{account_id}),
              created => $time,

              owner_status => $object->{data}->{owner_status},
              user_status => $object->{data}->{user_status},
            }]);
          })->then (sub {
            return unless keys %$reactions;
            $reactions->{object_revision_id} = $object->{data}->{object_revision_id};
            return create_object ($db, 
              group_id => $path->[1],
              author_account_id => $opts->{account}->{account_id},
              body_type => 3, # data
              body_data => $reactions,
              parent_object_id => $path->[3],
              thread_id => $object->{data}->{thread_id},
            );
          })->then (sub {
            return unless keys %{$trackbacks->{objects} or {}};
            ## If there is no trackbacked object, no trackback object
            ## is created for it.
            return $db->select ('object', {
              group_id => Dongry::Type->serialize ('text', $path->[1]),
              object_id => {-in => [map {
                Dongry::Type->serialize ('text', $_);
              } keys %{$trackbacks->{objects}}]},
            }, fields => ['object_id', 'thread_id'])->then (sub {
              my $parents = $_[0]->all->to_a;
              return promised_map {
                return create_object ($db,
                  group_id => $path->[1],
                  author_account_id => $opts->{account}->{account_id},
                  body_type => 3, # data
                  body_data => {
                    trackback => {
                      object_id => ''.$object->{object_id},
                      title => $object->{data}->{title},
                      search_data => (defined $search_data ? (substr $search_data, 0, 300) : undef),
                    },
                  },
                  parent_object_id => $_[0]->{object_id},
                  thread_id => $_[0]->{thread_id},
                );
              } $parents;
            });
          })->then (sub {
            return unless keys %{$trackbacks->{wiki_names} or {}};
            my $group_id = Dongry::Type->serialize ('text', $path->[1]);
            my @x;
            return $db->select ('index', {
              group_id => $group_id,
              index_id => {-in => [map {
                Dongry::Type->serialize ('text', $_);
              } keys %{$trackbacks->{wiki_names}}]},
            }, fields => ['index_id'])->then (sub {
              my $indexes = $_[0]->all->to_a;
              return promised_map {
                my $index_id = Dongry::Type->serialize ('text', $_[0]->{index_id});
                return promised_map {
                  my $wiki_name = $_[0];
                  return create_object ($db,
                    group_id => $path->[1],
                    author_account_id => $opts->{account}->{account_id},
                    body_type => 3, # data
                    body_data => {
                      trackback => {
                        object_id => ''.$object->{object_id},
                        title => $object->{data}->{title},
                        search_data => (defined $search_data ? (substr $search_data, 0, 300) : undef),
                      },
                    },
                  )->then (sub {
                    push @x, {
                      group_id => $group_id,
                      index_id => $index_id,
                      wiki_name_key => sha1_hex (Dongry::Type->serialize ('text', $wiki_name)),
                      object_id => $_[0]->{object_id},
                      created => $time,
                      timestamp => $time,
                    };
                  });
                } [keys %{$trackbacks->{wiki_names}->{$index_id}}];
              } $indexes;
            })->then (sub {
              return unless @x;
              return $db->insert ('wiki_trackback_object', \@x);
            });
          })->then (sub {
            my $update = {
              title => Dongry::Type->serialize ('text', $object->{data}->{title} // ''),
              data => $sdata,
              (defined $search_data
                ? (search_data => Dongry::Type->serialize ('text', $search_data))
                : ()),
              timestamp => $object->{data}->{timestamp},
              updated => $time,
            };

            ## XXX for backcompat
            $object->{data}->{owner_status} //= ($changes->{fields}->{owner_status} = 1);
            $object->{data}->{user_status} //= ($changes->{fields}->{user_status} = 1);
            $object->{data}->{thread_id} //= ($changes->{fields}->{thread_id} = ''.$object->{object_id});

            for my $key (qw(owner_status user_status thread_id
                            parent_object_id)) {
              $update->{$key} = $object->{data}->{$key}
                  if $changes->{fields}->{$key};
            }
            return $db->update ('object', $update, where => {
              group_id => Dongry::Type->serialize ('text', $path->[1]),
              object_id => Dongry::Type->serialize ('text', $path->[3]),
            });
          })->then (sub {
            return $opts->{acall}->(['group', 'touch'], {
              context_key => $app->config->{accounts}->{context} . ':group',
              group_id => $path->[1],
            })->();
          })->then (sub {
            return unless keys %{$object->{data}->{index_ids} or {}};
            return $db->update ('index', {
              updated => $time,
            }, where => {
              group_id => Dongry::Type->serialize ('text', $path->[1]),
              index_id => {-in => [map {
                Dongry::Type->serialize ('text', $_);
              } keys %{$object->{data}->{index_ids} or {}}]},
            });
          });
        })->then (sub {
          my $ts = $app->bare_param ('source_timestamp');
          my $sha = $app->bare_param ('source_sha');
          return unless $ts or $sha;
          my $info = {};
          $info->{timestamp} = $ts if $ts;
          $info->{sha} = $sha if defined $sha;
          return $db->update ('imported', {
            sync_info => Dongry::Type->serialize ('json', $info),
            updated => $time,
          }, where => {
            group_id => Dongry::Type->serialize ('text', $path->[1]),
            type => 2, # object
            dest_id => Dongry::Type->serialize ('text', $path->[3]),
          });
        })->then (sub {
          return json $app, {
            object_revision_id => ''.$object->{data}->{object_revision_id},
          } if keys %{$changes->{fields}};
          return json $app, {};
        });
      } elsif (@$path == 5 and
               ($path->[4] eq 'file' or $path->[4] eq 'image')) {
        # /g/{group_id}/o/{object_id}/file
        # /g/{group_id}/o/{object_id}/image
        if ($object->{data}->{body_type} != 4) { # file
          return $app->throw_error (404, reason_phrase => 'Not a file');
        }

        my $aws4 = $app->config->{storage}->{aws4};
        my $bucket = $app->config->{storage}->{bucket};
        my $url = Web::URL->parse_string ($app->config->{storage}->{url});
        my $client = Web::Transport::ConnectionClient->new_from_url ($url);
        # XXX body streaming
        return $client->request (
          method => 'GET',
          path => [$bucket, $path->[3]],
          aws4 => $aws4,
        )->then (sub {
          if ($_[0]->status == 200) {
            my $mime = $object->{data}->{mime_type} // 'application/octet-stream';
            if ($path->[4] eq 'image' and not $mime =~ m{^image/}) {
              return $app->throw_error (404, reason_phrase => 'Not an image');
            }
            $app->http->set_response_header ('content-type', $mime);
            unless ($path->[4] eq 'image') {
              $app->http->set_response_disposition
                  (disposition => 'attachment',
                   filename => $object->{data}->{file_name} // '');
            }
            $app->http->set_response_header
                ('content-security-policy', 'sandbox');
            $app->http->set_response_header
                ('x-content-type-options', 'nosniff');
            $app->http->set_response_last_modified
                ($object->{data}->{timestamp} || 0);
            $app->http->send_response_body_as_ref (\($_[0]->body_bytes));
            $app->http->close_response_body;
          } elsif ($_[0]->status == 404) {
            return $app->throw_error (404, reason_phrase => 'No file content');
          } else {
            die $_[0];
          }
        });
      } elsif (@$path == 5 and $path->[4] eq 'upload.json') {
        # /g/{group_id}/o/{object_id}/upload.json
        $app->requires_request_method ({POST => 1});
        $app->requires_same_origin;

        my $token = $app->bare_param ('token') // '';
        unless (defined $object->{data}->{upload_token} and
                $object->{data}->{upload_token} eq $token) {
          return $app->throw_error (403, reason_phrase => 'Bad |token|');
        }

        my $aws4 = $app->config->{storage}->{aws4};
        my $bucket = $app->config->{storage}->{bucket};
        my $url = Web::URL->parse_string ($app->config->{storage}->{url});
        my $client = Web::Transport::ConnectionClient->new_from_url ($url);

        my $file = $path->[3];
        return $client->request (
          method => 'HEAD',
          path => [$bucket],
          aws4 => $aws4,
        )->then (sub {
          my $res = $_[0];
          if ($res->status == 404) {
            ## <Error><Code>NoSuchBucket</Code><Message>The specified bucket does not exist</Message><Key></Key><BucketName></BucketName><Resource>{path}</Resource><RequestId>...</RequestId><HostId>...</HostId></Error>
            return $client->request (
              method => 'PUT',
              path => [$bucket],
              aws4 => $aws4,
            )->then (sub {
              die $_[0] unless $_[0]->status == 200;
            });
          }
          die $_[0] unless $_[0]->status == 200;
        })->then (sub {
          return $client->request (
            method => 'PUT',
            path => [$bucket, $file],
            aws4 => $aws4,

            # XXX streaming request body reading
            body => ${$app->http->request_body_as_ref},
          );
        })->then (sub {
          die $_[0] unless $_[0]->status == 200;
          return json $app, {};
        });
      } else {
        return $app->throw_error (404);
      }
    });
  }

  # XXX revisions
  ## XXX if revision's *_status is changed, save log

  if (@$path >= 4 and $path->[3] eq 'get.json') {
    # /g/{group_id}/o/get.json
    my $next_ref = {};
    my $rev_id;
    return Promise->resolve->then (sub {
      my $index_id;
      my $table;
      my %cond;
      my $ref = $app->bare_param ('ref');
      my $timestamp;
      my $offset;
      my $limit = $app->bare_param ('limit') || 20;
      if (defined $ref) {
        ($timestamp, $offset) = split /,/, $ref, 2;
        $next_ref->{$timestamp} = $offset || 0;
        return $app->throw_error (400, reason_phrase => 'Bad offset')
            if $offset > 1000;
        $cond{timestamp} = {'<=', $timestamp} if defined $timestamp;
      }
      return $app->throw_error (400, reason_phrase => 'Bad limit')
          if $limit > 100;
      my $thread_id = $app->bare_param ('thread_id');
      if (defined $thread_id) {
        return {thread_id => $thread_id,
                object_id => {'!=' => $thread_id},
                (defined $cond{timestamp} ? (timestamp => $cond{timestamp}) : ()),
                order => ['timestamp', 'desc', 'created', 'desc'],
                offset => $offset,
                limit => $limit};
      } else {
        my $parent_object_id = $app->bare_param ('parent_object_id');
        if (defined $parent_object_id) {
          return {parent_object_id => $parent_object_id,
                  object_id => {'!=' => $parent_object_id},
                  (defined $cond{timestamp} ? (timestamp => $cond{timestamp}) : ()),
                  order => ['timestamp', 'desc', 'created', 'desc'],
                  offset => $offset,
                  limit => $limit};
        } else {
          $index_id = $app->bare_param ('index_id');
          if (defined $index_id) {
            my $pwn = $app->text_param ('parent_wiki_name');
            if (defined $pwn) {
              $table = 'wiki_trackback_object';
              $cond{index_id} = $index_id;
              $cond{wiki_name_key} = sha1_hex +Dongry::Type->serialize ('text', $pwn);
            } else {
              $table = 'index_object';
              $cond{index_id} = $index_id;
              my $wiki_name = $app->text_param ('wiki_name');
              $cond{wiki_name_key} = sha1_hex +Dongry::Type->serialize ('text', $wiki_name)
                  if defined $wiki_name;
            }
          }
        }
      }
      if (defined $table) {
        return $db->select ($table, {
          group_id => Dongry::Type->serialize ('text', $path->[1]),
          %cond,
        },
          fields => ['object_id', 'timestamp'],
          order => ['timestamp', 'desc', 'created', 'desc'],
          offset => $offset, limit => $limit,
        )->then (sub {
          return {object_id => {-in => [map {
            $next_ref->{$_->{timestamp}}++;
            $next_ref->{_} = $_->{timestamp};
            $_->{object_id};
          } @{$_[0]->all}]}};
        });
      } else {
        my $list = $app->bare_param_list ('object_id');
        $rev_id = $app->bare_param ('object_revision_id') if @$list == 1;
        return {object_id => {-in => $list}};
      }
    })->then (sub {
      my $search = $_[0];
      my $order = delete $search->{order}; # or undef
      my $offset = delete $search->{offset}; # or undef
      my $limit = delete $search->{limit}; # or undef
      return [] unless keys %$search;
      return [] if defined $search->{object_id} and
                   defined $search->{object_id}->{-in} and
                   not @{$search->{object_id}->{-in}};
      return $db->select ('object', {
        group_id => Dongry::Type->serialize ('text', $path->[1]),
        %$search,

        # XXX
        owner_status => 1,
        user_status => 1,
      }, fields => ['object_id', 'title', 'timestamp', 'created', 'updated',
                    ($app->bare_param ('with_data') ? 'data' : ())],
        order => $order, # or undef
        offset => $offset, # or undef
        limit => $limit, # or undef
      )->then (sub {
        my $objects = $_[0]->all;
        if (defined $rev_id and @$objects == 1) {
          return $db->select ('object_revision', {
            group_id => Dongry::Type->serialize ('text', $path->[1]),
            object_id => $objects->[0]->{object_id},
            object_revision_id => $rev_id,
          }, fields => ['data', 'revision_data', 'author_account_id',
                        'created', 'user_status', 'owner_status'])->then (sub {
            my $r = $_[0]->first;
            return $app->throw_error (404, reason_phrase => 'Revision not found')
                unless defined $r;
            $objects->[0]->{updated} = $r->{created};
            $objects->[0]->{revision_author_account_id} = ''.$r->{author_account_id};
            if ($r->{user_status} == 1 and $r->{owner_status} == 1) { # open
              $objects->[0]->{data} = $r->{data};
              $objects->[0]->{revision_data}
                  = Dongry::Type->parse ('json', $r->{revision_data});
            } else {
              delete $objects->[0]->{data};
              delete $objects->[0]->{title};
            }
            return $objects;
          });
        } else {
          if (defined $order) {
            for (@$objects) {
              $next_ref->{$_->{timestamp}}++;
              $next_ref->{_} = $_->{timestamp};
            }
          }
          return $objects;
        }
      });
    })->then (sub {
      my $objects = $_[0];
      return json $app, {
        objects => {map {
          my $data;
          my $title;
          if (defined $_->{data}) {
            $data = Dongry::Type->parse ('json', $_->{data});
            $title = $data->{title} // '';
          } else {
            $title = Dongry::Type->parse ('text', $_->{title});
          }
          ($_->{object_id} => {
            group_id => $path->[1],
            object_id => ''.$_->{object_id},
            title => $title,
            created => $_->{created},
            updated => $_->{updated},
            timestamp => $_->{timestamp},
            (defined $_->{data} ? (data => $data) : ()),
            (defined $_->{revision_data} ?
                 (revision_data => $_->{revision_data},
                  revision_author_account_id => $_->{revision_author_account_id}) : ()),
          });
        } @$objects},
        next_ref => (defined $next_ref->{_} ? $next_ref->{_} . ',' . $next_ref->{$next_ref->{_}} : undef),
      };
    });
  } elsif (@$path >= 4 and $path->[3] eq 'search.json') {
    # /g/{group_id}/o/search.json
    my $q = $app->text_param ('q');
    my @have;
    my @not_have;
    if (defined $q) {
      for (grep { length } split /\s+/, $q) {
        if (s/^-(?=.)//s) {
          push @not_have, $_;
        } else {
          push @have, $_;
        }
      }
    }

    my $ref = $app->bare_param ('ref');
    my $timestamp;
    my $offset;
    my $limit = $app->bare_param ('limit') || 50;
    if (defined $ref) {
      ($timestamp, $offset) = split /,/, $ref, 2;
      return $app->throw_error (400, reason_phrase => 'Bad offset')
          if $offset > 1000;
    }
    return $app->throw_error (400, reason_phrase => 'Bad limit')
        if $limit > 100;

    my ($sqlx0, $sql0) = where [q{
      select `object_id`, `updated`, `title`, `timestamp`,
        substring(`search_data`, greatest(locate(:s1, `search_data`) - 300, 0) + 1, 600)
        as `snippet`
    }, 
      s1 => Dongry::Type->serialize ('text', $have[0] // ''),
    ];
    my ($sqlx, $sql) = where [q{
      from `object`
      where @@SEARCHDATA@@ and
            group_id = :group_id and
            user_status = 1 and owner_status = 1 and
            :updated:optsub
      order by `updated` desc limit :offset,:limit
    }, 
      group_id => Dongry::Type->serialize ('text', $path->[1]),
      updated => (defined $timestamp ? {updated => {'<=', $timestamp}} : {}),
      offset => $offset || 0,
      limit => $limit,
    ];

    my @expr;
    my @value;
    for (@have) {
      my ($x, $y) = where {search_data => {-infix => $_}};
      push @expr, $x;
      push @value, map { Dongry::Type->serialize ('text', $_) } @$y;
    }
    for (@not_have) {
      my ($x, $y) = where {search_data => {-infix => $_}};
      push @expr, 'not (' . $x . ')';
      push @value, map { Dongry::Type->serialize ('text', $_) } @$y;
    }

    $sqlx =~ s{\@\@SEARCHDATA\@\@}{
      if (@expr) {
        '(' . (join ' and ', @expr) . ')';
      } else {
        '(1 = 1)';
      }
    }e;
    $sqlx = $sqlx0 . $sqlx;
    unshift @$sql, @$sql0, @value;

    return $db->execute ($sqlx, $sql)->then (sub {
      my $items = $_[0]->all;
      return json $app, {
        next_ref => (@$items ? $items->[-1]->{updated} . ',1' : $ref // (time . ',' . 0)),
        objects => [map {
          {
            object_id => ''.$_->{object_id},
            title => Dongry::Type->parse ('text', $_->{title}),
            snippet => Dongry::Type->parse ('text', $_->{snippet}),
            updated => $_->{updated},
            timestamp => $_->{timestamp},
          };
        } @$items],
      };
    });
  } # /g/{}/o/search.json

  if (@$path == 4 and $path->[3] eq 'create.json') {
    # /g/{group_id}/o/create.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;

    my ($source_site_url, $source_page_url) = source_urls $app;

    return create_object ($db,
      group_id => $path->[1],
      author_account_id => $opts->{account}->{account_id},
      ($app->bare_param ('is_file') ? (
        body_type => 4, # file
      ) : ())
    )->then (sub {
      my $result = $_[0];
      return Promise->resolve->then (sub {
        return unless defined $source_page_url;
        my $page = Dongry::Type->serialize ('text', $source_page_url->stringify);
        my $site = Dongry::Type->serialize ('text', $source_site_url->stringify);
        my $time = time;
        return $db->insert ('imported', [{
          group_id => Dongry::Type->serialize ('text', $path->[1]),
          source_page_sha => sha1_hex ($page),
          source_page => $page,
          source_site_sha => sha1_hex ($site),
          source_site => $site,
          created => $time,
          updated => $time,
          type => 2, # object
          dest_id => $result->{object_id},
          sync_info => Dongry::Type->serialize ('json', {}),
        }], duplicate => {
          source_site => $db->bare_sql_fragment ('values(`source_site`)'),
          source_site_sha => $db->bare_sql_fragment ('values(`source_site_sha`)'),
          updated => $db->bare_sql_fragment ('values(`updated`)'),
          type => $db->bare_sql_fragment ('values(`type`)'),
          dest_id => $db->bare_sql_fragment ('values(`dest_id`)'),
          sync_info => $db->bare_sql_fragment ('values(`sync_info`)'),
        });
      })->then (sub {
        return json $app, {
          group_id => $path->[1],
          object_id => $result->{object_id},
          object_revision_id => $result->{object_revision_id},
          upload_token => $result->{upload_token},
        };
      });
    });
  }

  return $app->throw_error (404);
} # group_object

sub wiki ($$$$$) {
  my ($class, $app, $opts, $index, $wiki_name) = @_;
  return $app->throw_error (404) unless defined $index;

  # /g/{group_id}/wiki/{wiki_name}
  # /g/{group_id}/i/{index_id}/wiki/{wiki_name}

  if (@{$app->path_segments} == 6 and
      defined $opts->{group}->{data}->{default_wiki_index_id} and
      $index->{index_id} == $opts->{group}->{data}->{default_wiki_index_id}) {
    return $app->throw_redirect ('/g/'.(Web::URL::Encoding::percent_encode_c $opts->{group}->{group_id}).'/wiki/'.(Web::URL::Encoding::percent_encode_c $wiki_name));
  }

  return temma $app, 'group.index.index.html.tm', {
    account => $opts->{account},
    group => $opts->{group},
    group_member => $opts->{group_member},
    index => $index,
    wiki_name => $wiki_name,
  };

  #return $app->throw_error (404);
} # wiki

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
