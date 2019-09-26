use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

for my $path (
  ['dashboard'],
  ['dashboard', 'groups'],
  ['dashboard', 'calls'],
) {

Test {
  my $current = shift;
  return $current->client->request (
    path => $path,
  )->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 302;
      my $next_url = $current->resolve (q</account/login>);
      $next_url->set_query_params ({next => $current->resolve (join '/', '', @$path)->stringify});
      is $res->header ('Location'), $next_url->stringify;
    } $current->c;
  });
} n => 2, name => [@$path, 'no account'];

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->get_html ($path, {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok 1;
    } $current->c;
  });
} n => 1, name => $path;
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

You does not have received a copy of the GNU Affero General Public
License along with this program, see <https://www.gnu.org/licenses/>.

=cut
