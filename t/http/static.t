use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->client->request (path => ['css', 'base.css'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 200;
      is $res->header ('content-type'), 'text/css;charset=utf-8';
      like $res->body_bytes, qr<GNU Affero General Public License>;
      ok $res->header ('last-modified');
      $current->set_o (rev1 => $res->header ('last-modified'));
      is $res->header ('cache-control'), undef;
    } $current->c;
    return $current->client->request (path => ['css', 'base.css'], params => {
      r => rand,
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 200;
      ok ! $res->header ('last-modified');
      is $res->header ('cache-control'), 'no-cache';
    } $current->c, name => 'Unknown revision';
    return $current->client->request (path => ['css', 'base.css'], params => {
      r => $current->app_rev,
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 200;
      is $res->header ('last-modified'), $current->o ('rev1');
      is $res->header ('cache-control'), undef;
    } $current->c, name => 'Current revision';
  });
} n => 11, name => '/css/base.css';

Test {
  my $current = shift;
  return $current->client->request (path => ['js', 'pages.js'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 200;
      is $res->header ('content-type'), 'text/javascript;charset=utf-8';
      like $res->body_bytes, qr<GNU Affero General Public License>;
      ok $res->header ('last-modified');
      $current->set_o (rev1 => $res->header ('last-modified'));
      is $res->header ('cache-control'), undef;
    } $current->c;
    return $current->client->request (path => ['js', 'pages.js'], params => {
      r => rand,
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 200;
      ok ! $res->header ('last-modified');
      is $res->header ('cache-control'), 'no-cache';
    } $current->c, name => 'Unknown revision';
    return $current->client->request (path => ['js', 'pages.js'], params => {
      r => $current->app_rev,
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 200;
      is $res->header ('last-modified'), $current->o ('rev1');
      is $res->header ('cache-control'), undef;
    } $current->c, name => 'Current revision';
  });
} n => 11, name => '/js/pages.css';

Test {
  my $current = shift;
  return $current->client->request (path => ['theme', 'list.json'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 200;
      is $res->header ('content-type'), 'application/json;charset=utf-8';
      like $res->body_bytes, qr<}>;
      ok $res->header ('last-modified');
      $current->set_o (rev1 => $res->header ('last-modified'));
      is $res->header ('cache-control'), undef;
    } $current->c;
    return $current->client->request (path => ['theme', 'list.json'], params => {
      r => rand,
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 200;
      ok ! $res->header ('last-modified');
      is $res->header ('cache-control'), 'no-cache';
    } $current->c, name => 'Unknown revision';
    return $current->client->request (path => ['theme', 'list.json'], params => {
      r => $current->app_rev,
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 200;
      is $res->header ('last-modified'), $current->o ('rev1');
      is $res->header ('cache-control'), undef;
    } $current->c, name => 'Current revision';
  });
} n => 11, name => '/theme/list.json';

Test {
  my $current = shift;
  return $current->client->request (path => ['css', '404.css'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 404;
      is $res->header ('content-type'), 'text/plain; charset=us-ascii';
      ok ! $res->header ('last-modified');
      is $res->header ('cache-control'), undef;
      is $res->body_bytes, q{404 File not found};
    } $current->c, name => 'Current revision';
  });
} n => 5, name => '/css/404.css';

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
