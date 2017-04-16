use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  my $site = 'https://' . rand . '.test/foo/';
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {});
  })->then (sub {
    return $current->are_errors (
      ['GET', ['imported', $site, 'list.json'], {}, group => 'g1', account => 'a1'],
      [
        {account => undef, status => 403},
        {account => {}, status => 403},
        {group => 'g2', status => 403},
        {path => ['imported', rand, 'list.json'], status => 404},
        {path => ['imported', 'null', 'list.json'], status => 404},
      ],
    );
  })->then (sub {
    return $current->get_json (['imported', $site, 'list.json'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 0;
    } $current->c;
  });
} n => 2, name => 'empty';

Test {
  my $current = shift;
  my $site = 'https://' . rand . '.test/foo/';
  my $page = $site . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
      source_page => $page,
      source_site => $site,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    $current->set_o (o1 => $_[0]->{json});
    return $current->get_json (['imported', $site, 'list.json'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item = $result->{json}->{items}->[0];
      is $item->{source_page}, $page;
      ok $item->{created};
      ok $item->{updated};
      is $item->{type}, 2;
      is $item->{dest_id}, $current->o ('o1')->{object_id};
      like $result->{res}->body_bytes, qr{"dest_id"\s*:\s*"};
      is $item->{sync_info}->{timestamp}, undef;
    } $current->c;
    return $current->get_json (['imported', $site, 'list.json'], {}, group => 'g2', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 0;
    } $current->c;
  });
} n => 9, name => 'an item';

Test {
  my $current = shift;
  my $site = 'https://' . rand . '.test/foo/';
  my $page1 = $site . rand;
  my $page2 = $site . rand;
  my $page3 = $site . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
      source_page => $page1,
      source_site => $site,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    $current->set_o (o1 => $_[0]->{json});
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
      source_page => $page2,
      source_site => $site,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    $current->set_o (o2 => $_[0]->{json});
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
      source_page => $page3,
      source_site => $site,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    $current->set_o (o3 => $_[0]->{json});
    return $current->are_errors (
      ['GET', ['imported', $site, 'list.json'], {
        limit => 2,
      }, group => 'g1', account => 'a1'],
      [
        {params => {ref => rand}, status => 400},
        {params => {limit => 1000000}, status => 400},
        {params => {ref => '+3,4499999'}, status => 400},
      ],
    );
  })->then (sub {
    return $current->get_json (['imported', $site, 'list.json'], {
      limit => 2,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 2;
      my $item1 = $result->{json}->{items}->[0];
      is $item1->{source_page}, $page3;
      my $item2 = $result->{json}->{items}->[1];
      is $item2->{source_page}, $page2;
      ok $result->{json}->{has_next};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['imported', $site, 'list.json'], {
      limit => 2,
      ref => $result->{json}->{next_ref},
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item1 = $result->{json}->{items}->[0];
      is $item1->{source_page}, $page1;
      ok ! $result->{json}->{has_next};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['imported', $site, 'list.json'], {
      limit => 2,
      ref => $result->{json}->{next_ref},
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 0;
      ok ! $result->{json}->{has_next};
      ok $result->{json}->{next_ref};
    } $current->c;
    return $current->get_json (['imported', $site, 'list.json'], {
      limit => 2,
      ref => $result->{json}->{next_ref},
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 0;
      ok ! $result->{json}->{has_next};
      ok $result->{json}->{next_ref};
    } $current->c;
  });
} n => 16, name => 'paging';

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
