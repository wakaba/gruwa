use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->get_html (['account', 'login'])->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('X-Frame-Options'), 'sameorigin';
      is $result->{res}->header ('Set-Cookie'), undef;
    } $current->c;
  });
} n => 2, name => '/account/login GET';

Test {
  my $current = shift;
  return $current->are_errors (
    ['POST', ['account', 'login'], {server => 'test1'}],
    [
      {origin => undef,
       status => 400, response_headers => {'set-cookie' => undef},
       name => 'Bad |Origin:|'},
      {origin => 'foo',
       status => 400, response_headers => {'set-cookie' => undef},
       name => 'Bad |Origin:|'},
      {params => {},
       status => 400, response_headers => {'set-cookie' => undef},
       name => 'no |server|'},
      {params => {server => 'hoge'},
       status => 400, response_headers => {'set-cookie' => undef},
       name => 'Bad |server|'},
    ],
  );
} n => 1, name => '/account/login POST bad request';

Test {
  my $current = shift;
  return $current->client->request (path => ['account', 'login'], params => {
    server => 'test1',
  }, method => 'POST', headers => {
    origin => $current->client->origin->to_ascii,
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 302;
      like $res->header ('Set-Cookie'), qr{^sk=.+; httponly; samesite=lax$};
      like $res->header ('Location'), qr{^https?://[^/]+/authorize\?};
    } $current->c;
  });
} n => 3, name => '/account/login POST with server';

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
License along with this program, see <https://www.gnu.org/licenses/>.

=cut
