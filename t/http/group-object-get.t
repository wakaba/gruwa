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
    return $current->create_index (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->are_errors (
      ['GET', ['o', 'get.json'], {}, account => 'a1', group => 'g1'],
      [
        {account => '', status => 403},
        {account => undef, status => 403},
        {path => ['g', '532523', 'o', 'get.json'], status => 404},
      ],
    );
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 0;
      is 0+@{$result->{json}->{imported_sites}}, 0;
    } $current->c;
  });
} n => 3, name => 'no params';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      object_id => [52533, "abaegaea"],
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 0;
    } $current->c;
  });
} n => 1, name => 'bad object_id';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('o1')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 1;
      my $obj = $result->{json}->{objects}->{$current->o ('o1')->{object_id}};
      is $obj->{group_id}, $current->o ('g1')->{group_id};
      is $obj->{object_id}, $current->o ('o1')->{object_id};
      is $obj->{title}, '';
      is $obj->{data}, undef;
      ok $obj->{created};
      ok $obj->{updated};
      ok $obj->{timestamp};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('o1')->{object_id},
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 1;
      my $obj = $result->{json}->{objects}->{$current->o ('o1')->{object_id}};
      is $obj->{group_id}, $current->o ('g1')->{group_id};
      is $obj->{object_id}, $current->o ('o1')->{object_id};
      is $obj->{title}, '';
      is $obj->{data}->{title}, undef;
      ok $obj->{created};
      ok $obj->{updated};
      ok $obj->{timestamp};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('o1')->{object_id},
    }, account => 'a1', group => 'g2');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 0;
    } $current->c;
  });
} n => 17, name => 'found';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_object (o2 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      object_id => [$current->o ('o1')->{object_id},
                    $current->o ('o2')->{object_id}],
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 2;
      my $obj1 = $result->{json}->{objects}->{$current->o ('o1')->{object_id}};
      is $obj1->{group_id}, $current->o ('g1')->{group_id};
      is $obj1->{object_id}, $current->o ('o1')->{object_id};
      my $obj2 = $result->{json}->{objects}->{$current->o ('o2')->{object_id}};
      is $obj2->{group_id}, $current->o ('g1')->{group_id};
      is $obj2->{object_id}, $current->o ('o2')->{object_id};
      like $result->{res}->body_bytes, qr{"group_id"\s*:\s*"};
      like $result->{res}->body_bytes, qr{"object_id"\s*:\s*"};
    } $current->c;
  });
} n => 7, name => 'multiple';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_object (o2 => {group => 'g2', account => 'a1'});
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      object_id => [$current->o ('o1')->{object_id},
                    $current->o ('o2')->{object_id}],
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 1;
      my $obj1 = $result->{json}->{objects}->{$current->o ('o1')->{object_id}};
      is $obj1->{group_id}, $current->o ('g1')->{group_id};
      is $obj1->{object_id}, $current->o ('o1')->{object_id};
      is $result->{json}->{objects}->{$current->o ('o2')->{object_id}}, undef;
    } $current->c;
  });
} n => 4, name => 'multiple, other group';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return promised_map {
      return $current->create_object ($_[0] => {group => 'g1', account => 'a1',
                                                index => 'i1'});
    } [1..8];
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 3;
      ok $result->{json}->{objects}->{$current->o (8)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (7)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (6)->{object_id}};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      ref => $result->{json}->{next_ref},
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 3;
      ok $result->{json}->{objects}->{$current->o (5)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (4)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (3)->{object_id}};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      ref => $result->{json}->{next_ref},
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 2;
      ok $result->{json}->{objects}->{$current->o (2)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (1)->{object_id}};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      ref => $result->{json}->{next_ref},
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 0;
      is $result->{json}->{next_ref}, undef;
    } $current->c;
  });
} n => 16, name => 'index not empty';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    my $time = time;
    return Promise->all ([
      $current->create_object (1 => {group => 'g1', account => 'a1',
                                     index => 'i1', timestamp => $time}),
      $current->create_object (2 => {group => 'g1', account => 'a1',
                                     index => 'i1', timestamp => $time-24*60*60}),
      $current->create_object (3 => {group => 'g1', account => 'a1',
                                     index => 'i1', timestamp => $time}),
      $current->create_object (4 => {group => 'g1', account => 'a1',
                                     index => 'i1', timestamp => $time-24*60*60}),
      $current->create_object (5 => {group => 'g1', account => 'a1',
                                     index => 'i1', timestamp => $time-24*60*60*2}),
      $current->create_object (6 => {group => 'g1', account => 'a1',
                                     index => 'i1', timestamp => $time}),
    ]);
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      limit => 2,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 2;
      ok $result->{json}->{objects}->{$current->o (6)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (3)->{object_id}};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      ref => $result->{json}->{next_ref},
      limit => 2,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 2;
      ok $result->{json}->{objects}->{$current->o (1)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (4)->{object_id}};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      ref => $result->{json}->{next_ref},
      limit => 2,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 2;
      ok $result->{json}->{objects}->{$current->o (2)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (5)->{object_id}};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      ref => $result->{json}->{next_ref},
      limit => 2,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 0;
      is $result->{json}->{next_ref}, undef;
    } $current->c;
  });
} n => 14, name => 'index timestamp';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_object (o2 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->are_errors (
      ['GET', ['o', 'get.json'], {
        object_id => $current->o ('o1')->{object_id},
        object_revision_id => $current->o ('o1')->{object_revision_id},
      }, account => 'a1', group => 'g1'],
      [
        {params => {
          object_id => $current->o ('o1')->{object_id},
          object_revision_id => 523153333,
        }, status => 404, name => 'Bad |object_revision_id|'},
        {params => {
          object_id => $current->o ('o1')->{object_id},
          object_revision_id => $current->o ('o2')->{object_revision_id},
        }, status => 404, name => 'Bad |object_revision_id|'},
      ],
    );
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('o1')->{object_id},
      object_revision_id => $current->o ('o1')->{object_revision_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $obj = $result->{json}->{objects}->{$current->o ('o1')->{object_id}};
      is $obj->{object_id}, $current->o ('o1')->{object_id};
      is $obj->{title}, '';
      is $obj->{data}->{title}, undef;
      is $obj->{data}->{body}, '';
      is $obj->{data}->{object_revision_id}, $current->o ('o1')->{object_revision_id}, 'data is exposed even without with_data=1';
      like $result->{res}->body_bytes, qr{"object_id"\s*:\s*"};
      like $result->{res}->body_bytes, qr{"object_revision_id"\s*:\s*"};
      ok $obj->{created};
      is $obj->{updated}, $obj->{created};
      is $obj->{data}->{timestamp}, $obj->{created};
      is $obj->{revision_data}->{changes}->{action}, 'new';
      is $obj->{revision_author_account_id}, $current->o ('a1')->{account_id};
    } $current->c;
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('o1')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $obj = $result->{json}->{objects}->{$current->o ('o1')->{object_id}};
      is $obj->{object_id}, $current->o ('o1')->{object_id};
      is $obj->{title}, '';
      is $obj->{data}, undef;
      ok $obj->{created};
      is $obj->{updated}, $obj->{created};
      is $obj->{revision_data}, undef;
    } $current->c, name => 'without object_revision_id';
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      object_id => [$current->o ('o1')->{object_id},
                    $current->o ('o2')->{object_id}],
      object_revision_id => $current->o ('o1')->{object_revision_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok $result->{json}->{objects}->{$current->o ('o1')->{object_id}};
      is $result->{json}->{objects}->{$current->o ('o1')->{object_id}}->{revision_data}, undef;
      ok $result->{json}->{objects}->{$current->o ('o2')->{object_id}};
      is $result->{json}->{objects}->{$current->o ('o2')->{object_id}}->{revision_data}, undef;
    } $current->c, name => 'object_revision_id ignored';
    return $current->get_json (['o', 'get.json'], {
      object_id => [$current->o ('o1')->{object_id},
                    $current->o ('o2')->{object_id}],
      object_revision_id => 545131111,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok $result->{json}->{objects}->{$current->o ('o1')->{object_id}};
      is $result->{json}->{objects}->{$current->o ('o1')->{object_id}}->{revision_data}, undef;
      ok $result->{json}->{objects}->{$current->o ('o2')->{object_id}};
      is $result->{json}->{objects}->{$current->o ('o2')->{object_id}}->{revision_data}, undef;
    } $current->c, name => 'object_revision_id ignored';
  });
} n => 27, name => 'with object_revision_id';

