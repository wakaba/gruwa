use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->client->request (path => ['account', 'cb'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 400;
      is $res->header ('Set-Cookie'), undef;
      is $res->header ('Location'), undef;
    } $current->c;
  });
} n => 3, name => '/account/cb no params';

Test {
  my $current = shift;
  return $current->client->request (path => ['account', 'cb'], params => {
    code => "abc de",
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 302;
      is $res->header ('Set-Cookie'), undef;
      is $res->header ('Location'), $current->resolve ("/account/done")->stringify;
    } $current->c;
  });
} n => 3, name => '/account/cb with code';

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
