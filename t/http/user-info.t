use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  my $name = rand;
  return $current->create_account (u1 => {
    name => $name,
  })->then (sub {
    return $current->get_json (['u', 'info.json'], {
      account_id => $current->o ('u1')->{account_id},
    });
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{accounts}}, 1;
      my $u = $result->{json}->{accounts}->{$current->o ('u1')->{account_id}};
      is $u->{account_id}, $current->o ('u1')->{account_id};
      is $u->{name}, $name;
      like $result->{res}->body_bytes, qr{"account_id"\s*:\s*"};
    } $current->c;
  });
} n => 4, name => '/u/info.json';

Test {
  my $current = shift;
  my $name = rand;
  my $name2 = rand;
  return $current->create_account (u1 => {
    name => $name,
  })->then (sub {
    return $current->create_account (u2 => {
      name => $name2,
    });
  })->then (sub {
    return $current->get_json (['u', 'info.json'], {
      account_id => [$current->o ('u1')->{account_id},
                     53232323333,
                     $current->o ('u2')->{account_id}],
    });
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{accounts}}, 2;
      my $u = $result->{json}->{accounts}->{$current->o ('u1')->{account_id}};
      is $u->{account_id}, $current->o ('u1')->{account_id};
      is $u->{name}, $name;
      my $u2 = $result->{json}->{accounts}->{$current->o ('u2')->{account_id}};
      is $u2->{account_id}, $current->o ('u2')->{account_id};
      is $u2->{name}, $name2;
      like $result->{res}->body_bytes, qr{"account_id"\s*:\s*"};
    } $current->c;
  });
} n => 6, name => '/u/info.json';

Test {
  my $current = shift;
  return $current->get_json (['u', 'info.json'], {
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{accounts}}, 0;
    } $current->c;
  });
} n => 1, name => '/u/info.json';

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
