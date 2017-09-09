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
    return $current->create_account (anew => {});
  })->then (sub {
    return $current->create_group (g1 => {owner => 'a1', members => ['a2']});
  })->then (sub {
    return $current->are_errors (
      ['POST', ['members', 'invitations', 'create.json'], {
      }, account => 'a1', group => 'g1'],
      [
        {path => ['g', int rand 10000, 'members', 'invitations', 'create.json'], group => undef, status => 404},
        {account => undef, status => 403, name => 'no account'},
        {account => '', status => 403, name => 'not a member'},
        {account => 'a2', status => 403, name => 'normal member'},
        {method => 'GET', status => 405},
        {origin => undef, status => 400},
      ],
    );
  })->then (sub {
    return $current->post_json (['members', 'invitations', 'create.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    my $inv = $result->{json};
    test {
      is $inv->{group_id}, $current->o ('g1')->{group_id};
      like $result->{res}->body_bytes, qr{"group_id"\s*:\s*"};
      ok $inv->{invitation_key};
      like $result->{res}->body_bytes, qr{"invitation_key"\s*:\s*"};
      is $inv->{invitation_url},
         $current->resolve ('/invitation/' . $current->o ('g1')->{group_id} . '/' . $inv->{invitation_key} . '/')->stringify;
      ok $inv->{expires} > time;
    } $current->c;
    # XXX invitation_url is 200

    return $current->get_json (['members', 'invitations', 'list.json'], {
    }, account => 'a1', group => 'g1')->then (sub {
      my $result = $_[0];
      test {
        my $json = $result->{json};
        is 0+keys %{$json->{invitations}}, 1;
        my $inv2 = $json->{invitations}->{each %{$json->{invitations}}};
        is $inv2->{invitation_key}, $inv->{invitation_key};
        is $inv2->{expires}, $inv->{expires};
        is $inv2->{group_id}, $inv->{group_id};
        is $inv2->{author_account_id}, $current->o ('a1')->{account_id};
        is $inv2->{invitation_data}->{member_type}, 1; # normal
        ok $inv2->{created};
        is $inv2->{target_account_id}, '0';
        is $inv2->{user_account_id}, '0';
        is $inv2->{used_data}, undef;
        is $inv2->{used}, 0;
      } $current->c;
    });
  });
} n => 18, name => 'create.json';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_account (a2 => {});
  })->then (sub {
    return $current->create_account (anew => {});
  })->then (sub {
    return $current->create_group (g1 => {owner => 'a1', members => ['a2']});
  })->then (sub {
    return $current->post_json (['members', 'invitations', 'create.json'], {
      member_type => 2, # owner
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    my $inv = $result->{json};
    test {
      is $inv->{group_id}, $current->o ('g1')->{group_id};
      like $result->{res}->body_bytes, qr{"group_id"\s*:\s*"};
      ok $inv->{invitation_key};
      like $result->{res}->body_bytes, qr{"invitation_key"\s*:\s*"};
      is $inv->{invitation_url},
         $current->resolve ('/invitation/' . $current->o ('g1')->{group_id} . '/' . $inv->{invitation_key} . '/')->stringify;
      ok $inv->{expires} > time;
    } $current->c;
    # XXX invitation_url is 200

    return $current->get_json (['members', 'invitations', 'list.json'], {
    }, account => 'a1', group => 'g1')->then (sub {
      my $result = $_[0];
      test {
        my $json = $result->{json};
        is 0+keys %{$json->{invitations}}, 1;
        my $inv2 = $json->{invitations}->{each %{$json->{invitations}}};
        is $inv2->{invitation_key}, $inv->{invitation_key};
        is $inv2->{expires}, $inv->{expires};
        is $inv2->{group_id}, $inv->{group_id};
        is $inv2->{author_account_id}, $current->o ('a1')->{account_id};
        is $inv2->{invitation_data}->{member_type}, 2; # owner
        ok $inv2->{created};
        is $inv2->{target_account_id}, '0';
        is $inv2->{user_account_id}, '0';
        is $inv2->{used_data}, undef;
        is $inv2->{used}, 0;
      } $current->c;
    });
  });
} n => 17, name => 'create.json member_type=owner';

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
