use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {members => ['a1']}],
    [g2 => group => {members => ['a1']}],
    [o1 => object => {group => 'g1', account => 'a1'}],
  )->then (sub {
    return $current->get_json (['o', $current->o ('o1')->{object_id}, 'revisions.json'], {
      with_revision_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok 0+@{$result->{json}->{items}};
      ok ! $result->{json}->{has_next};
      ok $result->{json}->{next_ref};
      my $first = $result->{json}->{items}->[-1];
      is $first->{object_revision_id}, $current->o ('o1')->{object_revision_id};
      like $result->{res}->body_bytes, qr{"object_revision_id"\s*:\s*"};
      is $first->{author_account_id}, $current->o ('a1')->{account_id};
      like $result->{res}->body_bytes, qr{"author_account_id"\s*:\s*"};
      ok $first->{created};
      is $first->{owner_status}, 1, "open";
      is $first->{user_status}, 1, "open";
      is $first->{revision_data}->{changes}->{action}, 'new';
    } $current->c;
    return $current->get_json (['o', $current->o ('o1')->{object_id}, 'revisions.json'], {
      #with_revision_data => 0,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok 0+@{$result->{json}->{items}};
      ok ! $result->{json}->{has_next};
      ok $result->{json}->{next_ref};
      my $first = $result->{json}->{items}->[-1];
      is $first->{object_revision_id}, $current->o ('o1')->{object_revision_id};
      is $first->{author_account_id}, $current->o ('a1')->{account_id};
      ok $first->{created};
      is $first->{owner_status}, 1, "open";
      is $first->{user_status}, 1, "open";
      is $first->{revision_data}, undef;
    } $current->c;
    return $current->are_errors (
      ['GET', ['o', $current->o ('o1')->{object_id}, 'revisions.json'], {}, group => 'g1', account => 'a1'],
      [
        {group => 'g2', status => 404},
        {path => ['o', '5325253333', 'revisions.json'], status => 404},
        {account => '', status => 403},
        {account => undef, status => 403},
      ],
    );
  });
} n => 21, name => 'revisions';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {members => ['a1']}],
    [g2 => group => {members => ['a1']}],
    [o1 => object => {group => 'g1', account => 'a1'}],
  )->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      title => $current->generate_text (t1 => {}),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    $current->set_o (rev1 => $_[0]->{json});
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      title => $current->generate_text (t2 => {}),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    $current->set_o (rev2 => $_[0]->{json});
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      title => $current->generate_text (t3 => {}),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    $current->set_o (rev3 => $_[0]->{json});
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      title => $current->generate_text (t4 => {}),
    }, account => 'a1', group => 'g1');
  })->then (sub {
    $current->set_o (rev4 => $_[0]->{json});
    return $current->get_json (['o', $current->o ('o1')->{object_id}, 'revisions.json'], {
      limit => 2,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 2;
      ok $result->{json}->{has_next};
      ok $result->{json}->{next_ref};
      is $result->{json}->{items}->[0]->{object_revision_id},
         $current->o ('rev4')->{object_revision_id};
      is $result->{json}->{items}->[1]->{object_revision_id},
         $current->o ('rev3')->{object_revision_id};
    } $current->c;
    return $current->get_json (['o', $current->o ('o1')->{object_id}, 'revisions.json'], {
      limit => 2,
      ref => $result->{json}->{next_ref},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 2;
      ok $result->{json}->{has_next};
      ok $result->{json}->{next_ref};
      is $result->{json}->{items}->[0]->{object_revision_id},
         $current->o ('rev2')->{object_revision_id};
      is $result->{json}->{items}->[1]->{object_revision_id},
         $current->o ('rev1')->{object_revision_id};
    } $current->c;
    return $current->are_errors (
      ['GET', ['o', $current->o ('o1')->{object_id}, 'revisions.json'], {
      }, account => 'a1', group => 'g1'],
      [
        {params => {ref => rand}, status => 400},
        {params => {ref => '+54,422299922'}, status => 400},
      ],
    );
  });
} n => 11, name => 'pages';

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
