use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

for my $path (
  ['dashboard'],
  ['dashboard', 'groups'],
  ['dashboard', 'receive'],
  ['dashboard', 'calls'],
) {

  Test {
    my $current = shift;
    return $current->create (
      [a1 => account => {}],
      [a2 => account => {terms_version => 1}],
    )->then (sub {
      return promised_for {
        my $account = shift;
        return $current->get_html ($path, {
        }, account => $account);
      } ['a1', 'a2', undef];
    })->then (sub {
      test {
        ok 1;
      } $current->c;
    });
  } n => 1, name => [@$path];
} # $path

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->are_errors (
      ['GET', ['dashboard', 'abc'], {}],
      [
        {account => undef, status => 404},
        {account => 'a1', status => 404},
        {account => 'a1', path => ['dashboard', ''], status => 404},
      ],
    );
  });
} n => 1, name => '/dashboard/...';

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

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
<https://www.gnu.org/licenses/>.

=cut
