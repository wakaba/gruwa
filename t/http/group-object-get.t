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
    } $current->c;
  });
} n => 2, name => 'no params';

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
      is $obj->{data}->{title}, '';
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
      is $obj->{data}->{title}, '';
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
      my $o5 = $result->{json}->{objects}->{$current->o (5)->{object_id}};
      is $o5->{reaction_data}->{object_id}, $current->o (5)->{object_id};
      is $o5->{reaction_data}->{reaction_type}, 1;
      my $o4 = $result->{json}->{objects}->{$current->o (4)->{object_id}};
      is $o4->{reaction_data}->{object_id}, $current->o (4)->{object_id};
      is $o4->{reaction_data}->{reaction_type}, 1;
      my $o3 = $result->{json}->{objects}->{$current->o (3)->{object_id}};
      is $o3->{reaction_data}->{object_id}, $current->o (3)->{object_id};
      is $o3->{reaction_data}->{reaction_type}, 1;
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
} n => 21, name => 'by parent_object';

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
