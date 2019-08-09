use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [g1 => group => {owners => ['a1'], members => ['a2']}],
    [o1 => object => {group => 'g1', account => 'a1'}],
  )->then (sub {
    return $current->post_json (['edit.json'], {
      icon_object_id => $current->o ('o1')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_redirect (['icon'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('cache-control'), 'private,max-age=108000';
      is $result->{res}->header ('location'), $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/o/' . $current->o ('o1')->{object_id} . '/image')->stringify;
    } $current->c;
    return $current->get_redirect (['icon'], {}, account => 'a2', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('cache-control'), 'private,max-age=108000';
      is $result->{res}->header ('location'), $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/o/' . $current->o ('o1')->{object_id} . '/image')->stringify;
    } $current->c;
    return $current->are_errors (
      ['GET', ['icon'], {}, account => 'a1', group => 'g1'],
      [
        {account => undef, status => 302},
        {account => '', status => 403},
        {path => ['g', 242222, 'icon'], group => undef, status => 404},
        {path => ['g', 0 . $current->o ('g1')->{group_id}, 'icon'], group => undef, status => 404},
      ],
    );
  });
} n => 5, name => 'icon found';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [g1 => group => {owners => ['a1'], members => ['a2']}],
  )->then (sub {
    return $current->get_redirect (['icon'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('cache-control'), 'private,max-age=108000';
      is $result->{res}->header ('location'), $current->resolve ('/favicon.ico')->stringify;
    } $current->c;
    return $current->get_redirect (['icon'], {}, account => 'a2', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('cache-control'), 'private,max-age=108000';
      is $result->{res}->header ('location'), $current->resolve ('/favicon.ico')->stringify;
    } $current->c;
    return $current->are_errors (
      ['GET', ['icon'], {}, account => 'a1', group => 'g1'],
      [
        {account => undef, status => 302},
        {account => '', status => 403},
        {path => ['g', 242222, 'icon'], group => undef, status => 404},
        {path => ['g', 0 . $current->o ('g1')->{group_id}, 'icon'], group => undef, status => 404},
      ],
    );
  });
} n => 5, name => 'icon not found';

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
