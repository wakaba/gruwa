use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->client->request (path => ['account', 'login'], headers => {
    origin => $current->client->origin->to_ascii,
  }, method => 'POST', params => {
    server => 'test1',
  })->then (sub {
    my $res = $_[0];
    $res->header ('Set-Cookie') =~ /sk=([^;]+)/;
    my $sk = $1;
    return $current->are_errors (
      ['GET', ['account', 'cb'], {
        code => "abc de",
      }],
      [
        {params => {}, status => 400,
         response_headers => {location => undef, 'set-cookie' => undef},
         name => 'no |code|'},
      ],
      [
        {account => undef, status => 400,
         response_headers => {location => undef, 'set-cookie' => undef},
         name => 'no |sk|'},
      ],
    )->then (sub {
      return $current->client->request (path => ['account', 'cb'], params => {
        code => "abc de",
      }, cookies => {sk => $sk});
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 302;
      is $res->header ('Set-Cookie'), undef;
      is $res->header ('Location'), $current->resolve ("/dashboard")->stringify;
    } $current->c;
  });
} n => 4, name => '/account/cb';

Test {
  my $current = shift;
  return $current->client->request (path => ['account', 'login'], headers => {
    origin => $current->client->origin->to_ascii,
  }, method => 'POST', params => {
    server => 'test1',
    next => $current->resolve ('/hoge/fuga?abc')->stringify,
  })->then (sub {
    my $res = $_[0];
    $res->header ('Set-Cookie') =~ /sk=([^;]+)/;
    my $sk = $1;
    return $current->client->request (path => ['account', 'cb'], params => {
      code => "abc de",
    }, cookies => {sk => $sk});
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 302;
      is $res->header ('Set-Cookie'), undef;
      is $res->header ('Location'), $current->resolve ("/hoge/fuga?abc")->stringify;
    } $current->c;
  });
} n => 3, name => '/account/cb with next';

Test {
  my $current = shift;
  return $current->client->request (path => ['account', 'login'], headers => {
    origin => $current->client->origin->to_ascii,
  }, method => 'POST', params => {
    server => 'test1',
    next => 'https://hoge.test/foo',
  })->then (sub {
    my $res = $_[0];
    $res->header ('Set-Cookie') =~ /sk=([^;]+)/;
    my $sk = $1;
    return $current->client->request (path => ['account', 'cb'], params => {
      code => "abc de",
    }, cookies => {sk => $sk});
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 302;
      is $res->header ('Set-Cookie'), undef;
      is $res->header ('Location'), $current->resolve ("/dashboard")->stringify;
    } $current->c;
  });
} n => 3, name => '/account/cb with bad next';

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
