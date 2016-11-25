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
    return $current->create_index (i1 => {group => 'g1', account => 'a1', title => "\x{900}"});
  })->then (sub {
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'my.json'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['members.json'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{members}->{$current->o ('a1')->{account_id}}->{default_index_id}, undef;
    } $current->c;
  });
} n => 1, name => 'nop';

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
      ['POST', ['i', $current->o ('i1')->{index_id}, 'my.json'], {
        is_default => 1,
      }, group => 'g1', account => 'a1'],
      [
        {path => ['i', '435444', ''], status => 404},
        {group => 'g2', status => 404},
        {account => undef, status => 403},
        {account => '', status => 403},
        {method => 'GET', status => 405},
        {origin => undef, status => 400},
        {origin => 'null', status => 400},
      ],
    );
  })->then (sub {
    return $current->get_json (['members.json'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{members}->{$current->o ('a1')->{account_id}}->{default_index_id}, undef;
    } $current->c;
  })->then (sub {
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'my.json'], {is_default => 1}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['members.json'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{members}->{$current->o ('a1')->{account_id}}->{default_index_id}, $current->o ('i1')->{index_id};
      like $result->{res}->body_bytes, qr{"default_index_id"\s*:\s*"};
    } $current->c;
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'my.json'], {is_default => ''}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['members.json'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{members}->{$current->o ('a1')->{account_id}}->{default_index_id}, undef;
    } $current->c;
  });
} n => 5, name => 'default changed';

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
