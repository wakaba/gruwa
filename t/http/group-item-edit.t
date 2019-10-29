use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1'], title => "6"});
  })->then (sub {
    return $current->are_errors (
      ['POST', ['edit.json'], {title => "\x{667}"}, group => 'g1', account => 'a1'],
      [
        {path => ['g', '435444', 'edit.json'], group => undef, status => 404},
        {account => undef, status => 403},
        {account => '', status => 403},
        {method => 'GET', status => 405},
        {origin => undef, status => 400},
        {origin => 'null', status => 400},
      ],
    );
  })->then (sub {
    return $current->post_json (['edit.json'], {title => "\x{666}"}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $group = $_[0]->{json}->{group};
    test {
      is $group->{title}, "\x{666}";
      ok $group->{updated} > $group->{created};
    } $current->c;
  });
} n => 3, name => 'title changed';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1'], title => "\x{900}"});
  })->then (sub {
    return $current->post_json (['edit.json'], {title => ""}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $group = $_[0]->{json}->{group};
    test {
      is $group->{title}, "\x{900}";
      is $group->{updated}, $group->{created};
    } $current->c;
  });
} n => 2, name => 'title empty';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1'], title => "\x{900}"});
  })->then (sub {
    return $current->post_json (['edit.json'], {title => undef}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $group = $_[0]->{json}->{group};
    test {
      is $group->{title}, "\x{900}";
      is $group->{updated}, $group->{created};
    } $current->c;
  });
} n => 2, name => 'title undef';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1'], title => "6"});
  })->then (sub {
    return $current->post_json (['edit.json'], {theme => ''}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $group = $_[0]->{json}->{group};
    test {
      is $group->{theme}, 'green';
      is $group->{updated}, $group->{created};
    } $current->c;
    return $current->post_json (['edit.json'], {theme => 'red'}, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $group = $_[0]->{json}->{group};
    test {
      is $group->{theme}, 'red';
      ok $group->{updated} > $group->{created};
    } $current->c;
  });
} n => 4, name => 'theme';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1'], title => "6"});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_index (i2 => {group => 'g2', account => 'a1'});
  })->then (sub {
    return $current->are_errors (
      ['POST', ['edit.json'], {}, account => 'a1', group => 'g1'],
      [
        {params => {default_wiki_index_id => 0}, status => 400},
        {params => {default_wiki_index_id => 64363444}, status => 400},
        {params => {default_wiki_index_id => $current->o ('i2')->{index_id}}, status => 400},
      ],
    );
  })->then (sub {
    return $current->post_json (['edit.json'], {
      default_wiki_index_id => $current->o ('i1')->{index_id},
    }, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $group = $_[0]->{json}->{group};
    test {
      is $group->{default_wiki_index_id}, $current->o ('i1')->{index_id};
      ok $group->{updated} > $group->{created};
    } $current->c;
  });
} n => 3, name => 'default_wiki_index_id';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {owners => ['a1']}],
  )->then (sub {
    return $current->post_json (['edit.json'], {
      title => $current->generate_text (t1 => {}),
      theme => 'red',
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    $current->set_o (oid1 => $result->{json}->{group}->{object_id});
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
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{group}->{object_id}, $current->o ('oid1'),
         'group object unchanged';
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
} n => 5, name => 'group object';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {owners => ['a1']}],
    [o1 => object => {group => 'g1', account => 'a1'}],
  )->then (sub {
    return $current->post_json (['edit.json'], {
      icon_object_id => $current->o ('o1')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->are_errors (
      ['POST', ['edit.json'], {
        icon_object_id => rand,
      }, account => 'a1', group => 'g1'],
      [
        {params => {icon_object_id => rand}, status => 400},
        {params => {icon_object_id => 0}, status => 400},
        {params => {icon_object_id => "abc"}, status => 400},
      ],
    );
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    $current->set_o (oid1 => $result->{json}->{group}->{object_id});
    test {
      is $result->{json}->{group}->{icon_object_id}, $current->o ('o1')->{object_id};
      like $result->{res}->body_bytes, qr{"icon_object_id"\s*:\s*"};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('oid1'),
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    my $obj = $result->{json}->{objects}->{$current->o ('oid1')};
    test {
      is $obj->{data}->{body_type}, 3;
      is $obj->{data}->{body_data}->{icon_object_id}, $current->o ('o1')->{object_id};
      like $result->{res}->body_bytes, qr{"icon_object_id"\s*:\s*"};
    } $current->c;
  });
} n => 6, name => 'icon object';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {owners => ['a1']}],
    [o1 => object => {group => 'g1', account => 'a1'}],
  )->then (sub {
    return $current->post_json (['edit.json'], {
      guide_object_id => $current->o ('o1')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->are_errors (
      ['POST', ['edit.json'], {
        guide_object_id => rand,
      }, account => 'a1', group => 'g1'],
      [
        {params => {guide_object_id => rand}, status => 400},
        {params => {guide_object_id => 0}, status => 400},
        {params => {guide_object_id => "abc"}, status => 400},
      ],
    );
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    $current->set_o (oid1 => $result->{json}->{group}->{object_id});
    test {
      is $result->{json}->{group}->{guide_object_id}, $current->o ('o1')->{object_id};
      like $result->{res}->body_bytes, qr{"guide_object_id"\s*:\s*"};
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('oid1'),
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    my $obj = $result->{json}->{objects}->{$current->o ('oid1')};
    test {
      is $obj->{data}->{body_type}, 3;
      is $obj->{data}->{body_data}->{guide_object_id}, $current->o ('o1')->{object_id};
      like $result->{res}->body_bytes, qr{"guide_object_id"\s*:\s*"};
    } $current->c;
  });
} n => 6, name => 'guide object';

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
