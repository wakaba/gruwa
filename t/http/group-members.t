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
    [a3 => account => {terms_version => 1}],
  )->then (sub {
    return $current->create_group (g1 => {});
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 1;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 0;
      is $member->{user_status}, 0;
      is $member->{owner_status}, 0;
      is $member->{group_index_id}, undef;
      is $member->{desc}, '';
    } $current->c;
    return $current->are_errors (
      ['POST', ['g', $current->o ('g1')->{group_id}, 'members', 'status.json'], {
         account_id => $current->o ('a1')->{account_id},
         user_status => 6,
       }, account => 'a1'],
      [
        {path => ['g', '00'.$current->o ('g1')->{group_id}, 'members', 'status.json'], status => 404},
        {account => undef, status => 403},
        {account => 'a3', status => 403},
        {params => {
          account_id => 5251133333,
          user_status => 6,
        }, status => 403, name => 'another user'},
        {params => {
          account_id => $current->o ('a2')->{account_id},
          user_status => 6,
        }, status => 403, name => 'another user'},
      ],
    );
  })->then (sub {
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'members', 'status.json'], {
      account_id => $current->o ('a1')->{account_id},
      member_type => 4,
      user_status => 3,
      owner_status => 1,
      desc => 'abcde',
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 1;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 0;
      is $member->{user_status}, 3;
      is $member->{owner_status}, 0;
      is $member->{group_index_id}, undef;
      is $member->{guide_object_id}, undef;
      is $member->{desc}, '';
    } $current->c, name => 'user_status changed';
  });
} n => 16, name => 'non-member';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [owner => account => {}],
    ['other member' => account => {}],
    [g1 => group => {
      owner => 'owner', members => ['a1', 'other member'],
    }],
    [o3 => object => {
      group => 'g1', account => 'owner',
    }],
  )->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 3, "name a1 and owner";
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 1;
      is $member->{user_status}, 1;
      is $member->{owner_status}, 1;
      is $member->{group_index_id}, undef;
      is $member->{desc}, '';
    } $current->c;
    return $current->are_errors (
      ['POST', ['g', $current->o ('g1')->{group_id}, 'members', 'status.json'], {
         account_id => $current->o ('a1')->{account_id},
         user_status => 6,
       }, account => 'a1'],
      [
        {account => undef, status => 403},
        {params => {
          account_id => 5251133333,
          user_status => 6,
        }, status => 403, name => 'another user'},
        {params => {
          account_id => $current->o ('a2')->{account_id},
          user_status => 6,
        }, status => 403, name => 'another user'},
        {params => {
          account_id => $current->o ('other member')->{account_id},
          user_status => 6,
        }, status => 403, name => 'another user'},
      ],
    );
  })->then (sub {
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'members', 'status.json'], {
      account_id => $current->o ('a1')->{account_id},
      member_type => 2,
      user_status => 1,
      owner_status => 3,
      desc => 'abcde',
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 3;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 1, "not changed";
      is $member->{user_status}, 1, "same value";
      is $member->{owner_status}, 1, "not changed";
      is $member->{group_index_id}, undef;
      is $member->{desc}, '', "not changed";
    } $current->c, name => 'not in fact changed';
  })->then (sub {
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'members', 'status.json'], {
      account_id => $current->o ('a1')->{account_id},
      user_status => 2, # closed
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 1;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 0;
      is $member->{user_status}, 2;
      is $member->{owner_status}, 1;
      is $member->{group_index_id}, undef;
      is $member->{desc}, '';
    } $current->c, name => 'changed (closed)';
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'members', 'status.json'], {
      account_id => $current->o ('a1')->{account_id},
      member_type => 2,
      user_status => 3,
      owner_status => 4,
      desc => "abc",
    }, account => 'owner');
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 1;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 0;
      is $member->{user_status}, 2;
      is $member->{owner_status}, 4;
      is $member->{group_index_id}, undef;
      is $member->{desc}, '';
    } $current->c, name => 'changed by owner';
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members', 'list.json'], {}, account => 'owner');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 3;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 2;
      is $member->{user_status}, 2;
      is $member->{owner_status}, 4;
      is $member->{group_index_id}, undef;
      is $member->{guide_object_id}, undef;
      is $member->{desc}, 'abc';
    } $current->c, name => 'changed by owner';
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'my', 'edit.json'], {
      guide_object_id => $current->o ('o3')->{object_id},
    }, account => 'other member');
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members', 'list.json'], {}, account => 'owner');
  })->then (sub {
    my $result = $_[0];
    test {
      my $member = $result->{json}->{members}->{$current->o ('other member')->{account_id}};
      is $member->{guide_object_id}, $current->o ('o3')->{object_id};
      like $result->{res}->body_bytes, qr{"guide_object_id"\s*:\s*"};
    } $current->c, name => 'guide';
  });
} n => 39, name => 'member';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_account (a2 => {});
  })->then (sub {
    return $current->create_account (owner => {});
  })->then (sub {
    return $current->create_account ("other member" => {});
  })->then (sub {
    return $current->create_group (g1 => {owners => ['a1', 'owner'],
                                          members => ['other member']});
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 3, "name a1 and owner";
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 2;
      is $member->{user_status}, 1;
      is $member->{owner_status}, 1;
      is $member->{group_index_id}, undef;
      is $member->{desc}, '';
    } $current->c;
    return $current->are_errors (
      ['POST', ['g', $current->o ('g1')->{group_id}, 'members', 'status.json'], {
         account_id => $current->o ('a1')->{account_id},
         user_status => 6,
       }, account => 'a1'],
      [
        {account => undef, status => 403},
        {account => 'other member', status => 403},
      ],
    );
  })->then (sub {
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'members', 'status.json'], {
      account_id => $current->o ('a1')->{account_id},
      member_type => 1,
      user_status => 1,
      owner_status => 3,
      desc => 'abcde',
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 3;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 2, "not changed";
      is $member->{user_status}, 1, "same value";
      is $member->{owner_status}, 1, "not changed";
      is $member->{group_index_id}, undef;
      is $member->{desc}, 'abcde', "a1 is owner";
    } $current->c, name => 'not in fact changed';
  })->then (sub {
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'members', 'status.json'], {
      account_id => $current->o ('a1')->{account_id},
      user_status => 2, # closed
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 3;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 2;
      is $member->{user_status}, 1;
      is $member->{owner_status}, 1;
      is $member->{group_index_id}, undef;
      is $member->{desc}, 'abcde';
    } $current->c, name => 'cannot be downgraded';
    return $current->are_errors (
      ['POST', ['g', $current->o ('g1')->{group_id}, 'members', 'status.json'], {
         account_id => $current->o ('a1')->{account_id},
         member_type => 2,
         user_status => 3,
         owner_status => 4,
         desc => "abc",
       }, account => 'owner'],
      [
        {origin => undef, status => 400},
        {origin => 'null', status => 400},
      ],
    );
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 3;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 2;
      is $member->{user_status}, 1;
      is $member->{owner_status}, 1;
      is $member->{group_index_id}, undef;
      is $member->{desc}, 'abcde';
    } $current->c, name => 'not changed';
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'members', 'status.json'], {
      account_id => $current->o ('a1')->{account_id},
      member_type => 2,
      user_status => 3,
      owner_status => 4,
      desc => "abc",
    }, account => 'owner');
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 1;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 0;
      is $member->{user_status}, 1;
      is $member->{owner_status}, 4;
      is $member->{group_index_id}, undef;
      is $member->{desc}, '';
    } $current->c, name => 'changed by owner';
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members', 'list.json'], {}, account => 'owner');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 3;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 2;
      is $member->{user_status}, 1;
      is $member->{owner_status}, 4;
      is $member->{group_index_id}, undef;
      is $member->{desc}, 'abc';
    } $current->c, name => 'changed by owner';
  });
} n => 44, name => 'owner';

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
