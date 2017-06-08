use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->client->request (path => ['my', 'info.json'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 200;
      my $json = json_bytes2perl $res->body_bytes;
      is $json->{account_id}, undef;
      is $json->{name}, undef;
    } $current->c;
  });
} n => 3, name => '/my/info.json';

Test {
  my $current = shift;
  my $name = rand;
  return $current->create_account (u1 => {
    name => $name,
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, account => 'u1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok $result->{json}->{account_id};
      is $result->{json}->{name}, $name;
      like $result->{res}->body_bytes, qr{"account_id"\s*:\s*"};
    } $current->c;
  });
} n => 3, name => '/my/info.json';

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
