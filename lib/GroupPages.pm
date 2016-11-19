package GroupPages;
use strict;
use warnings;
use Time::HiRes qw(time);
use Dongry::Type;
use Dongry::Type::JSONPS;

use Results;

sub main ($$$$$) {
  my ($class, $app, $path, $config, $db) = @_;

  if (@$path >= 2 and $path->[1] =~ /\A[0-9]+\z/) {
    # /g/{group_id}
    return $db->select ('group', {
      group_id => Dongry::Type->serialize ('text', $path->[1]),
    }, fields => ['group_id', 'title'])->then (sub {
      my $group = $_[0]->first;
      return $app->throw_error (404, reason_phrase => 'Group not found')
          unless defined $group;
      # XXX group_member
      $group->{title} = Dongry::Type->parse ('text', $group->{title});
      return $class->group ($app, $path, {
        config => $config, db => $db, group => $group,
      });
    });
  }

  if (@$path == 2 and $path->[1] eq 'create.json') {
    # /g/create.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;
    # XXX account
    my $title = $app->text_param ('title') // '';
    return $app->throw_error (400, reason_phrase => 'Bad |title|')
        unless length $title;
    my $time = time;
    return $db->execute ('select uuid_short() as uuid')->then (sub {
      my $gid = $_[0]->first->{uuid};
      return $db->insert ('group', [{
        group_id => $gid,
        title => Dongry::Type->serialize ('text', $title),
        created => $time,
        updated => $time,
      }])->then (sub {
        # XXX group_member
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
    return temma $app, 'group.index.html.tm', {group => $opts->{group}};
  }

  if (@$path >= 4 and $path->[2] eq 'i' and $path->[3] =~ /\A[0-9]+\z/) {
    # /g/{group_id}/i/{index_id}
    return $db->select ('index', {
      group_id => Dongry::Type->serialize ('text', $path->[1]),
      index_id => Dongry::Type->serialize ('text', $path->[3]),
    }, fields => ['index_id', 'title'])->then (sub {
      my $index = $_[0]->first;
      return $app->throw_error (404, reason_phrase => 'Index not found')
          unless defined $index;
      $index->{title} = Dongry::Type->parse ('text', $index->{title});

      if (@$path == 5 and $path->[4] eq '') {
        # /g/{group_id}/i/{index_id}/
        return temma $app, 'group.index.index.html.tm', {
          group => $opts->{group},
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
      }])->then (sub {
        return json $app, {
          index_id => ''.$index_id,
        };
      });
    });
  }

  if (@$path >= 4 and $path->[2] eq 'o' and $path->[3] =~ /\A[0-9]+\z/) {
    # /g/{group_id}/o/{object_id}
    return $db->select ('object', {
      group_id => Dongry::Type->serialize ('text', $path->[1]),
      object_id => Dongry::Type->serialize ('text', $path->[3]),
    }, fields => ['object_id', 'title', 'data'])->then (sub {
      my $object = $_[0]->first;
      return $app->throw_error (404, reason_phrase => 'Object not found')
          unless defined $object;
      $object->{title} = Dongry::Type->parse ('text', $object->{title});
      $object->{data} = Dongry::Type->parse ('json', $object->{data});
      if (@$path == 4) {
        # /g/{group_id}/o/{object_id}
        return temma $app, 'group.object.html.tm', {
          group => $opts->{group},
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
      return $db->select ('object', {
        group_id => Dongry::Type->serialize ('text', $path->[1]),
        object_id => {-in => $object_ids},
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
      }])->then (sub {
        return json $app, {
          object_id => ''.$object_id,
        };
      });
    });
  }

  return $app->throw_error (404);
} # group

# XXX *_status columns

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
