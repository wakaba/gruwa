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
    return $current->create_account (a3 => {});
  })->then (sub {
    return $current->create_group (g1 => {title => "a\x{500}", owner => 'a1', members => ['a3']});
  })->then (sub {
    return $current->are_errors (
      ['GET', ['g', $current->o ('g1')->{group_id}, 'info.json'], {}, account => 'a1'],
      [
        {path => ['g', int rand 10000, 'info.json'], status => 404},
        {account => '', status => 403},
        {account => undef, status => 403},
      ],
    );
  })->then (sub {
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'info.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{status}, 200;
      is $result->{json}->{group_id}, $current->o ('g1')->{group_id};
      like $result->{res}->body_bytes, qr{"group_id"\s*:\s*"};
      is $result->{json}->{title}, "a\x{500}";
    } $current->c;
    return $current->get_json (['g', $current->o ('g1')->{group_id}, 'info.json'], {}, account => 'a3');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{status}, 200;
      is $result->{json}->{group_id}, $current->o ('g1')->{group_id};
      like $result->{res}->body_bytes, qr{"group_id"\s*:\s*"};
      is $result->{json}->{title}, "a\x{500}";
    } $current->c;
  });
} n => 9, name => '/g/{}/info.json';

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