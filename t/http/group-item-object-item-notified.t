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
    [g1 => group => {members => ['a1', 'a2', 'a3']}],
    [g2 => group => {members => ['a1']}],
    [o1 => object => {group => 'g1', account => 'a1'}],
    [o2 => object => {group => 'g1', account => 'a2'}],
    [o3 => object => {group => 'g1', account => 'a3', parent_object => 'o2'}],
  )->then (sub {
    return $current->are_errors (
      ['GET', ['o', $current->o ('o1')->{object_id}, 'notified.json'], {}, group => 'g1', account => 'a1'],
      [
        {group => 'g2', status => 404},
        {path => ['o', '5325253333', 'notified.json'], status => 404},
        {account => '', status => 403},
        {account => undef, status => 403},
      ],
    );
  })->then (sub {
    return $current->get_json (['o', $current->o ('o1')->{object_id}, 'notified.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{account_ids}}, 1;
      is $result->{json}->{account_ids}->[0], $current->o ('a1')->{account_id};
      like $result->{res}->body_bytes, qr{"account_ids":\["};
    } $current->c, name => 'empty object';
    return $current->get_json (['o', $current->o ('o2')->{object_id}, 'notified.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{account_ids}}, 2;
      my $got = join "\n", sort { $a cmp $b } @{$result->{json}->{account_ids}};
      my $exp = join "\n", sort { $a cmp $b } map { $current->o ($_)->{account_id} } 'a2', 'a3';
      is $got, $exp;
    } $current->c, name => 'thread root object';
    return $current->get_json (['o', $current->o ('o3')->{object_id}, 'notified.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{account_ids}}, 0;
    } $current->c, name => 'thread child object';
  });
} n => 7, name => 'notified accounts';

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
