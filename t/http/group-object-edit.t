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
      is $object->{data}->{title}, undef;
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
      is $object->{data}->{title}, undef;
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
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body => "\x{400} ",
      body_source => "abc def",
      body_source_type => 42523,
      body_type => 1,
      parent_section_id => "\x{553}",
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      isnt $object->{data}->{object_revision_id},
          $current->o ('o1')->{object_revision_id};
      is $object->{data}->{body}, "\x{400} ";
      is $object->{data}->{body_source}, "abc def";
      is $object->{data}->{body_source_type}, 42523;
      is $object->{data}->{body_type}, 1;
      is $object->{data}->{parent_section_id}, "\x{553}";
    } $current->c;
  });
} n => 6, name => 'body fields';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_data => '{"hatena_star": [["ab"],["cd"]]}',
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      isnt $object->{data}->{object_revision_id},
          $current->o ('o1')->{object_revision_id};
      is $object->{data}->{body_data}->{hatena_star}->[0]->[0], "ab";
      is $object->{data}->{body_data}->{hatena_star}->[1]->[0], "cd";
    } $current->c;
  });
} n => 3, name => 'body_data field';

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

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      todo_state => 2, # closed
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      is $object->{data}->{todo_state}, 2;
    } $current->c;
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      todo_state => 0, # default
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      is $object->{data}->{todo_state}, 0;
    } $current->c;
  });
} n => 2, name => 'todo state';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1', index_type => 3});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      edit_index_id => 1,
      index_id => $current->o ('i1')->{index_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      is $object->{data}->{todo_state}, 1;
    } $current->c;
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      todo_state => 0, # default
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      edit_index_id => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $object = $_[0];
    test {
      is $object->{data}->{todo_state}, 0;
    } $current->c;
  });
} n => 2, name => 'todo state';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1', index_type => 3});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      edit_assigned_account_id => 1,
      assigned_account_id => 532523333,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1', revision_id => $_[0]->{json}->{object_revision_id});
  })->then (sub {
    my $object = $_[0];
    test {
      is 0+keys %{$object->{data}->{assigned_account_ids}}, 1;
      ok $object->{data}->{assigned_account_ids}->{532523333};
      ok $object->{revision_data}->{changes}->{fields}->{assigned_account_ids};
    } $current->c;
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      edit_assigned_account_id => 1,
      assigned_account_id => 532523333,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{object_revision_id}, undef;
    } $current->c;
    return $current->object ($current->o ('o1'), account => 'a1', revision_id => $result->{json}->{object_revision_id});
  })->then (sub {
    my $object = $_[0];
    test {
      is 0+keys %{$object->{data}->{assigned_account_ids}}, 1;
      ok $object->{data}->{assigned_account_ids}->{532523333};
      ok ! $object->{revision_data}->{changes}->{fields}->{assigned_account_ids};
    } $current->c;
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      edit_assigned_account_id => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      like $result->{res}->body_bytes, qr{"object_revision_id"\s*:\s*"};
    } $current->c;
    return $current->object ($current->o ('o1'), account => 'a1', revision_id => $result->{json}->{object_revision_id});
  })->then (sub {
    my $object = $_[0];
    test {
      is 0+keys %{$object->{data}->{assigned_account_ids}}, 0;
      ok $object->{revision_data}->{changes}->{fields}->{assigned_account_ids};
    } $current->c;
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      edit_assigned_account_id => 1,
      assigned_account_id => 532523366,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1', revision_id => $_[0]->{json}->{object_revision_id});
  })->then (sub {
    my $object = $_[0];
    test {
      is 0+keys %{$object->{data}->{assigned_account_ids}}, 1;
      ok $object->{data}->{assigned_account_ids}->{532523366};
      ok $object->{revision_data}->{changes}->{fields}->{assigned_account_ids};
    } $current->c;
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      edit_assigned_account_id => 1,
      assigned_account_id => [532523333, 6444444],
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1', revision_id => $_[0]->{json}->{object_revision_id});
  })->then (sub {
    my $object = $_[0];
    test {
      is 0+keys %{$object->{data}->{assigned_account_ids}}, 2;
      ok $object->{data}->{assigned_account_ids}->{532523333};
      ok $object->{data}->{assigned_account_ids}->{6444444};
      ok $object->{revision_data}->{changes}->{fields}->{assigned_account_ids};
    } $current->c;
  });
} n => 17, name => 'assigned_account_id';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_object (o2 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_object (o3 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_object (o4 => {group => 'g2', account => 'a1'});
  })->then (sub {
    return $current->are_errors (
      ['POST', ['o', $current->o ('o1')->{object_id}, 'edit.json'], {}, account => 'a1', group => 'g1'],
      [
        {params => {parent_object_id => 554421111}, status => 404},
        {params => {parent_object_id => $current->o ('o4')->{object_id}}, status => 404},
        {params => {parent_object_id => $current->o ('o1')->{object_id}}, status => 409},
      ],
    );
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      parent_object_id => $current->o ('o2')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1', revision_id => $_[0]->{json}->{object_revision_id});
  })->then (sub {
    my $object = $_[0];
    test {
      is $object->{data}->{thread_id}, $current->o ('o2')->{object_id};
      is $object->{data}->{parent_object_id}, $current->o ('o2')->{object_id};
      ok $object->{revision_data}->{changes}->{fields}->{parent_object_id};
      ok $object->{revision_data}->{changes}->{fields}->{thread_id};
    } $current->c;
    return $current->are_errors (
      ['POST', ['o', $current->o ('o2')->{object_id}, 'edit.json'], {}, account => 'a1', group => 'g1'],
      [
        {params => {parent_object_id => $current->o ('o1')->{object_id}}, status => 409},
      ],
    );
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      parent_object_id => $current->o ('o3')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1', revision_id => $_[0]->{json}->{object_revision_id});
  })->then (sub {
    my $object = $_[0];
    test {
      is $object->{data}->{thread_id}, $current->o ('o3')->{object_id};
      is $object->{data}->{parent_object_id}, $current->o ('o3')->{object_id};
      ok $object->{revision_data}->{changes}->{fields}->{parent_object_id};
      ok $object->{revision_data}->{changes}->{fields}->{thread_id};
    } $current->c;
    return $current->post_json (['o', $current->o ('o2')->{object_id}, 'edit.json'], {
      parent_object_id => $current->o ('o1')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o2'), account => 'a1', revision_id => $_[0]->{json}->{object_revision_id});
  })->then (sub {
    my $object = $_[0];
    test {
      is $object->{data}->{thread_id}, $current->o ('o3')->{object_id};
      is $object->{data}->{parent_object_id}, $current->o ('o1')->{object_id};
      ok $object->{revision_data}->{changes}->{fields}->{parent_object_id};
      ok $object->{revision_data}->{changes}->{fields}->{thread_id};
    } $current->c;
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      parent_object_id => 0,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1', revision_id => $_[0]->{json}->{object_revision_id});
  })->then (sub {
    my $object = $_[0];
    test {
      is $object->{data}->{thread_id}, $current->o ('o1')->{object_id};
      is $object->{data}->{parent_object_id}, undef;
      ok $object->{revision_data}->{changes}->{fields}->{parent_object_id};
      ok $object->{revision_data}->{changes}->{fields}->{thread_id};
    } $current->c;
  });
} n => 18, name => 'thread';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o2 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_object (o3 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_object (o4 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 1, # html
      body => (sprintf q{<a href="../../o/%s/">abc</a>}, $current->o ('o2')->{object_id}),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 1, # html
      body => (sprintf q{<iframe src="../../o/%s/embed"></iframe>}, $current->o ('o3')->{object_id}),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 1, # html
      body => (sprintf q{<img src="../../o/%s/image">}, $current->o ('o4')->{object_id}),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o2')->{object_id},
      with_data => 1,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $objects = [grep {
        $_->{data}->{body_type} == 3 and
        $_->{data}->{body_data}->{trackback};
      } values %{$result->{json}->{objects}}];
      is 0+@$objects, 1;
      is $objects->[0]->{data}->{body_data}->{trackback}->{object_id}, $current->o ('o1')->{object_id};
      unlike $result->{res}->body_bytes, qr{"object_id"\s*:\s*\d};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o3')->{object_id},
      with_data => 1,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $objects = [grep {
        $_->{data}->{body_type} == 3 and
        $_->{data}->{body_data}->{trackback};
      } values %{$result->{json}->{objects}}];
      is 0+@$objects, 1;
      is $objects->[0]->{data}->{body_data}->{trackback}->{object_id}, $current->o ('o1')->{object_id};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o4')->{object_id},
      with_data => 1,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $objects = [grep {
        $_->{data}->{body_type} == 3 and
        $_->{data}->{body_data}->{trackback};
      } values %{$result->{json}->{objects}}];
      is 0+@$objects, 1;
      is $objects->[0]->{data}->{body_data}->{trackback}->{object_id}, $current->o ('o1')->{object_id};
    } $current->c;
  });
} n => 7, name => 'trackback object created';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o2 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 1, # html
      body => (sprintf q{<a href="../../o/%s/">abc</a>}, 63462424222),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => 63462424222,
      with_data => 1,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $objects = [values %{$result->{json}->{objects}}];
      is 0+@$objects, 0;
    } $current->c;
  });
} n => 1, name => 'trackback referenced object not found';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o2 => {group => 'g2', account => 'a1'});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 1, # html
      body => (sprintf q{<a href="/g/%s/o/%s/">abc</a>},
                   $current->o ('g2')->{group_id},
                   $current->o ('o2')->{object_id}),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o2')->{object_id},
      with_data => 1,
    }, group => 'g2', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $objects = [grep {
        $_->{data}->{body_type} == 3 and
        $_->{data}->{body_data}->{trackback};
      } values %{$result->{json}->{objects}}];
      is 0+@$objects, 0;
    } $current->c;
  });
} n => 1, name => 'trackback another group';

