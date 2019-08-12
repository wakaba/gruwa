use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {
      name => $current->generate_text ('a1name' => {}),
    }],
    [a3 => account => {
      name => $current->generate_text ('a3name' => {}),
    }],
    [g1 => group => {
      title => $current->generate_text (t1 => {}),
      owner => 'a1',
      members => ['a3'],
    }],
  )->then (sub {
    return $current->are_errors (
      ['GET', ['g', $current->o ('g1')->{group_id}, 'my', 'info.json'], {}, account => 'a1'],
      [
        {path => ['g', int rand 10000, 'info.json'], status => 404},
        {account => '', status => 403},
        {account => undef, status => 403},
      ],
    );
  })->then (sub {
    return promised_for {
      my $account = shift;
      return $current->get_json (['g', $current->o ('g1')->{group_id}, 'my', 'info.json'], {}, account => $account)->then (sub {
        my $result = $_[0];
        test {
          my $acc = $result->{json}->{account};
          is $acc->{account_id}, $current->o ($account)->{account_id};
          like $result->{res}->body_bytes, qr{"account_id"\s*:\s*"};
          is $acc->{name}, $current->o ($account.'name');
          my $g = $result->{json}->{group};
          is $g->{group_id}, $current->o ('g1')->{group_id};
          like $result->{res}->body_bytes, qr{"group_id"\s*:\s*"};
          is $g->{title}, $current->o ('t1');
          is $g->{default_wiki_index_id}, undef;
          is $g->{theme}, 'green';
          my $gm = $result->{json}->{group_member};
          is $gm->{default_index_id}, undef;
          is $gm->{member_type}, {a1 => 2, a3 => 1}->{$account};
        } $current->c;
      });
    } ['a1', 'a3'];
  });
} n => 1+2*10, name => '/g/{}/my/info.json';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {members => ['a1']}],
    [i1 => index => {group => 'g1', account => 'a1'}],
  )->then (sub {
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'my.json'], {
      is_default => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $gm = $result->{json}->{group_member};
      is $gm->{default_index_id}, $current->o ('i1')->{index_id};
      like $result->{res}->body_bytes, qr{"default_index_id"\s*:\s*"};
    } $current->c;
  });
} n => 2, name => 'default_index_id';

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
