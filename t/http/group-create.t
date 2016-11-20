use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->post_json (['g', 'create.json'], {
      title => "\x{4000}ab ",
    }, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{status}, 200;
      ok $result->{json}->{group_id};
      like $result->{res}->body_bytes, qr{"group_id"\s*:\s*"};
    } $current->c;
    return $current->group ($result->{json}, account => 'a1');
  })->then (sub {
    my $g = $_[0];
    test {
      is $g->{title}, "\x{4000}ab ";
    } $current->c;
  });
} n => 4, name => '/g/create.json';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->are_errors (
      ['POST', ['g', 'create.json'], {
        title => "\x{4000}ab ",
      }, account => 'a1'],
      [
        {method => 'GET', status => 405, name => 'GET'},
        {origin => undef, status => 400, name => 'no origin'},
        {params => {title => undef}, status => 400, name => 'no title'},
        {params => {title => ''}, status => 400, name => 'empty title'},
        {account => undef, status => 403, name => 'no account'},
      ],
    );
  });
} n => 1, name => '/g/create.json errors';

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
