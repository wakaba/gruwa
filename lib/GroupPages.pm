package GroupPages;
use strict;
use warnings;
use Time::HiRes qw(time);
use Dongry::Type;
use Dongry::Type::JSONPS;

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
    }, fields => ['group_id', 'title', 'created', 'updated'])->then (sub {
      my $group = $_[0]->first;
      return $app->throw_error (404, reason_phrase => 'Group not found')
          unless defined $group;
      $group->{title} = Dongry::Type->parse ('text', $group->{title});

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
    };
  } elsif (@$path == 3 and $path->[2] eq 'edit.json') {
    # /g/{group_id}/edit.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;
    my %update = (updated => time);
    my $title = $app->text_param ('title') // '';
    $update{title} = Dongry::Type->serialize ('text', $title)
        if length $title;
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

  if (@$path == 4 and $path->[2] eq 'i' and $path->[3] eq 'list.json') {
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

  if (@$path >= 4 and $path->[2] eq 'i' and $path->[3] =~ /\A[0-9]+\z/) {
    # /g/{group_id}/i/{index_id}
    return $db->select ('index', {
      group_id => Dongry::Type->serialize ('text', $path->[1]),
      index_id => Dongry::Type->serialize ('text', $path->[3]),

      # XXX
      owner_status => 1,
      user_status => 1,
    }, fields => ['index_id', 'title', 'created', 'updated'])->then (sub {
      my $index = $_[0]->first;
      return $app->throw_error (404, reason_phrase => 'Index not found')
          unless defined $index;
      $index->{title} = Dongry::Type->parse ('text', $index->{title});

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
        };
      } elsif (@$path == 5 and $path->[4] eq 'edit.json') {
        # /g/{group_id}/i/{index_id}/edit.json
        $app->requires_request_method ({POST => 1});
        $app->requires_same_origin;
        my %update = (updated => time);
        my $title = $app->text_param ('title') // '';
        $update{title} = Dongry::Type->serialize ('text', $title)
            if length $title;
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

  if (@$path == 4 and $path->[2] eq 'i' and $path->[3] eq 'create.json') {
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

  # XXX tests
  if (@$path >= 4 and $path->[2] eq 'o' and $path->[3] =~ /\A[0-9]+\z/) {
    # /g/{group_id}/o/{object_id}
    return $db->select ('object', {
      group_id => Dongry::Type->serialize ('text', $path->[1]),
      object_id => Dongry::Type->serialize ('text', $path->[3]),

      # XXX
      owner_status => 1,
      user_status => 1,
    }, fields => ['object_id', 'title', 'data'])->then (sub {
      my $object = $_[0]->first;
      return $app->throw_error (404, reason_phrase => 'Object not found')
          unless defined $object;
      $object->{title} = Dongry::Type->parse ('text', $object->{title});
      $object->{data} = Dongry::Type->parse ('json', $object->{data});
      if (@$path == 4) {
        # /g/{group_id}/o/{object_id}
        return temma $app, 'group.object.html.tm', {
          account => $opts->{account},
          group => $opts->{group},
          group_member => $opts->{group_member},
          object => $object,
        };
      } elsif (@$path == 5 and $path->[4] eq 'edit.json') {
        # /g/{group_id}/o/{object_id}/edit.json
        my $index_ids = $app->bare_param_list ('index_id');
        my $time = time;
        return Promise->resolve->then (sub {
          return unless @$index_ids;
          return $db->select ('index', {
            group_id => Dongry::Type->serialize ('text', $path->[1]),
            index_id => {-in => $index_ids},
            owner_status => 1, # open
            user_status => 1, # open
          }, fields => ['index_id'])->then (sub {
            my $has_index = {map { $_->{index_id} => 1 } @{$_[0]->all}};
            for (@$index_ids) {
              return $app->throw_error (400, reason_phrase => 'Bad |index_id| ('.$_.')')
                  unless $has_index->{$_};
            }
          });
        })->then (sub {
          # XXX revision
          $object->{data}->{title} = $app->text_param ('title') // '';
          $object->{data}->{body} = $app->text_param ('body') // '';
          $object->{data}->{index_ids} = {map { $_ => 1 } @$index_ids};

          return unless @$index_ids;
          return Promise->all ([
            $db->insert ('index_object', [map {
              +{
                group_id => Dongry::Type->serialize ('text', $path->[1]),
                index_id => $_,
                object_id => Dongry::Type->serialize ('text', $path->[3]),
                created => $time,
               };
            } @$index_ids], duplicate => 'ignore'),
            $db->delete ('index_object', {
              group_id => Dongry::Type->serialize ('text', $path->[1]),
              index_id => {-not_in => $index_ids},
              object_id => Dongry::Type->serialize ('text', $path->[3]),
            }),
                                #XXX touch indexes
          ]);
        })->then (sub {
          return $db->update ('object', {
            title => Dongry::Type->serialize ('text', $object->{data}->{title}),
            data => Dongry::Type->serialize ('json', $object->{data}),
            updated => $time,
          }, where => {
            group_id => Dongry::Type->serialize ('text', $path->[1]),
            object_id => Dongry::Type->serialize ('text', $path->[3]),
          });
        })->then (sub {
          return json $app, {};
        });
      } else {
        return $app->throw_error (404);
      }
    });
  }

  # XXX tests
  if (@$path >= 4 and $path->[2] eq 'o' and $path->[3] eq 'get.json') {
    # /g/{group_id}/o/get.json
    return Promise->resolve->then (sub {
      # XXX paging
      # XXX status
      my $index_id = $app->bare_param ('index_id');
      if (defined $index_id) {
        return $db->select ('index_object', {
          group_id => Dongry::Type->serialize ('text', $path->[1]),
          index_id => $index_id,
        }, fields => ['object_id'])->then (sub {
          return [map { $_->{object_id} } @{$_[0]->all}];
        });
      } else {
        return $app->bare_param_list ('object_id');
      }
    })->then (sub {
      my $object_ids = $_[0];
      return [] unless @$object_ids;
# XXX with_*
      return $db->select ('object', {
        group_id => Dongry::Type->serialize ('text', $path->[1]),
        object_id => {-in => $object_ids},

        # XXX
        owner_status => 1,
        user_status => 1,
      }, fields => ['object_id', 'title', 'data', 'created', 'updated'])->then (sub {
        return $_[0]->all;
      });
    })->then (sub {
      my $objects = $_[0];
      # XXX sort
      return json $app, {objects => [map {
        +{
          object_id => ''.$_->{object_id},
          title => Dongry::Type->parse ('text', $_->{title}),
          data => Dongry::Type->parse ('json', $_->{data}),
          created => $_->{created},
          updated => $_->{updated},
        };
      } @$objects]};
    });
  }

  # XXX tests
  if (@$path == 4 and $path->[2] eq 'o' and $path->[3] eq 'create.json') {
    # /g/{group_id}/o/create.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;
    my $time = time;
    return $db->execute ('select uuid_short() as uuid')->then (sub {
      my $object_id = $_[0]->first->{uuid};
      return $db->insert ('object', [{
        group_id => Dongry::Type->serialize ('text', $path->[1]),
        object_id => $object_id,
        title => '',
        data => '{"index_ids":{},"title":"","body":""}',
        created => $time,
        updated => $time,
        owner_status => 1, # open
        user_status => 1, # open
      }])->then (sub {
        return json $app, {
          object_id => ''.$object_id,
        };
      });
    });
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
