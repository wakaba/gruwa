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
    return $current->are_errors (
      ['POST', ['i', 'create.json'], {
         title => "\x{500}",
       }, account => 'a1', group => $current->o ('g1')],
      [
        {method => 'GET', status => 405},
        {path => ['g', '5445444', 'i', 'create.json'], group => undef, status => 404},
        {origin => undef, status => 400, name => 'no origin'},
        {origin => 'null', status => 400, name => 'null origin'},
        {account => undef, status => 403, name => 'no account'},
        {account => '', status => 403, name => 'not member'},
        {params => {title => ''}, status => 400, name => 'Empty title'},
        {params => {title => undef}, status => 400, name => 'No title'},
      ],
    );
  })->then (sub {
    return $current->post_json (['i', 'create.json'], {
      title => "\x{500}",
    }, account => 'a1', group => $current->o ('g1'));
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{group_id}, $current->o ('g1')->{group_id};
      ok $result->{json}->{index_id};
      like $result->{res}->body_bytes, qr{"group_id"\s*:\s*"};
      like $result->{res}->body_bytes, qr{"index_id"\s*:\s*"};
    } $current->c;
    return $current->index ({group_id => $current->o ('g1')->{group_id},
                             index_id => $result->{json}->{index_id}},
                            account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{title}, "\x{500}";
      ok $index->{created};
      is $index->{updated}, $index->{created};
    } $current->c;
  });
} n => 8, name => 'create';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->post_json (['i', 'create.json'], {
      index_type => 2,
      title => rand,
    }, account => 'a1', group => $current->o ('g1'));
  })->then (sub {
    return $current->index ($_[0]->{json}, account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{index_type}, 2;
    } $current->c;
  });
} n => 1, name => 'create with index_id';

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
