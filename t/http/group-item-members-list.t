use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_account (a2 => {});
  })->then (sub {
    return $current->create_group (g1 => {owner => 'a1', members => ['a2']});
  })->then (sub {
    return $current->are_errors (
      ['GET', ['members', 'list.json'], {}, account => 'a1', group => 'g1'],
      [
        {path => ['g', '52564444', 'members', 'list.json'], status => 404},
        {path => ['g', '0'.$current->o ('g1')->{group_id}, 'members', 'list.json'], status => 404},
        {account => undef, status => 403},
      ],
    );
  });
} n => 1, name => '/g/{}/members/list.json errors';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_account (a2 => {});
  })->then (sub {
    return $current->create_group (g1 => {owner => 'a1', members => ['a2']});
  })->then (sub {
    return $current->post_json (['members', 'status.json'], {
      account_id => $current->o ('a2')->{account_id},
      owner_status => 2, # closed
    }, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['members', 'list.json'], {
    }, group => 'g1', account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      my $json = $result->{json};
      is 0+keys %{$json->{members}}, 1;
      my $item = $json->{members}->{$current->o ('a2')->{account_id}};
      is $item->{account_id}, $current->o ('a2')->{account_id};
      is $item->{user_status}, 1;
      is $item->{owner_status}, 2;
      is $item->{member_type}, 0;
    } $current->c;
  });
} n => 5, name => 'group member owner_status 2';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [g1 => group => {owners => ['a1'], members => ['a2']}],
  )->then (sub {
    return $current->post_json (['my', 'edit.json'], {
      name => $current->generate_text ('namea1' => {}),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->post_json (['my', 'edit.json'], {
      name => $current->generate_text ('namea2' => {}),
    }, account => 'a2', group => 'g1');
  })->then (sub {
    return $current->get_json (['members', 'list.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $mem1 = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $mem1->{name}, $current->o ('namea1');
      my $mem2 = $result->{json}->{members}->{$current->o ('a2')->{account_id}};
      is $mem2->{name}, $current->o ('namea2');
    } $current->c;
    return $current->post_json (['members', 'status.json'], {
      account_id => $current->o ('a2')->{account_id},
      owner_status => 2, # closed
    }, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['members', 'list.json'], {}, account => 'a2', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $mem2 = $result->{json}->{members}->{$current->o ('a2')->{account_id}};
      is $mem2->{name}, $current->o ('namea2');
    } $current->c, name => 'closed member still can see their own name';
  });
} n => 3, name => 'explicit account name';

RUN;

=head1 LICENSE

Copyright 2017-2019 Wakaba <wakaba@suikawiki.org>.

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
