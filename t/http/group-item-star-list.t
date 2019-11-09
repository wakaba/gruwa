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
    [g1 => group => {members => ['a1', 'a2']}],
    [o1 => object => {group => 'g1', account => 'a1'}],
  )->then (sub {
    return $current->add_star ({group => 'g1', object => 'o1', delta => 30,
                                account => 'a2'});
  })->then (sub {
    return $current->add_star ({group => 'g1', object => 'o1', delta => 40,
                                account => 'a2'});
  })->then (sub {
    return $current->add_star ({group => 'g1', object => 'o1', delta => 20, account => 'a1'});
  })->then (sub {
    return $current->get_json (['star', 'list.json'], {
      o => $current->o ('o1')->{object_id},
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $stars = $result->{json}->{items}->{$current->o ('o1')->{object_id}};
      is 0+@$stars, 2;
      is $stars->[0]->{author_account_id}, $current->o ('a2')->{account_id};
      is $stars->[0]->{type_id}, 0;
      is $stars->[0]->{count}, 70;
      is $stars->[1]->{author_account_id}, $current->o ('a1')->{account_id};
      is $stars->[1]->{type_id}, 0;
      is $stars->[1]->{count}, 20;
      like $result->{res}->body_bytes, qr{"author_account_id"\s*:\s*"};
      like $result->{res}->body_bytes, qr{"type_id"\s*:\s*"};
      unlike $result->{res}->body_bytes, qr{"author_account_id"\s*:\s*[0-9]};
      unlike $result->{res}->body_bytes, qr{"type_id"\s*:\s*[0-9]};
    } $current->c;
  });
} n => 11, name => 'list';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [g1 => group => {members => ['a1', 'a2']}],
    [o1 => object => {group => 'g1', account => 'a1'}],
    [o2 => object => {group => 'g1', account => 'a1'}],
    [o3 => object => {group => 'g1', account => 'a1'}],
  )->then (sub {
    return $current->add_star ({object => 'o1', delta => 30,
                                account => 'a1', group => 'g1'});
  })->then (sub {
    return $current->add_star ({object => 'o2', delta => 40,
                                account => 'a1', group => 'g1'});
  })->then (sub {
    return $current->add_star ({object => 'o3', delta => 20,
                                account => 'a1', group => 'g1'});
  })->then (sub {
    return $current->get_json (['star', 'list.json'], {
      o => [$current->o ('o1')->{object_id},
            $current->o ('o2')->{object_id},
            'object-'.$current->o ('o3')->{object_id},
            623543444444,
            '2-623543444444',
            "abcde"],
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{items}}, 2;
      my $stars = $result->{json}->{items}->{$current->o ('o1')->{object_id}};
      is 0+@$stars, 1;
      is $stars->[0]->{author_account_id}, $current->o ('a1')->{account_id};
      is $stars->[0]->{type_id}, 0;
      is $stars->[0]->{count}, 30;
      my $stars2 = $result->{json}->{items}->{$current->o ('o2')->{object_id}};
      is 0+@$stars2, 1;
      is $stars2->[0]->{author_account_id}, $current->o ('a1')->{account_id};
      is $stars2->[0]->{type_id}, 0;
      is $stars2->[0]->{count}, 40;
      my $stars3 = $result->{json}->{items}->{$current->o ('o3')->{object_id}};
      is $stars3, undef;
    } $current->c;
  });
} n => 10, name => 'multiple targets';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {members => ['a1']}],
  )->then (sub {
    return $current->are_errors (
      ['GET', ['star', 'list.json'], {
      }, group => 'g1', account => 'a1'],
      [
        {account => undef, status => 403},
        {account => '', status => 403},
      ],
    );
  })->then (sub {
    return $current->get_json (['star', 'list.json'], {
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{items}}, 0;
    } $current->c;
  });
} n => 2, name => 'empty target';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {members => ['a1']}],
  )->then (sub {
    return $current->get_json (['star', 'list.json'], {
      o => rand,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{items}}, 0;
    } $current->c;
  });
} n => 1, name => 'bad target only';

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