Test {
  my $current = shift;
  my $wn = "\x{64344} " . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1',
                                          is_default_wiki => 1});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 1, # html
      body => (sprintf q{<a href="" data-wiki-name="%s">abc</a>}, $wn),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      parent_wiki_name => $wn,
      with_data => 1,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $objects = [grep {
        $_->{data}->{body_type} == 3 and
        $_->{data}->{body_data}->{trackback};
      } values %{$result->{json}->{objects}}];
      is 0+@$objects, 1;
      is $objects->[0]->{data}->{body_data}->{trackback}->{object_id}, $current->o ('o1')->{object_id};
      unlike $result->{res}->body_bytes, qr{"object_id"\s*:\s*\d};
    } $current->c;
  });
} n => 3, name => 'trackback object for wiki name';

Test {
  my $current = shift;
  my $wn = "\x{64344} " . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1',
                                          is_default_wiki => 1});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 1, # html
      body => (sprintf q{<a href="../../wiki/%s/">abc</a>},
                   percent_encode_c $wn),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      parent_wiki_name => $wn,
      with_data => 1,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $objects = [grep {
        $_->{data}->{body_type} == 3 and
        $_->{data}->{body_data}->{trackback};
      } values %{$result->{json}->{objects}}];
      is 0+@$objects, 1;
      is $objects->[0]->{data}->{body_data}->{trackback}->{object_id}, $current->o ('o1')->{object_id};
      unlike $result->{res}->body_bytes, qr{"object_id"\s*:\s*\d};
    } $current->c;
  });
} n => 3, name => 'trackback object for wiki name';