Test {
  my $current = shift;
  my $wiki_name = "\x{6001} " . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {account => 'a1', group => 'g1', index_type => 2});
  })->then (sub {
    return promised_map {
      return $current->create_object ($_[0] => {group => 'g1', account => 'a1',
                                                index => 'i1',
                                                title => $wiki_name});
    } [1..8];
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      wiki_name => $wiki_name,
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 3;
      ok $result->{json}->{objects}->{$current->o (8)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (7)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (6)->{object_id}};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      wiki_name => $wiki_name,
      ref => $result->{json}->{next_ref},
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 3;
      ok $result->{json}->{objects}->{$current->o (5)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (4)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (3)->{object_id}};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      wiki_name => $wiki_name,
      ref => $result->{json}->{next_ref},
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 2;
      ok $result->{json}->{objects}->{$current->o (2)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (1)->{object_id}};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      wiki_name => $wiki_name,
      ref => $result->{json}->{next_ref},
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 0;
      is $result->{json}->{next_ref}, undef;
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      index_id => undef,
      wiki_name => $wiki_name,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 0;
      is $result->{json}->{next_ref}, undef;
    } $current->c;
  });
} n => 18, name => 'wiki name not empty';

Test {
  my $current = shift;
  my $wiki_name = "\x{6001} " . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {account => 'a1', group => 'g1', index_type => 2});
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      wiki_name => $wiki_name,
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 0;
      is $result->{json}->{next_ref}, undef;
    } $current->c;
  });
} n => 2, name => 'wiki name empty';

