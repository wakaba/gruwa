use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->get_json (['my', 'groups.json'])->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{groups}}, 0;
    } $current->c;
  });
} n => 1, name => 'no account';

Test {
  my $current = shift;
  return $current->create_account (u1 => {terms_version => 1})->then (sub {
    return $current->get_json (['my', 'groups.json'], {}, account => 'u1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{groups}}, 0;
    } $current->c;
  });
} n => 1, name => 'terms_version bad';

Test {
  my $current = shift;
  return $current->create_account (u1 => {})->then (sub {
    return $current->get_json (['my', 'groups.json'], {}, account => 'u1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{groups}}, 0;
    } $current->c;
  });
} n => 1, name => 'no group';

Test {
  my $current = shift;
  return $current->create_account (u1 => {})->then (sub {
    return $current->create_group (g1 => {owner => 'u1', title => "\x{500}"});
  })->then (sub {
    return $current->create_group (g2 => {members => ['u1'], title => "\x{600}"});
  })->then (sub {
    return $current->get_json (['my', 'groups.json'], {}, account => 'u1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{groups}}, 2;
      my $g1 = $result->{json}->{groups}->{$current->o ('g1')->{group_id}};
      is $g1->{group_id}, $current->o ('g1')->{group_id};
      is $g1->{member_type}, 2;
      is $g1->{user_status}, 1;
      is $g1->{owner_status}, 1;
      is $g1->{title}, "\x{500}";
      is $g1->{default_index_id}, undef;
      my $g2 = $result->{json}->{groups}->{$current->o ('g2')->{group_id}};
      is $g2->{group_id}, $current->o ('g2')->{group_id};
      is $g2->{member_type}, 1;
      is $g2->{user_status}, 1;
      is $g2->{owner_status}, 1;
      is $g2->{title}, "\x{600}";
      is $g2->{default_index_id}, undef;
      ok $g2->{updated};
      like $result->{res}->body_bytes, qr{"group_id"\s*:\s*"};
    } $current->c;
    return $current->create_index (i1 => {group => 'g1', account => 'u1'});
  })->then (sub {
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'my.json'], {is_default => 1}, group => 'g1', account => 'u1');
  })->then (sub {
    return $current->get_json (['my', 'groups.json'], {}, account => 'u1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $g1 = $result->{json}->{groups}->{$current->o ('g1')->{group_id}};
      is $g1->{default_index_id}, $current->o ('i1')->{index_id};
      my $g2 = $result->{json}->{groups}->{$current->o ('g2')->{group_id}};
      is $g2->{default_index_id}, undef;
      like $result->{res}->body_bytes, qr{"default_index_id"\s*:\s*"};
      like $result->{res}->body_bytes, qr{"group_id"\s*:\s*"};
    } $current->c;
  });
} n => 19, name => 'has groups';

Test {
  my $current = shift;
  return $current->create_account (u1 => {})->then (sub {
    return $current->create_group (g1 => {});
  })->then (sub {
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'members', 'status.json'], {
      account_id => $current->o ('u1')->{account_id},
      user_status => 1, # open
    }, account => 'u1');
  })->then (sub {
    return $current->get_json (['my', 'groups.json'], {}, account => 'u1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{groups}}, 0;
      #my $g1 = $result->{json}->{groups}->{$current->o ('g1')->{group_id}};
      #is $g1->{group_id}, $current->o ('g1')->{group_id};
      #is $g1->{member_type}, 0;
      #is $g1->{user_status}, 1;
      #is $g1->{owner_status}, 0;
      #is $g1->{default_index_id}, undef;
      #is $g1->{title}, undef;
    } $current->c;
  });
} n => 1, name => 'not member';

Test {
  my $current = shift;
  return $current->create_account (u1 => {})->then (sub {
    return $current->create_account (u2 => {});
  })->then (sub {
    return $current->create_group (g1 => {members => ['u1'], owner => 'u2'});
  })->then (sub {
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'members', 'status.json'], {
      account_id => $current->o ('u1')->{account_id},
      owner_status => 2, # closed
    }, account => 'u2');
  })->then (sub {
    return $current->get_json (['my', 'groups.json'], {}, account => 'u1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{groups}}, 0;
      #my $g1 = $result->{json}->{groups}->{$current->o ('g1')->{group_id}};
      #is $g1->{group_id}, $current->o ('g1')->{group_id};
      #is $g1->{member_type}, 0;
      #is $g1->{user_status}, 1;
      #is $g1->{owner_status}, 0;
      #is $g1->{default_index_id}, undef;
      #is $g1->{title}, undef;
    } $current->c;
  });
} n => 1, name => 'no longer member';

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
