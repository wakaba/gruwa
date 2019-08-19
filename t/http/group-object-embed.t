use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {title => "a\x{500}", members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {title => "a\x{500}", members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1',
                                           account => 'a1',
                                           title => "ab\x{4000}"});
  })->then (sub {
    return $current->are_errors (
      ['GET', ['o', $current->o ('o1')->{object_id}, 'embed'], {}, group => $current->o ('g1'), account => 'a1'],
      [
        {group => $current->o ('g2'), status => 404},
        {path => ['o', '5325253333', 'embed'], status => 404},
        {account => '', status => 403},
        {account => undef, status => 302},
      ],
    );
  })->then (sub {
    return $current->get_html (['o', $current->o ('o1')->{object_id}, 'embed'], {}, account => 'a1', group => $current->o ('g1'));
  })->then (sub {
    my $result = $_[0];
    test {
      ok 1;
    } $current->c;
  });
} n => 2, name => 'no index association';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {title => "a\x{500}", members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1',
                                           account => 'a1',
                                           title => "ab\x{4000}",
                                           user_status => 2});
  })->then (sub {
    return $current->are_errors (
      ['GET', ['o', $current->o ('o1')->{object_id}, 'embed'], {}, group => $current->o ('g1'), account => 'a1'],
      [
        {status => 410},
      ],
    );
  });
} n => 1, name => 'deleted by user';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_account (a0 => {});
  })->then (sub {
    return $current->create_group (g1 => {title => "a\x{500}", members => ['a1'], owner => 'a0'});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1',
                                           account => 'a0',
                                           title => "ab\x{4000}",
                                           owner_status => 2});
  })->then (sub {
    return $current->are_errors (
      ['GET', ['o', $current->o ('o1')->{object_id}, 'embed'], {}, group => $current->o ('g1'), account => 'a1'],
      [
        {status => 410},
      ],
    );
  });
} n => 1, name => 'deleted by owner'
    if 0; # owner_status change not implemented

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
