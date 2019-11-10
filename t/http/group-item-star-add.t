use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {members => ['a1']}],
    [o1 => object => {group => 'g1', account => 'a1'}],
  )->then (sub {
    return $current->are_errors (
      ['POST', ['star', 'add.json'], {
        object_id => $current->o ('o1')->{object_id},
        delta => 14,
      }, account => 'a1', group => 'g1'],
      [
        {method => 'GET', status => 405},
        {origin => undef, status => 400},
        {account => undef, status => 403},
        {account => '', status => 403},
        {params => {object_id => 0}, status => 404},
        {params => {object_id => rand}, status => 404},
        {params => {}, status => 404},
        {params => {
          object_id => $current->o ('o1')->{object_id},
          delta => 0,
        }, status => 200},
        {params => {
          object_id => $current->o ('o1')->{object_id},
          delta => -1,
        }, status => 200},
      ],
    );
  })->then (sub {
    return $current->post_json (['star', 'add.json'], {
      object_id => $current->o ('o1')->{object_id},
      delta => 4.6,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['star', 'list.json'], {
      o => $current->o ('o1')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $stars = $result->{json}->{items}->{$current->o ('o1')->{object_id}};
      is 0+@$stars, 1;
      is $stars->[0]->{author_account_id}, $current->o ('a1')->{account_id};
      is $stars->[0]->{type_id}, 0;
      is $stars->[0]->{count}, 4;
    } $current->c;
    return $current->post_json (['star', 'add.json'], {
      object_id => $current->o ('o1')->{object_id},
      delta => 10,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['star', 'list.json'], {
      o => $current->o ('o1')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $stars = $result->{json}->{items}->{$current->o ('o1')->{object_id}};
      is 0+@$stars, 1;
      is $stars->[0]->{author_account_id}, $current->o ('a1')->{account_id};
      is $stars->[0]->{type_id}, 0;
      is $stars->[0]->{count}, 14;
    } $current->c;
    return $current->post_json (['star', 'add.json'], {
      object_id => $current->o ('o1')->{object_id},
      delta => -3,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['star', 'list.json'], {
      o => $current->o ('o1')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $stars = $result->{json}->{items}->{$current->o ('o1')->{object_id}};
      is 0+@$stars, 1;
      is $stars->[0]->{author_account_id}, $current->o ('a1')->{account_id};
      is $stars->[0]->{type_id}, 0;
      is $stars->[0]->{count}, 11;
    } $current->c;
  });
} n => 13, name => 'add.json';

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
