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
