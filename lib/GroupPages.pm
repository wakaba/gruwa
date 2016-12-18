package GroupPages;
use strict;
use warnings;
use Time::HiRes qw(time);
use Dongry::Type;
use Dongry::Type::JSONPS;
use Dongry::SQL qw(where);
use Web::DOM::Document;

use Results;

sub main ($$$$$) {
  my ($class, $app, $path, $db, $account_data) = @_;

  if (@$path >= 2 and $path->[1] =~ /\A[0-9]+\z/) {
    # /g/{group_id}
    return $db->select ('group', {
      group_id => Dongry::Type->serialize ('text', $path->[1]),

      # XXX
      admin_status => 1,
      owner_status => 1,
    }, fields => ['group_id', 'title', 'created', 'updated', 'options'])->then (sub {
      my $group = $_[0]->first;
      return $app->throw_error (404, reason_phrase => 'Group not found')
          unless defined $group;
      $group->{title} = Dongry::Type->parse ('text', $group->{title});
      $group->{options} = Dongry::Type->parse ('json', $group->{options});

      if (@$path == 3 and $path->[2] eq 'members.json') {
        return $class->group_members_json ($app, $path, $db, $group, $account_data);
      } else {
        return $db->select ('group_member', {
          group_id => Dongry::Type->serialize ('text', $path->[1]),
          account_id => Dongry::Type->serialize ('text', $account_data->{account_id}),
          member_type => {-in => [
            1, # member
            2, # owner
          ]},
          user_status => 1, # open
          owner_status => 1, # open
        }, fields => ['member_type', 'default_index_id'])->then (sub {
          my $membership = $_[0]->first;
          return $app->throw_error (403, reason_phrase => 'Not a group member')
              unless defined $membership;
          return $class->group ($app, $path, {
            account => $account_data,
            db => $db, group => $group, group_member => $membership,
          });
        });
      }
    });
  }

  if (@$path == 2 and $path->[1] eq 'create.json') {
    # /g/create.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;
    my $title = $app->text_param ('title') // '';
    return $app->throw_error (400, reason_phrase => 'Bad |title|')
        unless length $title;
    my $time = time;
    return $db->execute ('select uuid_short() as uuid')->then (sub {
      my $gid = $_[0]->first->{uuid};
      return Promise->all ([
        $db->insert ('group', [{
          group_id => $gid,
          title => Dongry::Type->serialize ('text', $title),
          created => $time,
          updated => $time,
          admin_status => 1, # open
          owner_status => 1, # open
          options => '{"theme":"green"}',
        }]),
        $db->insert ('group_member', [{
          group_id => $gid,
          account_id => Dongry::Type->serialize ('text', $account_data->{account_id}),
          member_type => 2, # owner
          user_status => 1, # open
          owner_status => 1, # open
          desc => '',
          created => $time,
          updated => $time,
        }]),
      ])->then (sub {
        # XXX group log
        #     ipaddr
        return json $app, {
          group_id => ''.$gid,
        };
      });
    });
  } # /g/create.json

  return $app->send_error (404);
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
      title => $g->{title},
      created => $g->{created},
      updated => $g->{updated},
      theme => $g->{options}->{theme},
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
    my %update = (updated => time);
    my $title = $app->text_param ('title') // '';
    $update{title} = Dongry::Type->serialize ('text', $title)
        if length $title;
    my $theme = $app->text_param ('theme') // '';
    if (length $theme) {
      my $options = $opts->{group}->{options};
      $options->{theme} = $theme;
      $update{options} = Dongry::Type->serialize ('json', $options);
      # XXX need transaction for editing options :-<
    }
    return Promise->resolve->then (sub {
      return unless 1 < keys %update;
      return $db->update ('group', \%update, where => {
        group_id => Dongry::Type->serialize ('text', $path->[1]),
      });
      # XXX logging
    })->then (sub {
      return json $app, {};
    });
  }

  return $app->throw_error (404);
} # group