Test {
  my $current = shift;
  my $wn = "\x{64344} " . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 1, # html
      body => (sprintf q{<a href="../../wiki/%s/">abc</a>},
                   percent_encode_c $wn),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1',
                                          is_default_wiki => 1});
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      parent_wiki_name => $wn,
      with_data => 1,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $objects = [grep {
        $_->{data}->{body_type} == 3 and
        $_->{data}->{body_data}->{trackback};
      } values %{$result->{json}->{objects}}];
      is 0+@$objects, 0;
    } $current->c;
  });
} n => 1, name => 'trackback object for wiki name, no default wiki';

Test {
  my $current = shift;
  my $wn = "\x{64344} " . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 1, # html
      body => (sprintf q{<a href="/g/%s/i/%s/wiki/%s/">abc</a>},
                   $current->o ('g1')->{group_id},
                   $current->o ('i1')->{index_id},
                   percent_encode_c $wn),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      parent_wiki_name => $wn,
      with_data => 1,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $objects = [grep {
        $_->{data}->{body_type} == 3 and
        $_->{data}->{body_data}->{trackback};
      } values %{$result->{json}->{objects}}];
      is 0+@$objects, 1;
      is $objects->[0]->{data}->{body_data}->{trackback}->{object_id}, $current->o ('o1')->{object_id};
      unlike $result->{res}->body_bytes, qr{"object_id"\s*:\s*\d};
    } $current->c;
  });
} n => 3, name => 'trackback object for wiki name';

Test {
  my $current = shift;
  my $wn = "\x{64344} " . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 1, # html
      body => (sprintf q{<a href="/g/%s/i/%s/wiki/%s/">abc</a>},
                   $current->o ('g1')->{group_id},
                   62525333222222,
                   percent_encode_c $wn),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      parent_wiki_name => $wn,
      with_data => 1,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $objects = [grep {
        $_->{data}->{body_type} == 3 and
        $_->{data}->{body_data}->{trackback};
      } values %{$result->{json}->{objects}}];
      is 0+@$objects, 0;
    } $current->c;
  });
} n => 1, name => 'trackback object for wiki name, bad index id';

RUN;

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
