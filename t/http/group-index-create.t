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
      is $index->{theme}, 'green';
    } $current->c;
  });
} n => 2, name => 'create with index_id';

Test {
  my $current = shift;
  my $title = "\x{63245}" . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->post_json (['i', 'create.json'], {
      index_type => 6,
      title => $title,
      subtype => 'image',
    }, account => 'a1', group => $current->o ('g1'));
  })->then (sub {
    return $current->index ($_[0]->{json}, account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{index_type}, 6;
      is $index->{title}, $title;
      is $index->{subtype}, 'image';
    } $current->c;
  });
} n => 3, name => 'create an image album';

Test {
  my $current = shift;
  my $site = 'https://' . rand . '.test/foo/';
  my $page = $site . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->are_errors (
      ['POST', ['i', 'create.json'], {
        index_type => 6,
        title => $current->generate_text,
        source_page => $page,
        source_site => $site,
      }, account => 'a1', group => 'g1'],
      [
        {params => {
          index_type => 6,
          title => $current->generate_text,
          #source_page => $page,
          source_site => $site,
        }, status => 400},
        {params => {
          index_type => 6,
          title => $current->generate_text,
          source_page => $page,
          #source_site => $site,
        }, status => 400},
        {params => {
          index_type => 6,
          title => $current->generate_text,
          source_page => rand,
          source_site => $site,
        }, status => 400},
        {params => {
          index_type => 6,
          title => $current->generate_text,
          source_page => $page,
          source_site => rand,
        }, status => 400},
        {params => {
          index_type => 6,
          title => $current->generate_text,
          source_page => $page,
          source_site => 'https://test',
        }, status => 400},
      ],
    );
  })->then (sub {
    return $current->post_json (['i', 'create.json'], {
      index_type => 6,
      title => $current->generate_text,
      source_page => $page,
      source_site => $site,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    $current->set_o (i1 => $_[0]->{json});
    return $current->get_json (['imported', $site, 'list.json'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item = $result->{json}->{items}->[0];
      is $item->{source_page}, $page;
      ok $item->{created};
      ok $item->{updated};
      is $item->{type}, 1;
      is $item->{dest_id}, $current->o ('i1')->{index_id};
      like $result->{res}->body_bytes, qr{"dest_id"\s*:\s*"};
      is ref $item->{sync_info}, 'HASH';
    } $current->c;
  });
} n => 9, name => 'create with source';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->post_json (['i', 'create.json'], {
      title => "\x{500}",
      theme => 'abcdef',
      index_type => 3,
    }, account => 'a1', group => $current->o ('g1'));
  })->then (sub {
    my $result = $_[0];
    return $current->index ({group_id => $current->o ('g1')->{group_id},
                             index_id => $result->{json}->{index_id}},
                            account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{title}, "\x{500}";
      is $index->{theme}, 'abcdef';
    } $current->c;
  });
} n => 2, name => 'create with theme';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {owner => 'a1'}],
  )->then (sub {
    return $current->post_json (['i', 'create.json'], {
      title => $current->generate_text (t1 => {}),
      theme => 'blue',
      index_type => 2,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    $current->set_o (i1 => $result->{json});
    return $current->get_json (['info.json'], {}, account => 'a1', group => 'g1', index => 'i1');
  })->then (sub {
    my $result = $_[0];
    $current->set_o (oid1 => $result->{json}->{object_id});
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('oid1'),
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    my $obj = $result->{json}->{objects}->{$current->o ('oid1')};
    test {
      ok $obj->{data}->{object_revision_id};
      is $obj->{data}->{body_type}, 3;
      is $obj->{data}->{body_data}->{title}, $current->o ('t1');
      is $obj->{data}->{body_data}->{theme}, 'blue';
    } $current->c;
  });
} n => 4, name => 'group index object';

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
