use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1', title => "\x{900}"});
  })->then (sub {
    return $current->are_errors (
      ['GET', ['i', $current->o ('i1')->{index_id}, ''], {}, group => 'g1', account => 'a1'],
      [
        {path => ['i', '435444', ''], status => 404},
        {group => 'g2', status => 404},
        {account => undef, status => 302},
        {account => '', status => 403},
      ],
    );
  })->then (sub {
    return $current->get_html (['i', $current->o ('i1')->{index_id}, ''], {}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->are_errors (
      ['GET', ['i', $current->o ('i1')->{index_id}, 'info.json'], {}, group => 'g1', account => 'a1'],
      [
        {path => ['i', '435444', 'info.json'], status => 404},
        {group => 'g2', status => 404},
        {account => undef, status => 403},
        {account => '', status => 403},
      ],
    );
  })->then (sub {
    return $current->get_json (['i', $current->o ('i1')->{index_id}, 'info.json'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{group_id}, $current->o ('g1')->{group_id};
      is $result->{json}->{index_id}, $current->o ('i1')->{index_id};
      is $result->{json}->{title}, "\x{900}";
      ok $result->{json}->{created};
      is $result->{json}->{updated}, $result->{json}->{created};
      like $result->{res}->body_bytes, qr{"group_id"\s*:\s*"};
      like $result->{res}->body_bytes, qr{"index_id"\s*:\s*"};
    } $current->c;
  });
} n => 9, name => 'info';

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
