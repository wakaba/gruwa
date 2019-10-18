use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->get_json (['account', 'email', 'list.json'])->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 0;
    } $current->c;
  });
} n => 1, name => 'no account';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
  )->then (sub {
    return $current->get_json (['account', 'email', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 0;
    } $current->c;
  });
} n => 1, name => 'empty list';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {
      email => [
        $current->generate_email_addr (d1 => {}),
        $current->generate_email_addr (d2 => {}),
      ],
    }],
  )->then (sub {
    return $current->get_json (['account', 'email', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 2;
      is join ($;, sort { $a cmp $b } map { $_->{addr} } @{$result->{json}->{items}}),
         join ($;, sort { $a cmp $b } $current->o ('d1'), $current->o ('d2'));
      ok $result->{json}->{items}->[0]->{account_link_id};
      like $result->{res}->body_bytes, qr{"account_link_id"\s*:\s*"};
    } $current->c;
  });
} n => 4, name => 'non-empty list';

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
