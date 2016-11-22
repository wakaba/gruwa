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
    return $current->create_group (g1 => {title => "a\x{500}", owner => 'a1', members => ['a2']});
  })->then (sub {
    return $current->are_errors (
      ['GET', ['g', $current->o ('g1')->{group_id}, 'info.json'], {}, account => 'a1'],
      [
        {path => ['g', int rand 10000, 'members'], status => 404},
        {account => '', status => 403},
        {account => undef, status => 403},
      ],
    );
  })->then (sub {
    return $current->get_html (['g', $current->o ('g1')->{group_id}, 'members'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok 1;
    } $current->c;
    return $current->get_html (['g', $current->o ('g1')->{group_id}, 'members'], {}, account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      ok 1;
    } $current->c;
  });
} n => 3, name => '/g/{}/members';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_account (a2 => {});
  })->then (sub {
    return $current->create_group (g1 => {});
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 1;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 0;
      is $member->{user_status}, 0;
      is $member->{owner_status}, 0;
      is $member->{desc}, '';
    } $current->c;
    return $current->are_errors (
      ['POST', ['g', $current->o ('g1')->{group_id}, 'members.json'], {
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
      ],
    );
  })->then (sub {
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {
      account_id => $current->o ('a1')->{account_id},
      member_type => 4,
      user_status => 3,
      owner_status => 1,
      desc => 'abcde',
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 1;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 0;
      is $member->{user_status}, 3;
      is $member->{owner_status}, 0;
      is $member->{desc}, '';
    } $current->c, name => 'user_status changed';
  });
} n => 13, name => 'non-member';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_account (a2 => {});
  })->then (sub {
    return $current->create_account (owner => {});
  })->then (sub {
    return $current->create_account ("other member" => {});
  })->then (sub {
    return $current->create_group (g1 => {owner => 'owner', members => ['a1', 'other member']});
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 3, "name a1 and owner";
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 1;
      is $member->{user_status}, 1;
      is $member->{owner_status}, 1;
      is $member->{desc}, '';
    } $current->c;
    return $current->are_errors (
      ['POST', ['g', $current->o ('g1')->{group_id}, 'members.json'], {
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
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {
      account_id => $current->o ('a1')->{account_id},
      member_type => 2,
      user_status => 1,
      owner_status => 3,
      desc => 'abcde',
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 3;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 1, "not changed";
      is $member->{user_status}, 1, "same value";
      is $member->{owner_status}, 1, "not changed";
      is $member->{desc}, '', "not changed";
    } $current->c, name => 'not in fact changed';
  })->then (sub {
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {
      account_id => $current->o ('a1')->{account_id},
      user_status => 2, # closed
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 1;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 0;
      is $member->{user_status}, 2;
      is $member->{owner_status}, 1;
      is $member->{desc}, '';
    } $current->c, name => 'changed (closed)';
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {
      account_id => $current->o ('a1')->{account_id},
      member_type => 2,
      user_status => 3,
      owner_status => 4,
      desc => "abc",
    }, account => 'owner');
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 1;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 0;
      is $member->{user_status}, 2;
      is $member->{owner_status}, 4;
      is $member->{desc}, '';
    } $current->c, name => 'changed by owner';
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {}, account => 'owner');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 3;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 2;
      is $member->{user_status}, 2;
      is $member->{owner_status}, 4;
      is $member->{desc}, 'abc';
    } $current->c, name => 'changed by owner';
  });
} n => 31, name => 'member';

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
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 3, "name a1 and owner";
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 2;
      is $member->{user_status}, 1;
      is $member->{owner_status}, 1;
      is $member->{desc}, '';
    } $current->c;
    return $current->are_errors (
      ['POST', ['g', $current->o ('g1')->{group_id}, 'members.json'], {
         account_id => $current->o ('a1')->{account_id},
         user_status => 6,
       }, account => 'a1'],
      [
        {account => undef, status => 403},
        {account => 'other member', status => 403},
      ],
    );
  })->then (sub {
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {
      account_id => $current->o ('a1')->{account_id},
      member_type => 1,
      user_status => 1,
      owner_status => 3,
      desc => 'abcde',
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 3;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 2, "not changed";
      is $member->{user_status}, 1, "same value";
      is $member->{owner_status}, 1, "not changed";
      is $member->{desc}, 'abcde', "a1 is owner";
    } $current->c, name => 'not in fact changed';
  })->then (sub {
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {
      account_id => $current->o ('a1')->{account_id},
      user_status => 2, # closed
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 3;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 2;
      is $member->{user_status}, 1;
      is $member->{owner_status}, 1;
      is $member->{desc}, 'abcde';
    } $current->c, name => 'cannot be downgraded';
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {
      account_id => $current->o ('a1')->{account_id},
      member_type => 2,
      user_status => 3,
      owner_status => 4,
      desc => "abc",
    }, account => 'owner');
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 1;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 0;
      is $member->{user_status}, 1;
      is $member->{owner_status}, 4;
      is $member->{desc}, '';
    } $current->c, name => 'changed by owner';
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'members.json'], {}, account => 'owner');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{members}}, 3;
      my $member = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $member->{account_id}, $current->o ('a1')->{account_id};
      is $member->{member_type}, 2;
      is $member->{user_status}, 1;
      is $member->{owner_status}, 4;
      is $member->{desc}, 'abc';
    } $current->c, name => 'changed by owner';
  });
} n => 31, name => 'owner';

RUN;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

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
