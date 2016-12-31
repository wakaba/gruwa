use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->are_errors (
      ['POST', ['o', $current->o ('o1')->{object_id}, 'edit.json'], {}, account => 'a1', group => 'g1'],
      [
        {method => 'GET', status => 405},
        {origin => 'null', status => 400, name => 'null origin'},
        {group => 'g2', status => 404},
        {path => ['o', '524444343', 'edit.json'], status => 404},
        {account => '', status => 403},
        {account => undef, status => 403},
      ],
    );
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      is $object->{data}->{object_revision_id},
          $current->o ('o1')->{object_revision_id};
    } $current->c, name => 'object_revision_id ignored';
  });
} n => 2, name => 'zero edits';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      title => "\x{400} ",
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      isnt $object->{data}->{object_revision_id},
          $current->o ('o1')->{object_revision_id};
      is $object->{data}->{title}, "\x{400} ";
      is $object->{title}, "\x{400} ";
      is $object->{data}->{body}, '';
      is $object->{data}->{user_status}, 1;
      is $object->{data}->{owner_status}, 1;
      ok $object->{created};
      ok $object->{updated} > $object->{created};
    } $current->c, name => 'object_revision_id ignored';
    return $current->object ($current->o ('o1'), account => 'a1',
                             revision_id => $object->{data}->{object_revision_id});
  })->then (sub {
    my $object = $_[0];
    test {
      is $object->{data}->{title}, "\x{400} ";
      is $object->{title}, "\x{400} ";
      is $object->{data}->{body}, '';
      is $object->{data}->{user_status}, 1;
      is $object->{data}->{owner_status}, 1;
      ok $object->{created};
      ok $object->{updated} > $object->{created};
      is 0+keys %{$object->{revision_data}->{changes}}, 1;
      is 0+keys %{$object->{revision_data}->{changes}->{fields}}, 1;
      ok $object->{revision_data}->{changes}->{fields}->{title};
    } $current->c, name => 'object_revision_id ignored';
  });
} n => 18, name => 'title changed';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body => "\x{400} ",
      timestamp => 33436444,
      body_type => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      isnt $object->{data}->{object_revision_id},
          $current->o ('o1')->{object_revision_id};
      is $object->{data}->{body}, "\x{400} ";
      is $object->{title}, "";
      is $object->{data}->{title}, '';
      is $object->{data}->{user_status}, 1;
      is $object->{data}->{owner_status}, 1;
      ok $object->{created};
      ok $object->{updated} > $object->{created};
      is $object->{data}->{timestamp}, 33436444;
      is $object->{data}->{body_type}, 3;
    } $current->c, name => 'object_revision_id ignored';
    return $current->object ($current->o ('o1'), account => 'a1',
                             revision_id => $object->{data}->{object_revision_id});
  })->then (sub {
    my $object = $_[0];
    test {
      is $object->{data}->{body}, "\x{400} ";
      is $object->{title}, "";
      is $object->{data}->{title}, '';
      is $object->{data}->{user_status}, 1;
      is $object->{data}->{owner_status}, 1;
      ok $object->{created};
      ok $object->{updated} > $object->{created};
      is $object->{data}->{timestamp}, 33436444;
      is $object->{data}->{body_type}, 3;
      is 0+keys %{$object->{revision_data}->{changes}}, 1;
      is 0+keys %{$object->{revision_data}->{changes}->{fields}}, 3;
      ok $object->{revision_data}->{changes}->{fields}->{body};
      ok $object->{revision_data}->{changes}->{fields}->{timestamp};
      ok $object->{revision_data}->{changes}->{fields}->{body_type};
    } $current->c, name => 'object_revision_id ignored';
  });
} n => 24, name => 'body and timestamp changed';