Test {
  my $current = shift;
  my $wiki_name = "\x{6001} " . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {account => 'a1', group => 'g1'});
  })->then (sub {
    return $current->create_object (o2 => {account => 'a1', group => 'g1', parent_object => 'o1'});
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('o2')->{object_id},
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $obj = $result->{json}->{objects}->{$current->o ('o2')->{object_id}};
      is $obj->{data}->{parent_object_id}, $current->o ('o1')->{object_id};
      is $obj->{data}->{thread_id}, $current->o ('o1')->{object_id};
      like $result->{res}->body_bytes, qr{"parent_object_id"\s*:\s*"};
      like $result->{res}->body_bytes, qr{"thread_id"\s*:\s*"};
    } $current->c;
  });
} n => 4, name => 'thread of object';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o0 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return promised_map {
      return $current->create_object ($_[0] => {group => 'g1', account => 'a1',
                                                parent_object => 'o0'});
    } [1..8];
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      thread_id => $current->o ('o0')->{object_id},
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 3;
      ok $result->{json}->{objects}->{$current->o (8)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (7)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (6)->{object_id}};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      thread_id => $current->o ('o0')->{object_id},
      ref => $result->{json}->{next_ref},
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 3;
      ok $result->{json}->{objects}->{$current->o (5)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (4)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (3)->{object_id}};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      thread_id => $current->o ('o0')->{object_id},
      ref => $result->{json}->{next_ref},
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 2;
      ok $result->{json}->{objects}->{$current->o (2)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (1)->{object_id}};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      thread_id => $current->o ('o0')->{object_id},
      ref => $result->{json}->{next_ref},
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 0;
      is $result->{json}->{next_ref}, undef;
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      thread_id => $current->o ('o0')->{object_id},
    }, account => 'a1', group => 'g2');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 0;
      is $result->{json}->{next_ref}, undef;
    } $current->c, name => 'different group';
  });
} n => 18, name => 'by thread';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o0 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      thread_id => $current->o ('o0')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 0;
      is $result->{json}->{next_ref}, undef;
    } $current->c;
  });
} n => 2, name => 'by thread - no children';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      thread_id => int rand 1000000000,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 0;
      is $result->{json}->{next_ref}, undef;
    } $current->c;
  });
} n => 2, name => 'by thread - no thread';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o0 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return promised_map {
      return $current->create_object ($_[0] => {group => 'g1', account => 'a1',
                                                parent_object => 'o0'});
    } [1..8];
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o0')->{object_id},
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 3;
      ok $result->{json}->{objects}->{$current->o (8)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (7)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (6)->{object_id}};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o0')->{object_id},
      ref => $result->{json}->{next_ref},
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 3;
      ok $result->{json}->{objects}->{$current->o (5)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (4)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (3)->{object_id}};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o0')->{object_id},
      ref => $result->{json}->{next_ref},
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 2;
      ok $result->{json}->{objects}->{$current->o (2)->{object_id}};
      ok $result->{json}->{objects}->{$current->o (1)->{object_id}};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o0')->{object_id},
      ref => $result->{json}->{next_ref},
      limit => 3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 0;
      is $result->{json}->{next_ref}, undef;
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o0')->{object_id},
    }, account => 'a1', group => 'g2');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 0;
      is $result->{json}->{next_ref}, undef;
    } $current->c, name => 'different group';
  });
} n => 18, name => 'by parent_object';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o0 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o0')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 0;
      is $result->{json}->{next_ref}, undef;
    } $current->c;
  });
} n => 2, name => 'by parent_object - no children';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => int rand 1000000000,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 0;
      is $result->{json}->{next_ref}, undef;
    } $current->c;
  });
} n => 2, name => 'by parent_object - no parent_object';

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
      body => (sprintf q{<a href="../../wiki/%s/">abc</a>
                         <a href="../../wiki/%s/">abc</a>},
                   percent_encode_c $wn, percent_encode_c $wn),
    }, account => 'a1', group => 'g1');
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
} n => 3, name => 'parent wiki name';

