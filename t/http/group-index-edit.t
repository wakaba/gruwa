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
      ['POST', ['i', $current->o ('i1')->{index_id}, 'edit.json'], {title => "\x{667}"}, group => 'g1', account => 'a1'],
      [
        {path => ['i', '435444', 'edit.json'], status => 404},
        {group => 'g2', status => 404},
        {account => undef, status => 403},
        {account => '', status => 403},
        {method => 'GET', status => 405},
        {origin => undef, status => 400},
        {origin => 'null', status => 400},
      ],
    );
  })->then (sub {
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'edit.json'], {title => "\x{666}"}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->index ($current->o ('i1'), account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{title}, "\x{666}";
      ok $index->{updated} > $index->{created};
    } $current->c;
  });
} n => 3, name => 'title changed';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1', title => "\x{900}"});
  })->then (sub {
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'edit.json'], {title => ""}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->index ($current->o ('i1'), account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{title}, "\x{900}";
      is $index->{updated}, $index->{created};
    } $current->c;
  });
} n => 2, name => 'title empty';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1', title => "\x{900}"});
  })->then (sub {
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'edit.json'], {title => undef}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->index ($current->o ('i1'), account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{title}, "\x{900}";
      is $index->{updated}, $index->{created};
    } $current->c;
  });
} n => 2, name => 'title undef';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1', title => "\x{900}"});
  })->then (sub {
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'edit.json'], {theme => ''}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->index ($current->o ('i1'), account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{theme}, "green";
      is $index->{updated}, $index->{created};
    } $current->c;
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'edit.json'], {theme => 'black'}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->index ($current->o ('i1'), account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{theme}, "black";
      ok $index->{updated} > $index->{created};
    } $current->c;
  });
} n => 4, name => 'theme';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1', title => "\x{900}"});
  })->then (sub {
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'edit.json'], {index_type => 4}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->index ($current->o ('i1'), account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{index_type}, 4;
      ok $index->{updated} > $index->{created};
    } $current->c;
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'edit.json'], {index_type => 7}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->index ($current->o ('i1'), account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{index_type}, 7;
      ok $index->{updated} > $index->{created};
    } $current->c;
  });
} n => 4, name => 'index_type';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1', title => "\x{900}"});
  })->then (sub {
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'edit.json'], {color => '2016-01-01'}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->index ($current->o ('i1'), account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{color}, '2016-01-01';
      ok $index->{updated} > $index->{created};
    } $current->c;
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'edit.json'], {color => ''}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->index ($current->o ('i1'), account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{color}, '2016-01-01';
      ok $index->{updated} > $index->{created};
    } $current->c;
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'edit.json'], {color => 'abcee'}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->index ($current->o ('i1'), account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{color}, 'abcee';
      ok $index->{updated} > $index->{created};
    } $current->c;
  });
} n => 6, name => 'color';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1', title => "\x{900}"});
  })->then (sub {
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'edit.json'], {deadline => '2016-01-10'}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->index ($current->o ('i1'), account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{deadline}, '1452384000';
      ok $index->{updated} > $index->{created};
    } $current->c;
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'edit.json'], {deadline => ''}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->index ($current->o ('i1'), account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{deadline}, undef;
      ok $index->{updated} > $index->{created};
    } $current->c;
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'edit.json'], {deadline => 'abcee'}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->index ($current->o ('i1'), account => 'a1');
  })->then (sub {
    my $index = $_[0];
    test {
      is $index->{deadline}, undef;
      ok $index->{updated} > $index->{created};
    } $current->c;
  });
} n => 6, name => 'deadline';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {owners => ['a1']}],
    [i1 => index => {group => 'g1', account => 'a1'}],
  )->then (sub {
    return $current->post_json (['edit.json'], {
      title => $current->generate_text (t1 => {}),
      theme => 'red',
    }, account => 'a1', group => 'g1', index => 'i1');
  })->then (sub {
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
    $current->set_o (rev1 => $obj->{data}->{object_revision_id});
    return $current->post_json (['edit.json'], {
      title => $current->generate_text (t2 => {}),
    }, account => 'a1', group => 'g1', index => 'i1');
  })->then (sub {
    return $current->get_json (['info.json'], {}, account => 'a1', group => 'g1', index => 'i1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{object_id}, $current->o ('oid1'), 'group object unchanged';
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('oid1'),
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    my $obj = $result->{json}->{objects}->{$current->o ('oid1')};
    $current->set_o (rev2 => $obj->{data}->{object_revision_id});
    test {
      isnt $obj->{data}->{object_revision_id}, $current->o ('rev1'), 'revision changed';
      is $obj->{data}->{body_type}, 3;
      is $obj->{data}->{body_data}->{title}, $current->o ('t2');
      is $obj->{data}->{body_data}->{theme}, 'red';
    } $current->c;
  });
} n => 5, name => 'group index object';

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
