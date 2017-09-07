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
    return $current->create_group (g2 => {owner => 'a1'});
  })->then (sub {
    return $current->create_invitation (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->are_errors (
      ['POST', ['members', 'invitations', $current->o ('i1')->{invitation_key}, 'invalidate.json'], {}, account => 'a1', group => 'g1'],
      [
        {path => ['g', '434355555', 'members', 'invitations', $current->o ('i1')->{invitation_key}, 'invalidate.json'], account => 'a1', group => undef, status => 404, name => 'Bad group_id'},
        {path => ['g', '000'.$current->o ('g1')->{group_id}, 'members', 'invitations', $current->o ('i1')->{invitation_key}, 'invalidate.json'], account => 'a1', group => undef, status => 404, name => 'Bad group_id'},
        {path => ['g', $current->o ('g2')->{group_id}, 'members', 'invitations', $current->o ('i1')->{invitation_key}, 'invalidate.json'], account => 'a1', group => undef, status => 404, name => 'Wrong group_id'},
        {path => ['g', $current->o ('g1')->{group_id}, 'members', 'invitations', '526532aawaaa', 'invalidate.json'], account => 'a1', group => undef, status => 404, name => 'Bad invitation_key'},
        {account => undef, status => 403, name => 'no account'},
        {account => '', status => 403, name => 'bad account'},
        {account => 'a2', status => 403, name => 'not owner'},
        {origin => undef, status => 400},
        {method => 'GET', status => 405},
      ],
    );
  })->then (sub {
    return $current->post_json (['members', 'invitations', $current->o ('i1')->{invitation_key}, 'invalidate.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok ref $result->{json}, 'HASH';
    } $current->c;
    return $current->get_json (['members', 'invitations', 'list.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $json = $result->{json};
      is 0+keys %{$json->{invitations}}, 1;
      my $inv2 = $json->{invitations}->{each %{$json->{invitations}}};
      is $inv2->{invitation_key}, $current->o ('i1')->{invitation_key};
      is $inv2->{expires}, $current->o ('i1')->{expires};
      is $inv2->{group_id}, $current->o ('g1')->{group_id};
      is $inv2->{author_account_id}, $current->o ('a1')->{account_id};
      is $inv2->{invitation_data}->{member_type}, 1; # normal
      ok $inv2->{created};
      is $inv2->{target_account_id}, '0';
      is $inv2->{user_account_id}, '0';
      is $inv2->{used_data}->{old_group_membership}, undef;
      is $inv2->{used_data}->{group_id}, $current->o ('g1')->{group_id};
      is $inv2->{used_data}->{operator_account_id}, $current->o ('a1')->{account_id};
      ok $inv2->{used} > $inv2->{created};
    } $current->c;
  });
} n => 15, name => 'invalidate';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_account (a2 => {});
  })->then (sub {
    return $current->create_group (g1 => {owner => 'a1'});
  })->then (sub {
    return $current->create_group (g2 => {owner => 'a1'});
  })->then (sub {
    return $current->create_invitation (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_redirect (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => 'a2');
  })->then (sub {
    return $current->are_errors (['POST', ['members', 'invitations', $current->o ('i1')->{invitation_key}, 'invalidate.json'], {}, account => 'a1', group => 'g1'], [{status => 404}]);
  })->then (sub {
    return $current->get_json (['members', 'invitations', 'list.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $json = $result->{json};
      is 0+keys %{$json->{invitations}}, 1;
      my $inv2 = $json->{invitations}->{each %{$json->{invitations}}};
      is $inv2->{invitation_key}, $current->o ('i1')->{invitation_key};
      is $inv2->{expires}, $current->o ('i1')->{expires};
      is $inv2->{group_id}, $current->o ('g1')->{group_id};
      is $inv2->{author_account_id}, $current->o ('a1')->{account_id};
      is $inv2->{invitation_data}->{member_type}, 1; # normal
      ok $inv2->{created};
      is $inv2->{target_account_id}, '0';
      is $inv2->{user_account_id}, $current->o ('a2')->{account_id};
      is $inv2->{used_data}->{old_group_membership}, undef;
      is $inv2->{used_data}->{group_id}, $current->o ('g1')->{group_id};
      ok $inv2->{used} > $inv2->{created};
    } $current->c;
  });
} n => 13, name => 'invalidate used invitation';

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