Test {
  my $current = shift;
  my $wn = "\x{64344} " . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1',
                                          is_default_wiki => 1});
  })->then (sub {
    return $current->create_index (i2 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 1, # html
      body => (sprintf q{<a href="../../wiki/%s/">abc</a>
                         <a href="../../wiki/%s/">abc</a>},
                   percent_encode_c $wn, percent_encode_c $wn),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->create_object (o2 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o2')->{object_id}, 'edit.json'], {
      body_type => 1, # html
      body => (sprintf q{<a href="../../wiki/%s/">abc</a>},
                   percent_encode_c $wn),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->post_json (['o', $current->o ('o2')->{object_id}, 'edit.json'], {
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
      is 0+@$objects, 2;
      my %object_id = map {
        $_->{data}->{body_data}->{trackback}->{object_id} => 1;
      } @$objects;
      ok $object_id{$current->o ('o1')->{object_id}};
      ok $object_id{$current->o ('o2')->{object_id}};
    } $current->c;
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i2')->{index_id},
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
} n => 4, name => 'parent wiki name - multiple results';

Test {
  my $current = shift;
  my $site1 = 'https://' . rand . '.test/foo1/';
  my $site2 = 'https://' . rand . '.test/foo2/';
  my $page1 = $site1 . rand;
  my $page2 = $site2 . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
      source_page => $page1,
      source_site => $site1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    $current->set_o (o1 => $_[0]->{json});
    return $current->post_json (['o', 'create.json'], {
      source_page => $page2,
      source_site => $site2,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    $current->set_o (o2 => $_[0]->{json});
    return $current->get_json (['o', 'get.json'], {
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $sites = $result->{json}->{imported_sites};
      is 0+@$sites, 2;
      ok grep { $_ eq $site1 } @$sites;
      ok grep { $_ eq $site2 } @$sites;
    } $current->c;
  });
} n => 3, name => 'imported source sites';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {
      group => 'g1', account => 'a1',
      body => $current->generate_text ('n1'),
    });
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('o1')->{object_id},
      with_snippet => 1,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $o = $result->{json}->{objects}->{$current->o ('o1')->{object_id}};
      ok $o->{snippet};
    } $current->c;
  });
} n => 1, name => 'with_snippet';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {owners => ['a1']}],
    [i1 => index => {group => 'g1', account => 'a1'}],
    [o1 => object => {group => 'g1', account => 'a1', index => 'i1',
                      body => $current->generate_text (t1 => {}),
                      user_status => 1}], # open
    [o2 => object => {group => 'g1', account => 'a1', index => 'i1',
                      body => $current->generate_text (t2 => {})}],
  )->then (sub {
    return $current->post_json (['o', $current->o ('o2')->{object_id}, 'edit.json'], {
      user_status => 2, # deleted
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      object_id => [$current->o ('o1')->{object_id},
                    $current->o ('o2')->{object_id}],
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $obj1 = $result->{json}->{objects}->{$current->o ('o1')->{object_id}};
      is $obj1->{user_status}, 1;
      is $obj1->{owner_status}, 1;
      is $obj1->{data}->{user_status}, $obj1->{user_status};
      is $obj1->{data}->{owner_status}, $obj1->{owner_status};
      is $obj1->{data}->{body}, $current->o ('t1');
      my $obj2 = $result->{json}->{objects}->{$current->o ('o2')->{object_id}};
      is $obj2->{user_status}, 2;
      is $obj2->{owner_status}, 1;
      is $obj2->{data}->{user_status}, $obj2->{user_status};
      is $obj2->{data}->{owner_status}, $obj2->{owner_status};
      is $obj2->{data}->{body}, undef;
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      index_id => $current->o ('i1')->{index_id},
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $obj1 = $result->{json}->{objects}->{$current->o ('o1')->{object_id}};
      is $obj1->{user_status}, undef;
      is $obj1->{owner_status}, undef;
      is $obj1->{data}->{user_status}, 1;
      is $obj1->{data}->{owner_status}, 1;
      is $obj1->{data}->{body}, $current->o ('t1');
      my $obj2 = $result->{json}->{objects}->{$current->o ('o2')->{object_id}};
      is $obj2, undef;
    } $current->c;
  });
} n => 16, name => 'user_status';

RUN;

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
