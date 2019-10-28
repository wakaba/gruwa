use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create_account (ao => {})->then (sub {
    return $current->create_account (am => {});
  })->then (sub {
    return $current->create_group (g1 => {title => "a\x{500}", owner => 'ao', members => ['am']});
  })->then (sub {
    return $current->are_errors (
      ['GET', ['i', 'list.json'], {}, account => 'am', group => 'g1'],
      [
        {path => ['g', '532533', 'i', 'list.json'], group => undef, status => 404},
        {account => '', status => 403, name => 'not member'},
        {account => undef, status => 403, name => 'no account'},
      ],
    );
  })->then (sub {
    return $current->get_json (['i', 'list.json'], {}, account => 'am', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{index_list}}, 0;
    } $current->c;
  })->then (sub {
    return $current->get_json (['i', 'list.json'], {}, account => 'ao', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{index_list}}, 0;
    } $current->c;
  });
} n => 3, name => '/g/{}/i/list.json empty';

Test {
  my $current = shift;
  return $current->create_account (ao => {})->then (sub {
    return $current->create_account (am => {});
  })->then (sub {
    return $current->create_group (g1 => {title => "a\x{500}", owner => 'ao', members => ['am']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1',
                                          account => 'am',
                                          title => "ab\x{4000}"});
  })->then (sub {
    return $current->get_json (['i', 'list.json'], {}, account => 'am', group => $current->o ('g1'));
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{index_list}}, 1;
      my $index = $result->{json}->{index_list}->{$current->o ('i1')->{index_id}};
      is $index->{group_id}, $current->o ('g1')->{group_id};
      is $index->{index_id}, $current->o ('i1')->{index_id};
      is $index->{index_type}, 1;
      is $index->{title}, "ab\x{4000}";
      ok $index->{updated};
      like $result->{res}->body_bytes, qr{"group_id"\s*:\s*"};
      like $result->{res}->body_bytes, qr{"index_id"\s*:\s*"};
    } $current->c;
  })->then (sub {
    return $current->get_json (['i', 'list.json'], {}, account => 'ao', group => $current->o ('g1'));
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{index_list}}, 1;
      my $index = $result->{json}->{index_list}->{$current->o ('i1')->{index_id}};
      is $index->{group_id}, $current->o ('g1')->{group_id};
      is $index->{index_id}, $current->o ('i1')->{index_id};
      is $index->{title}, "ab\x{4000}";
      ok $index->{updated};
    } $current->c;
  });
} n => 13, name => '/g/{}/i/list.json has an item';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {index_type => 4, group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_index (i2 => {index_type => 7, group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_index (i3 => {index_type => 17, group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->get_json (['i', 'list.json'], {
      index_type => [4, 7],
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{index_list}}, 2;
      ok $result->{json}->{index_list}->{$current->o ('i1')->{index_id}};
      ok $result->{json}->{index_list}->{$current->o ('i2')->{index_id}};
    } $current->c;
  });
} n => 3, name => '/g/{}/i/list.json index_type';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1',
                                          color => '#ffaa42',
                                          theme => 'red',
                                          deadline => '2051-04-15'});
  })->then (sub {
    return $current->get_json (['i', 'list.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $data = $result->{json}->{index_list}->{$current->o ('i1')->{index_id}};
      is $data->{color}, '#ffaa42';
      is $data->{theme}, 'red';
      is $data->{deadline}, 2565129600;
      is $data->{subtype}, undef;
    } $current->c;
  });
} n => 4, name => '/g/{}/i/list.json options';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1',
                                          color => '#ffaa42',
                                          theme => 'red',
                                          deadline => '2051-04-15',
                                          index_type => 6,
                                          subtype => 'image'});
  })->then (sub {
    return $current->get_json (['i', 'list.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $data = $result->{json}->{index_list}->{$current->o ('i1')->{index_id}};
      is $data->{color}, '#ffaa42';
      is $data->{theme}, 'red';
      is $data->{deadline}, 2565129600;
      is $data->{subtype}, 'image';
    } $current->c;
  });
} n => 4, name => '/g/{}/i/list.json options - fileset';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1',
                                          color => '#ffaa42',
                                          theme => 'red',
                                          deadline => '2051-04-15',
                                          index_type => 6,
                                          subtype => undef});
  })->then (sub {
    return $current->get_json (['i', 'list.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $data = $result->{json}->{index_list}->{$current->o ('i1')->{index_id}};
      is $data->{color}, '#ffaa42';
      is $data->{theme}, 'red';
      is $data->{deadline}, 2565129600;
      is $data->{subtype}, 'file';
    } $current->c;
  });
} n => 4, name => '/g/{}/i/list.json options - fileset no subtype';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {index_type => 9, group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_index (i2 => {index_type => 9, subtype => "foo", group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_index (i3 => {index_type => 9, subtype => "bar", group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_index (i4 => {index_type => 9, subtype => "baz", group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_index (i5 => {index_type => 9, subtype => "bar", group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->get_json (['i', 'list.json'], {
      subtype => ["foo", "bar"],
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{index_list}}, 3;
      ok $result->{json}->{index_list}->{$current->o ('i2')->{index_id}};
      ok $result->{json}->{index_list}->{$current->o ('i3')->{index_id}};
      ok $result->{json}->{index_list}->{$current->o ('i5')->{index_id}};
      is $result->{json}->{index_list}->{$current->o ('i5')->{index_id}}->{subtype}, 'bar';
    } $current->c;
  });
} n => 5, name => '/g/{}/i/list.json subtype';

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
