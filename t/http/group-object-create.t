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
    return $current->create_index (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->are_errors (
      ['POST', ['o', 'create.json'], {}, account => 'a1', group => 'g1'],
      [
        {method => 'GET', status => 405},
        {origin => 'null', status => 400},
        {account => '', status => 403},
        {account => undef, status => 403},
        {path => ['g', '532523', 'o', 'create.json'], status => 404},
      ],
    );
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{group_id}, $current->o ('g1')->{group_id};
      ok $result->{json}->{object_id};
      ok $result->{json}->{object_revision_id};
      is $result->{json}->{upload_token}, undef;
      like $result->{res}->body_bytes, qr{"group_id"\s*:\s*"};
      like $result->{res}->body_bytes, qr{"object_id"\s*:\s*"};
      like $result->{res}->body_bytes, qr{"object_revision_id"\s*:\s*"};
    } $current->c;
    $current->set_o (o1 => $result->{json});
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $obj = $_[0];
    test {
      is $obj->{group_id}, $current->o ('g1')->{group_id};
      is $obj->{title}, '';
      is $obj->{data}->{title}, '';
      is $obj->{data}->{object_revision_id}, $current->o ('o1')->{object_revision_id};
      is $obj->{data}->{thread_id}, $current->o ('o1')->{object_id};
      ok $obj->{created};
      is $obj->{updated}, $obj->{created};
      is $obj->{timestamp}, $obj->{created};
    } $current->c;
    return $current->object ($current->o ('o1'), account => 'a1', revision => 1);
  })->then (sub {
    my $obj = $_[0];
    test {
      is $obj->{group_id}, $current->o ('g1')->{group_id};
      is $obj->{title}, '';
      is $obj->{data}->{title}, '';
      is $obj->{data}->{object_revision_id}, $current->o ('o1')->{object_revision_id};
      ok $obj->{created};
      is $obj->{updated}, $obj->{created};
      is $obj->{timestamp}, $obj->{created};
      is $obj->{revision_data}->{changes}->{action}, 'new';
      is $obj->{revision_author_account_id}, $current->o ('a1')->{account_id};
    } $current->c;
  });
} n => 25, name => 'create object';

RUN;

=head1 LICENSE

Copyright 2016-2017 Wakaba <wakaba@suikawiki.org>.

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
