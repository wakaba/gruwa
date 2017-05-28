use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  my $obj_rev_id;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      todo_state => 4,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    $obj_rev_id = $result->{json}->{object_revision_id};
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o1')->{object_id},
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 1;
      my $o = $result->{json}->{objects}->{each %{$result->{json}->{objects}}};
      is $o->{data}->{body_type}, 3;
      is $o->{data}->{body_data}->{object_revision_id}, $obj_rev_id;
      is 0+keys %{$o->{data}->{body_data}->{old}}, 1;
      is $o->{data}->{body_data}->{old}->{todo_state}, 0;
      is 0+keys %{$o->{data}->{body_data}->{new}}, 1;
      is $o->{data}->{body_data}->{new}->{todo_state}, 4;
      unlike $result->{res}->body_bytes, qr{"object_revision_id"\s*:\s*[0-9]};
    } $current->c;
  });
} n => 8, name => 'todo_state';

Test {
  my $current = shift;
  my $old_id;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_index (i2 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      edit_index_id => 1,
      index_id => $current->o ('i1')->{index_id},
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o1')->{object_id},
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 1;
      my $o = $result->{json}->{objects}->{each %{$result->{json}->{objects}}};
      is $o->{data}->{body_type}, 3;
      ok $o->{data}->{body_data}->{new}->{index_ids}->{$current->o ('i1')->{index_id}};
      $old_id = $o->{object_id};
    } $current->c;
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      edit_index_id => 1,
      index_id => $current->o ('i2')->{index_id},
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o1')->{object_id},
      with_data => 1,
      limit => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{objects}}, 1;
      my $o = $result->{json}->{objects}->{each %{$result->{json}->{objects}}};
      isnt $o->{object_id}, $old_id;
      is $o->{data}->{body_type}, 3;
      is 0+keys %{$o->{data}->{body_data}->{old}}, 1;
      ok $o->{data}->{body_data}->{old}->{index_ids}->{$current->o ('i1')->{index_id}};
      is 0+keys %{$o->{data}->{body_data}->{new}}, 1;
      ok $o->{data}->{body_data}->{new}->{index_ids}->{$current->o ('i2')->{index_id}};
    } $current->c;
  });
} n => 10, name => 'index_id';

Test {
  my $current = shift;
  my $site = 'https://' . rand . '.test/foo/';
  my $page = $site . rand;
  my $timestamp = rand 10000000;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {
      group => 'g1', account => 'a1',
      body_type => 1,
      body => qq{<a href="$page"></a>},
      timestamp => $timestamp,
    });
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
      source_page => $page,
      source_site => $site,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    $current->set_o (o2 => $_[0]->{json});
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o2')->{object_id},
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $objs = [grep {
        $_->{data}->{body_type} == 3;
      } values %{$result->{json}->{objects}}];
      is 0+@$objs, 1;
      my $obj = $objs->[0];
      is $obj->{timestamp}, $timestamp;
      is $obj->{data}->{body_data}->{trackback}->{object_id}, $current->o ('o1')->{object_id};
      like $result->{res}->body_bytes, qr{"object_id"\s*:\s*"};
      unlike $result->{res}->body_bytes, qr{"object_id"\s*:\s*[0-9]};
    } $current->c, name => 'trackback object created';
    return $current->post_json (['o', 'create.json'], {
      source_page => $page,
      source_site => $site,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    $current->set_o (o3 => $_[0]->{json});
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o3')->{object_id},
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $obj = [grep {
        $_->{data}->{body_type} == 3;
      } values %{$result->{json}->{objects}}]->[0];
      is $obj, undef;
    } $current->c, name => 'trackback object not created for later updates';
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body => qq{<a href="$page"></a>!!!},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o3')->{object_id},
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $objs = [grep {
        $_->{data}->{body_type} == 3;
      } values %{$result->{json}->{objects}}];
      is 0+@$objs, 0;
    } $current->c, name => 'no duplicate trackback';
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body => qq{<a href="/g/@{[$current->o ('g1')->{group_id}]}/o/@{[$current->o ('o3')->{object_id}]}/"></a>!!!},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o3')->{object_id},
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $objs = [grep {
        $_->{data}->{body_type} == 3;
      } values %{$result->{json}->{objects}}];
      is 0+@$objs, 1;
    } $current->c, name => 'duplicate trackback allowed to avoid complexity';
  });
} n => 8, name => 'referenced url is then imported as an object';

Test {
  my $current = shift;
  my $site = 'https://' . rand . '.test/foo/';
  my $page = $site . rand;
  my $timestamp = rand 10000000;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
      source_page => $page,
      source_site => $site,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    $current->set_o (o2 => $_[0]->{json});
    return $current->create_object (o1 => {
      group => 'g1', account => 'a1',
      body_type => 1,
      body => qq{<a href="$page"></a>},
      timestamp => $timestamp,
    });
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o2')->{object_id},
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $objs = [grep {
        $_->{data}->{body_type} == 3;
      } values %{$result->{json}->{objects}}];
      is 0+@$objs, 1;
      my $obj = $objs->[0];
      is $obj->{timestamp}, $timestamp;
      is $obj->{data}->{body_data}->{trackback}->{object_id}, $current->o ('o1')->{object_id};
      like $result->{res}->body_bytes, qr{"object_id"\s*:\s*"};
      unlike $result->{res}->body_bytes, qr{"object_id"\s*:\s*[0-9]};
    } $current->c, name => 'trackback object created';
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body => qq{<a href="$page"></a>...},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o2')->{object_id},
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $objs = [grep {
        $_->{data}->{body_type} == 3;
      } values %{$result->{json}->{objects}}];
      is 0+@$objs, 1;
    } $current->c, name => 'no duplicate trackback';
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body => qq{<a href="/g/@{[$current->o ('g1')->{group_id}]}/o/@{[$current->o ('o2')->{object_id}]}/"></a>...},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      parent_object_id => $current->o ('o2')->{object_id},
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $objs = [grep {
        $_->{data}->{body_type} == 3;
      } values %{$result->{json}->{objects}}];
      is 0+@$objs, 1;
    } $current->c, name => 'no duplicate trackback';
  });
} n => 7, name => 'trackback to imported url';

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
