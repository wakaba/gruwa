use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create_account (ao => {})->then (sub {
    return $current->create_account (am => {});
  })->then (sub {
    return $current->create_group (g1 => {title => "a\x{500}", owner => 'ao', members => ['am']});
  })->then (sub {
    return $current->are_errors (
      ['GET', ['i', 'list.json'], {}, account => 'am', group => $current->o ('g1')],
      [
        {path => ['g', '532533', 'i', 'list.json'], group => undef, status => 404},
        {account => '', status => 403, name => 'not member'},
        {account => undef, status => 403, name => 'no account'},
      ],
    );
  })->then (sub {
    return $current->get_json (['i', 'list.json'], {}, account => 'am', group => $current->o ('g1'));
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{index_list}}, 0;
    } $current->c;
  })->then (sub {
    return $current->get_json (['i', 'list.json'], {}, account => 'ao', group => $current->o ('g1'));
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+keys %{$result->{json}->{index_list}}, 0;
    } $current->c;
  });
} n => 3, name => '/g/{}/i/list.json empty';

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