sub group_members_json ($) {
  my ($class, $app, $path, $db, $group, $account_data) = @_;
  # /g/{group_id}/members.json
  if ($app->http->request_method eq 'POST') {
    $app->requires_same_origin;
    my $account_id = $app->bare_param ('account_id') // '';
    return $app->throw_error (400, reason_phrase => 'Bad |account_id|')
        unless $account_id =~ /\A[0-9]+\z/;

    return $db->select ('group_member', {
      group_id => Dongry::Type->serialize ('text', $path->[1]),
      account_id => Dongry::Type->serialize ('text', $account_data->{account_id}),
    }, fields => ['member_type', 'member_type', 'user_status', 'owner_status'])->then (sub {
      my $membership = $_[0]->first;

      my $is_owner = (
        $membership->{member_type} == 2 and # owner
        $membership->{user_status} == 1 and # open
        $membership->{owner_status} == 1 # open
      );

      my %update;
      if ($account_id == $account_data->{account_id}) {
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

      if ($is_owner) {
        $update{desc} = $app->text_param ('desc');
        if (defined $update{desc}) {
          $update{desc} = Dongry::Type->serialize ('text', $update{desc});
        } else {
          delete $update{desc};
        }
      }

      return unless %update;

      return $db->insert ('group_member', [{
        group_id => Dongry::Type->serialize ('text', $path->[1]),
        account_id => Dongry::Type->serialize ('text', $account_id),
        created => time, updated => time,
        member_type => 0, user_status => 0, owner_status => 0, desc => '',
        default_index_id => 0,
        %update,
      }], duplicate => {
        map {
          $_ => $db->bare_sql_fragment ("values(`$_`)")
        } keys %update
      });
    })->then (sub {
      return json $app, {};
    });
  } else { # GET
    return $db->select ('group_member', {
      group_id => Dongry::Type->serialize ('text', $path->[1]),
    }, fields => ['account_id', 'member_type', 'owner_status', 'user_status', 'desc', 'default_index_id'])->then (sub {
      my $members = {map {
        $_->{account_id} => {
          account_id => ''.$_->{account_id},
          member_type => $_->{member_type},
          owner_status => $_->{owner_status},
          user_status => $_->{user_status},
          default_index_id => ($_->{default_index_id} ? ''.$_->{default_index_id} : undef),
          desc => Dongry::Type->parse ('text', $_->{desc}),
        };
      } @{$_[0]->all}};
      my $current = $members->{$account_data->{account_id}};
      if (defined $current and
          ($current->{member_type} == 2 or # owner
           $current->{member_type} == 1) and # open
          $current->{owner_status} == 1 and # open
          $current->{user_status} == 1) { # open
        return json $app, {members => $members};
      } else {
        return json $app, {members => {
          $account_data->{account_id} => {
            account_id => $account_data->{account_id},
            member_type => 0,
            owner_status => $current->{owner_status} || 0,
            user_status => $current->{user_status} || 0,
            default_index_id => undef,
            desc => '',
          },
        }};
      }
    });
  } # GET
} # group_members_json

sub group_index ($$$$) {
  my ($class, $app, $path, $opts) = @_;
  my $db = $opts->{db};

  if (@$path == 4 and $path->[3] eq 'list.json') {
    # /g/{}/i/list.json
    return $db->select ('index', {
      group_id => Dongry::Type->serialize ('text', $path->[1]),
      owner_status => 1,
      user_status => 1,
    }, fields => ['index_id', 'title', 'updated'])->then (sub {
      return json $app, {index_list => {map {
        $_->{index_id} => {
          group_id => $path->[1],
          index_id => ''.$_->{index_id},
          title => Dongry::Type->parse ('text', $_->{title}),
          updated => $_->{updated},
        };
      } @{$_[0]->all}}};
    });
  }

  if (@$path >= 4 and $path->[3] =~ /\A[0-9]+\z/) {
    # /g/{group_id}/i/{index_id}
    return $db->select ('index', {
      group_id => Dongry::Type->serialize ('text', $path->[1]),
      index_id => Dongry::Type->serialize ('text', $path->[3]),

      # XXX
      owner_status => 1,
      user_status => 1,
    }, fields => ['index_id', 'title', 'created', 'updated', 'options'])->then (sub {
      my $index = $_[0]->first;
      return $app->throw_error (404, reason_phrase => 'Index not found')
          unless defined $index;
      $index->{title} = Dongry::Type->parse ('text', $index->{title});
      $index->{options} = Dongry::Type->parse ('json', $index->{options});

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
          theme => $index->{options}->{theme},
        };
      } elsif (@$path == 5 and $path->[4] eq 'edit.json') {
        # /g/{group_id}/i/{index_id}/edit.json
        $app->requires_request_method ({POST => 1});
        $app->requires_same_origin;
        my %update = (updated => time);
        my $title = $app->text_param ('title') // '';
        $update{title} = Dongry::Type->serialize ('text', $title)
            if length $title;
        my $theme = $app->text_param ('theme') // '';
        if (length $theme) {
          my $options = $opts->{group}->{options};
          $options->{theme} = $theme;
          $update{options} = Dongry::Type->serialize ('json', $options);
          # XXX need transaction for editing options :-<
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
          push @p, $db->update ('group_member', {
            default_index_id => ($is_default ? Dongry::Type->serialize ('text', $path->[3]) : 0),
            updated => time,
          }, where => {
            group_id => Dongry::Type->serialize ('text', $path->[1]),
            account_id => Dongry::Type->serialize ('text', $opts->{account}->{account_id}),
          });
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
    my $time = time;
    return $db->execute ('select uuid_short() as uuid')->then (sub {
      my $index_id = $_[0]->first->{uuid};
      return $db->insert ('index', [{
        group_id => Dongry::Type->serialize ('text', $path->[1]),
        index_id => $index_id,
        title => Dongry::Type->serialize ('text', $title),
        created => $time,
        updated => $time,
        owner_status => 1, # open
        user_status => 1, # open
        options => '{"theme":"green"}',
      }])->then (sub {
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
        return temma $app, 'group.index.index.html.tm', {
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
        for my $key (qw(title body)) {
          my $value = $app->text_param ($key);
          if (defined $value) {
            $object->{data}->{$key} = $value;
            $changes->{fields}->{$key} = 1;
          }
        }
        for my $key (qw(timestamp body_type user_status owner_status)) {
          my $value = $app->bare_param ($key);
          if (defined $value) {
            $object->{data}->{$key} = 0+$value;
            $changes->{fields}->{$key} = 1;
          }
        }
        # XXX owner_status only can be changed by group owners

        # XXX tests
        if ($app->bare_param ('edit_tag')) {
          my @old_tags = sort { $a cmp $b } keys %{$object->{data}->{tags} or {}};
          $object->{data}->{tags} = {map { $_ => 1 } @{$app->text_param_list ('tag')}};
          my @new_tags = sort { $a cmp $b } keys %{$object->{data}->{tags} or {}};
          unless (@old_tags == @new_tags and
                  (join $;, @old_tags) eq (join $;, @new_tags)) { ## This check is not strict but good enough.
            $changes->{fields}->{tags} = 1;
          }
        }

        my $search_data;
        if ($changes->{fields}->{title} or
            $changes->{fields}->{body} or
            $changes->{fields}->{body_type} or
            $changes->{fields}->{tags}) {
          my $body;
          if ($object->{data}->{body_type} == 1) { # html
            my $doc = new Web::DOM::Document;
            $doc->manakai_is_html (1);
            $doc->inner_html ($object->{data}->{body});
            $body = $doc->document_element->text_content;
          } elsif ($object->{data}->{body_type} == 2) { # plain text
            $body = $object->{data}->{body};
          }
          $search_data = join "\n",
              keys %{$object->{data}->{tags}},
              $object->{data}->{title},
              $body;
        }

        my $time = time;
        return Promise->resolve->then (sub {
          return unless $app->bare_param ('edit_index_id');
          ## Note that, event when |$changes->{fields}->{timestamp}|
          ## is true, `index_object`'s `updated` is not updated...

          my $index_ids = $app->bare_param_list ('index_id');

          my @new_id;
          for (@$index_ids) {
            unless ($object->{data}->{index_ids}->{$_}) {
              push @new_id, $_;
            }
          }

          if (@$index_ids == keys %{$object->{data}->{index_ids}} and
              not @new_id) {
            # not changed
            unless ($changes->{fields}->{timestamp}) {
              return;
            }
          }

          $object->{data}->{index_ids} = {map { $_ => 1 } @$index_ids};
          $changes->{fields}->{index_ids} = 1;

          return Promise->resolve->then (sub {
            return unless @new_id;
            return $db->select ('index', {
              group_id => Dongry::Type->serialize ('text', $path->[1]),
              index_id => {-in => \@new_id},
              owner_status => 1, # open
              user_status => 1, # open
            }, fields => ['index_id'])->then (sub {
              my $has_index = {map { $_->{index_id} => 1 } @{$_[0]->all}};
              for (@new_id) {
                return $app->throw_error (400, reason_phrase => 'Bad |index_id| ('.$_.')')
                    unless $has_index->{$_};
              }
            });
          })->then (sub {
            if (@$index_ids) {
              return Promise->all ([
                $db->insert ('index_object', [map {
                  +{
                    group_id => Dongry::Type->serialize ('text', $path->[1]),
                    index_id => $_,
                    object_id => Dongry::Type->serialize ('text', $path->[3]),
                    created => $time,
                    timestamp => $object->{data}->{timestamp},
                  };
                } @$index_ids], duplicate => {
                  timestamp => $db->bare_sql_fragment ('values(`timestamp`)'),
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
            my $update = {
              title => Dongry::Type->serialize ('text', $object->{data}->{title}),
              data => $sdata,
              (defined $search_data
                ? (search_data => Dongry::Type->serialize ('text', $search_data))
                : ()),
              timestamp => $object->{data}->{timestamp},
              updated => $time,
            };
            $update->{owner_status} = $object->{data}->{owner_status}
                if $changes->{fields}->{owner_status};
            $update->{user_status} = $object->{data}->{user_status}
                if $changes->{fields}->{user_status};
            return $db->update ('object', $update, where => {
              group_id => Dongry::Type->serialize ('text', $path->[1]),
              object_id => Dongry::Type->serialize ('text', $path->[3]),
            });
          })->then (sub {
            return $db->update ('group', {
              updated => $time,
            }, where => {
              group_id => Dongry::Type->serialize ('text', $path->[1]),
            });
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
      my $index_id = $app->bare_param ('index_id');
      if (defined $index_id) {
        my $ref = $app->bare_param ('ref');
        my $timestamp;
        my $offset;
        my $limit = $app->bare_param ('limit') || 20;
        if (defined $ref) {
          ($timestamp, $offset) = split /,/, $ref, 2;
          $next_ref->{$timestamp} = $offset || 0;
          return $app->throw_error (400, reason_phrase => 'Bad offset')
              if $offset > 1000;
        }
        return $app->throw_error (400, reason_phrase => 'Bad limit')
            if $limit > 100;
        return $db->select ('index_object', {
          group_id => Dongry::Type->serialize ('text', $path->[1]),
          index_id => $index_id,
          (defined $timestamp ? (timestamp => {'<=', $timestamp}) : ()),
        },
          fields => ['object_id', 'timestamp'],
          order => ['timestamp', 'desc', 'created', 'desc'],
          offset => $offset, limit => $limit,
        )->then (sub {
          return [map {
            $next_ref->{$_->{timestamp}}++;
            $next_ref->{_} = $_->{timestamp};
            $_->{object_id};
          } @{$_[0]->all}];
        });
      #} elsif ($app->bare_param ('recent')) {
      #  return $db->select ('object', {
      #    group_id => Dongry::Type->serialize ('text', $path->[1]),
      #  }, fields => ['object_id'], order => ['updated', 'desc'], limit => 50)->then (sub {
      #    return [map { $_->{object_id} } @{$_[0]->all}];
      #  });
      } else {
        my $list = $app->bare_param_list ('object_id');
        $rev_id = $app->bare_param ('object_revision_id') if @$list == 1;
        return $list;
      }
    })->then (sub {
      my $object_ids = $_[0];
      return [] unless @$object_ids;
      return $db->select ('object', {
        group_id => Dongry::Type->serialize ('text', $path->[1]),
        object_id => {-in => $object_ids},

        # XXX
        owner_status => 1,
        user_status => 1,
      }, fields => ['object_id', 'title', 'timestamp', 'created', 'updated',
                    ($app->bare_param ('with_data') ? 'data' : ())],
      )->then (sub {
        my $objects = $_[0]->all;
        if (defined $rev_id and @$objects == 1) {
          return $db->select ('object_revision', {
            group_id => Dongry::Type->serialize ('text', $path->[1]),
            object_id => {-in => $object_ids},
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
            $title = $data->{title};
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
    my $time = time;
    return $db->execute ('select uuid_short() as uuid1,
                                 uuid_short() as uuid2')->then (sub {
      my $ids = $_[0]->first;
      my $object_id = $ids->{uuid1};
      my $data = {index_ids => {}, title => '', body => '', body_type => 2,
                  timestamp => $time,
                  object_revision_id => ''.$ids->{uuid2},
                  user_status => 1, # open
                  owner_status => 1}; # open
      my $rev_data = {changes => {action => 'new'}};
      ## This does not touch `group`.  It will be touched by
      ## o/{}/edit.json soon.

      my $sdata = Dongry::Type->serialize ('json', $data);
      return $db->insert ('object', [{
        group_id => Dongry::Type->serialize ('text', $path->[1]),
        object_id => $object_id,
        title => '',
        data => $sdata,
        search_data => '',
        created => $time,
        updated => $time,
        timestamp => $time,
        owner_status => $data->{owner_status},
        user_status => $data->{user_status},
      }])->then (sub {
        return $db->insert ('object_revision', [{
          group_id => Dongry::Type->serialize ('text', $path->[1]),
          object_id => $object_id,
          data => $sdata,

          object_revision_id => $data->{object_revision_id},
          revision_data => Dongry::Type->serialize ('json', $rev_data),
          author_account_id => Dongry::Type->serialize ('text', $opts->{account}->{account_id}),
          created => $time,

          owner_status => $data->{owner_status},
          user_status => $data->{user_status},
        }]);
      })->then (sub {
        return json $app, {
          group_id => $path->[1],
          object_id => ''.$object_id,
          object_revision_id => $data->{object_revision_id},
        };
      });
    });
  }

  return $app->throw_error (404);
} # group_object

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
