use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  my $wiki_name = qq{\x{22155}} . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['edit.json'], {
      default_wiki_index_id => $current->o ('i1')->{index_id},
    }, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->are_errors (
      ['GET', ['wiki', $wiki_name], {}, account => 'a1', group => 'g1'],
      [
        {path => ['g', int rand 10000, 'wiki', $wiki_name], group => undef, status => 404},
        {account => '', status => 403},
        {account => undef, status => 302},
        {path => ['i', 32533333, 'wiki', $wiki_name], status => 404},
      ],
    );
  })->then (sub {
    return $current->get_html (['wiki', $wiki_name], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok 1;
    } $current->c;
    return $current->get_html (['i', $current->o ('i1')->{index_id},
                                'wiki', $wiki_name], {},
                               account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok 1;
    } $current->c;
  });
} n => 3, name => '/g/{group_id}/wiki/{wiki_name}';

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