Test {
  my $current = shift;
  my $rev1;
  my $rev2;
  my $rev3;
  my $rev4;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_index (i2 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_index (i3 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_index (i4 => {group => 'g2', account => 'a1'});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      edit_index_id => 1,
      index_id => [$current->o ('i1')->{index_id},
                   $current->o ('i2')->{index_id},
                   $current->o ('i3')->{index_id}],
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      isnt $object->{data}->{object_revision_id},
          $current->o ('o1')->{object_revision_id};
      is 0+keys %{$object->{data}->{index_ids}}, 3;
      ok $object->{data}->{index_ids}->{$current->o ('i1')->{index_id}};
      ok $object->{data}->{index_ids}->{$current->o ('i2')->{index_id}};
      ok $object->{data}->{index_ids}->{$current->o ('i3')->{index_id}};
    } $current->c, name => 'index_ids 0 -> 3';
    return $current->object ($current->o ('o1'), account => 'a1',
                             revision_id => $rev1 = $object->{data}->{object_revision_id});
  })->then (sub {
    my $object = $_[0];
    test {
      is 0+keys %{$object->{revision_data}->{changes}}, 1;
      is 0+keys %{$object->{revision_data}->{changes}->{fields}}, 1;
      ok $object->{revision_data}->{changes}->{fields}->{index_ids};
      is $object->{revision_author_account_id}, $current->o ('a1')->{account_id};
    } $current->c;
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      edit_index_id => 0,
      index_id => [$current->o ('i2')->{index_id},
                   $current->o ('i1')->{index_id},
                   $current->o ('i3')->{index_id}],
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      edit_index_id => 1,
      index_id => [$current->o ('i2')->{index_id},
                   $current->o ('i1')->{index_id},
                   $current->o ('i3')->{index_id}],
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      is $object->{data}->{object_revision_id}, $rev1;
      is 0+keys %{$object->{data}->{index_ids}}, 3;
      ok $object->{data}->{index_ids}->{$current->o ('i1')->{index_id}};
      ok $object->{data}->{index_ids}->{$current->o ('i2')->{index_id}};
      ok $object->{data}->{index_ids}->{$current->o ('i3')->{index_id}};
    } $current->c, name => 'index_ids not in fact changed';
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      edit_index_id => 1,
      index_id => [$current->o ('i2')->{index_id},
                   $current->o ('i3')->{index_id}],
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      isnt $rev2 = $object->{data}->{object_revision_id}, $rev1;
      is 0+keys %{$object->{data}->{index_ids}}, 2;
      ok $object->{data}->{index_ids}->{$current->o ('i2')->{index_id}};
      ok $object->{data}->{index_ids}->{$current->o ('i3')->{index_id}};
    } $current->c, name => 'index_ids 3 -> 2';
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      edit_index_id => 1,
      index_id => [$current->o ('i2')->{index_id},
                   $current->o ('i1')->{index_id}],
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      isnt $rev3 = $object->{data}->{object_revision_id}, $rev2;
      is 0+keys %{$object->{data}->{index_ids}}, 2;
      ok $object->{data}->{index_ids}->{$current->o ('i2')->{index_id}};
      ok $object->{data}->{index_ids}->{$current->o ('i1')->{index_id}};
    } $current->c, name => 'index_ids 2 -> 2 changed';
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      edit_index_id => 1,
      index_id => [],
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      isnt $rev4 = $object->{data}->{object_revision_id}, $rev3;
      is 0+keys %{$object->{data}->{index_ids}}, 0;
    } $current->c, name => 'index_ids 2 -> 0';
    return $current->are_errors (
      ['POST', ['o', $current->o ('o1')->{object_id}, 'edit.json'], {}, account => 'a1', group => 'g1'],
      [
        {
          params => {
            edit_index_id => 1,
            index_id => [$current->o ('i1')->{index_id}, 542444444],
          },
          status => 400,
          name => 'has bad index_id',
        },
        {
          params => {
            edit_index_id => 1,
            index_id => [$current->o ('i4')->{index_id}],
          },
          status => 400,
          name => 'has bad index_id',
        },
      ],
    );
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      is $object->{data}->{object_revision_id}, $rev4;
    } $current->c;
  });
} n => 26, name => 'index_id changes';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 1, # html
      body => q{
      },
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      is $object->{data}->{all_checkbox_count}, 0;
      is $object->{data}->{checked_checkbox_count}, 0;
    } $current->c;
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 1, # html
      body => q{
        <input type="checkbox">
        <p><input type="checkbox" checked="">
        <template><input type="checkbox" checked=""></template>
      },
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      is $object->{data}->{all_checkbox_count}, 2;
      is $object->{data}->{checked_checkbox_count}, 1;
    } $current->c;
  });
} n => 4, name => 'checkbox count';

RUN;

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
