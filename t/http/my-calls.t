use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->get_json (['my', 'calls.json'], {})->then (sub {
    my $result = $_[0];
    test {
      is ref $result->{json}->{items}, 'ARRAY';
      is 0+@{$result->{json}->{items}}, 0;
      ok ! $result->{json}->{has_next};
      is $result->{json}->{next_ref}, undef;
    } $current->c;
  });
} n => 4, name => 'no account';

Test {
  my $current = shift;
  return $current->get_json (['my', 'calls.json'], {}, account => '')->then (sub {
    my $result = $_[0];
    test {
      is ref $result->{json}->{items}, 'ARRAY';
      is 0+@{$result->{json}->{items}}, 0;
      ok ! $result->{json}->{has_next};
      is $result->{json}->{next_ref}, undef;
    } $current->c;
  });
} n => 4, name => 'empty';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [g1 => group => {members => ['a2', 'a1']}],
    [o1 => object => {group => 'g1', account => 'a2',
                      called_account => 'a1'}],
  )->then (sub {
    return $current->get_json (['my', 'calls.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      ok ! $result->{json}->{has_next};
      ok $result->{json}->{next_ref};
      my $item = $result->{json}->{items}->[0];
      is $item->{group_id}, $current->o ('g1')->{group_id};
      like $result->{res}->body_bytes, qr{"group_id"\s*:\s*"};
      is $item->{thread_id}, $current->o ('o1')->{object_id};
      like $result->{res}->body_bytes, qr{"thread_id"\s*:\s*"};
      is $item->{object_id}, $current->o ('o1')->{object_id};
      like $result->{res}->body_bytes, qr{"object_id"\s*:\s*"};
      is $item->{from_account_id}, $current->o ('a2')->{account_id};
      like $result->{res}->body_bytes, qr{"from_account_id"\s*:\s*"};
      ok $item->{timestamp};
      ok ! $item->{read};
    } $current->c;
  });
} n => 13, name => 'has an item';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [g1 => group => {members => ['a2', 'a1']}],
    [o1 => object => {group => 'g1', account => 'a2', called_account => 'a1'}],
    [o2 => object => {group => 'g1', account => 'a2', called_account => 'a1'}],
    [o3 => object => {group => 'g1', account => 'a2', called_account => 'a1'}],
    [o4 => object => {group => 'g1', account => 'a2', called_account => 'a1'}],
    [o5 => object => {group => 'g1', account => 'a2', called_account => 'a1'}],
  )->then (sub {
    return $current->pages_ok ([['my', 'calls.json'], {
    }, account => 'a1'] => ['o1', 'o2', 'o3', 'o4', 'o5'], 'object_id');
  });
} n => 1, name => 'pager paging';

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
