use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [a3 => account => {}],
    [g1 => group => {members => ['a1', 'a2']}],
    [o1 => object => {group => 'g1', account => 'a1'}],
  )->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      called_account_id => $current->o ('a2')->{account_id},
    }, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->are_errors (
      ['POST', ['o', $current->o ('o1')->{object_id}, 'edit.json'], {
        called_account_id => $current->o ('a2')->{account_id},
      }, group => 'g1', account => 'a1'],
      [
        {params => {
          called_account_id => $current->o ('a3')->{account_id},
        }, status => 400, name => 'Not a group member'},
        {params => {
          called_account_id => [$current->o ('a1')->{account_id},
                                rand],
        }, status => 400, name => 'Not a group member'},
      ],
    );
  })->then (sub {
    return $current->get_json (['my', 'calls.json'], {}, account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item = $result->{json}->{items}->[0];
      is $item->{group_id}, $current->o ('g1')->{group_id};
      is $item->{thread_id}, $current->o ('o1')->{object_id};
      is $item->{object_id}, $current->o ('o1')->{object_id};
      is $item->{from_account_id}, $current->o ('a1')->{account_id};
      ok $item->{timestamp};
      ok ! $item->{read};
    } $current->c;
    return $current->get_json (['o', $current->o ('o1')->{object_id}, 'revisions.json'], {
      with_revision_data => 1,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $item = $result->{json}->{items}->[0];
      ok my $called = $item->{revision_data}->{changes}->{fields}->{called};
      is 0+@{$called->{account_ids}}, 1;
      is $called->{account_ids}->[0], $current->o ('a2')->{account_id};
      like $result->{res}->body_bytes, qr{"account_ids"\s*:\s*\[\s*"};
    } $current->c;
  });
} n => 12, name => 'called';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [a3 => account => {}],
    [g1 => group => {members => ['a1', 'a2'], owners => ['a3']}],
    [o1 => object => {group => 'g1', account => 'a1'}],
  )->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      called_account_id => [$current->o ('a2')->{account_id},
                            $current->o ('a2')->{account_id}, # dup
                            $current->o ('a3')->{account_id}],
    }, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['my', 'calls.json'], {}, account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item = $result->{json}->{items}->[0];
      is $item->{group_id}, $current->o ('g1')->{group_id};
      is $item->{object_id}, $current->o ('o1')->{object_id};
      is $item->{from_account_id}, $current->o ('a1')->{account_id};
    } $current->c;
    return $current->get_json (['my', 'calls.json'], {}, account => 'a3');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item = $result->{json}->{items}->[0];
      is $item->{group_id}, $current->o ('g1')->{group_id};
      is $item->{object_id}, $current->o ('o1')->{object_id};
      is $item->{from_account_id}, $current->o ('a1')->{account_id};
    } $current->c;
    return $current->get_json (['o', $current->o ('o1')->{object_id}, 'revisions.json'], {
      with_revision_data => 1,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $item = $result->{json}->{items}->[0];
      ok my $called = $item->{revision_data}->{changes}->{fields}->{called};
      is 0+@{$called->{account_ids}}, 2;
      is join ($;, sort { $a cmp $b } @{$called->{account_ids}}),
         join ($;, sort { $a cmp $b } $current->o ('a2')->{account_id}, $current->o ('a3')->{account_id});
    } $current->c;
  });
} n => 11, name => 'called multiple accounts';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [a3 => account => {}],
    [g1 => group => {members => ['a1', 'a2']}],
    [o1 => object => {group => 'g1', account => 'a1'}],
  )->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      called_account_id => $current->o ('a2')->{account_id},
    }, group => 'g1', account => 'a1');
  })->then (sub {
    $current->set_o (time1 => time);
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      called_account_id => $current->o ('a2')->{account_id},
    }, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['my', 'calls.json'], {}, account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item = $result->{json}->{items}->[0];
      is $item->{group_id}, $current->o ('g1')->{group_id};
      is $item->{thread_id}, $current->o ('o1')->{object_id};
      is $item->{object_id}, $current->o ('o1')->{object_id};
      is $item->{from_account_id}, $current->o ('a1')->{account_id};
      ok $current->o ('time1') < $item->{timestamp};
      ok ! $item->{read};
    } $current->c;
  });
} n => 7, name => 'called twice';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [a3 => account => {}],
    [g1 => group => {members => ['a1', 'a2']}],
    [o1 => object => {group => 'g1', account => 'a1'}],
    [o2 => object => {group => 'g1', account => 'a1',
                      parent_object => 'o1'}],
  )->then (sub {
    return $current->post_json (['o', $current->o ('o2')->{object_id}, 'edit.json'], {
      called_account_id => $current->o ('a2')->{account_id},
    }, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['my', 'calls.json'], {}, account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item = $result->{json}->{items}->[0];
      is $item->{group_id}, $current->o ('g1')->{group_id};
      is $item->{thread_id}, $current->o ('o1')->{object_id};
      is $item->{object_id}, $current->o ('o2')->{object_id};
    } $current->c;
  });
} n => 4, name => 'called thread_id';

RUN;

=head1 LICENSE

Copyright 2019 Wakaba <wakaba@suikawiki.org>.

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
