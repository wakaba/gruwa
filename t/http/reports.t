use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  my $now = time;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {members => ['a1']}],
  )->then (sub {
    return $current->post_json (['reports', 'heartbeat'], {
    });
  })->then (sub {
    return $current->get_json (['reports', 'requests.json'], {
      group_id => [$current->o ('g1')->{group_id}],
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $req = [grep {
        $_->{account_id} eq $current->o ('a1')->{account_id};
      } @{$result->{json}->{items}}]->[0];
      ok $req->{next_report_after} >= $now;
      $current->set_o (req1 => $req);
    } $current->c;
    return $current->create (
      [i1 => index => {group => 'g1', account => 'a1'}],
    );
  })->then (sub {
    return $current->post_json (['reports', 'heartbeat'], {
    });
  })->then (sub {
    return $current->get_json (['reports', 'requests.json'], {
      group_id => [$current->o ('g1')->{group_id}],
    });
  })->then (sub {
    my $result = $_[0];
    test {
      my $req = [grep {
        $_->{account_id} eq $current->o ('a1')->{account_id};
      } @{$result->{json}->{items}}]->[0];
      is $req->{next_report_after}, $current->o ('req1')->{next_report_after};
      ok $req->{touch_timestamp} > $current->o ('req1')->{touch_timestamp};
    } $current->c, name => 'new touch before reporting';
  });
} n => 3, name => 'report';

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
