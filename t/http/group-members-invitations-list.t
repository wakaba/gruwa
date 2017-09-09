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
      ['POST', ['members', 'invitations', 'list.json'], {
      }, account => 'a1', group => 'g1'],
      [
        {path => ['g', int rand 10000, 'members', 'invitations', 'list.json'], group => undef, status => 404},
        {path => ['g', '000' . $current->o ('g1')->{group_id}, 'members', 'invitations', 'list.json'], group => undef, status => 404},
        {account => undef, status => 403, name => 'no account'},
        {account => '', status => 403, name => 'not a member'},
        {account => 'a2', status => 403, name => 'normal member'},
      ],
    );
  })->then (sub {
    return $current->get_json (['members', 'invitations', 'list.json'], {
    }, account => 'a1', group => 'g1')->then (sub {
      my $result = $_[0];
      test {
        my $json = $result->{json};
        is 0+keys %{$json->{invitations}}, 0;
        is $json->{next_ref}, undef;
      } $current->c;
    });
  });
} n => 3, name => 'list.json empty';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_account (a2 => {});
  })->then (sub {
    return $current->create_account (anew => {});
  })->then (sub {
    return $current->create_group (g1 => {owner => 'a1', members => ['a2']});
  })->then (sub {
    return $current->create_invitation (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->get_json (['members', 'invitations', 'list.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $json = $result->{json};
      is 0+keys %{$json->{invitations}}, 1;
      my $inv2 = $json->{invitations}->{each %{$json->{invitations}}};
      ok $inv2->{invitation_key};
      is $inv2->{invitation_url},
         $current->resolve ("/invitation/$inv2->{group_id}/$inv2->{invitation_key}/")->stringify;
      ok $inv2->{expires} > time;
      is $inv2->{group_id}, $current->o ('g1')->{group_id};
      is $inv2->{author_account_id}, $current->o ('a1')->{account_id};
      is $inv2->{invitation_data}->{member_type}, 1; # normal
      ok $inv2->{created};
      is $inv2->{target_account_id}, '0';
      is $inv2->{user_account_id}, '0';
      is $inv2->{used_data}, undef;
      is $inv2->{used}, 0;
    } $current->c;
  });
} n => 12, name => 'list.json';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_account (a2 => {});
  })->then (sub {
    return $current->create_account (anew => {});
  })->then (sub {
    return $current->create_group (g1 => {owner => 'a1', members => ['a2']});
  })->then (sub {
    return $current->create_invitation (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_invitation (i2 => {group => 'g1', account => 'a1',
                                               member_type => 2});
  })->then (sub {
    return $current->create_invitation (i3 => {group => 'g1', account => 'a1',
                                               member_type => 3});
  })->then (sub {
    return $current->create_invitation (i4 => {group => 'g1', account => 'a1',
                                               member_type => 4});
  })->then (sub {
    return $current->create_invitation (i5 => {group => 'g1', account => 'a1',
                                               member_type => 5});
  })->then (sub {
    return $current->are_errors (
      ['POST', ['members', 'invitations', 'list.json'], {
      }, account => 'a1', group => 'g1'],
      [
        {params => {limit => -2}, status => 400},
        {params => {ref => "abc"}, status => 400},
      ],
    );
  })->then (sub {
    return $current->get_json (['members', 'invitations', 'list.json'], {
      limit => 2,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $json = $result->{json};
      is 0+keys %{$json->{invitations}}, 2;
      my $found = {};
      $found->{$_->{invitation_data}->{member_type}} = 1
          for values %{$json->{invitations}};
      ok $found->{4};
      ok $found->{5};
    } $current->c;
    return $current->get_json (['members', 'invitations', 'list.json'], {
      limit => 2,
      ref => $result->{json}->{next_ref},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $json = $result->{json};
      is 0+keys %{$json->{invitations}}, 2;
      my $found = {};
      $found->{$_->{invitation_data}->{member_type}} = 1
          for values %{$json->{invitations}};
      ok $found->{2};
      ok $found->{3};
    } $current->c;
    return $current->get_json (['members', 'invitations', 'list.json'], {
      limit => 2,
      ref => $result->{json}->{next_ref},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $json = $result->{json};
      is 0+keys %{$json->{invitations}}, 1;
      my $found = {};
      $found->{$_->{invitation_data}->{member_type}} = 1
          for values %{$json->{invitations}};
      ok $found->{1};
    } $current->c;
    return $current->get_json (['members', 'invitations', 'list.json'], {
      limit => 2,
      ref => $result->{json}->{next_ref},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $json = $result->{json};
      is 0+keys %{$json->{invitations}}, 0;
    } $current->c;
  });
} n => 10, name => 'list.json paging';

RUN;

=head1 LICENSE

Copyright 2017 Wakaba <wakaba@suikawiki.org>.

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
