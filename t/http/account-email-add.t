use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
  )->then (sub {
    return $current->are_errors (
      ['POST', ['account', 'email', 'add.json'], {
        addr => $current->generate_email_addr (undef, {}),
      }, account => 'a1'],
      [
        {method => 'GET', status => 405},
        {origin => undef, status => 400},
        {origin => rand, status => 400},
        {account => undef, status => 400},
        {params => {}, status => 400},
      ],
    );
  })->then (sub {
    return $current->are_errors (
      ['GET', ['account', 'email', 'verify'], {
      }, account => 'a1'],
      [
        {params => {}, status => 400},
        {params => {key => rand}, status => 400},
      ],
    );
  })->then (sub {
    $current->generate_email_addr (e1 => {});
    return $current->reset_email_count ('e1');
  })->then (sub {
    return $current->post_json (['account', 'email', 'add.json'], {
      addr => $current->o ('e1'),
    }, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok $result->{json}->{sent};
    } $current->c;
    return $current->get_email ('e1');
  })->then (sub {
    my $item = $_[0];
    test {
      is $item->{from}, 'info@gruwa.test';
      is $item->{to}, $current->o ('e1');
      my $msg = $item->{message};
      $msg =~ s/=([0-9A-F]{2})/pack 'C', hex $1/ge;
      $msg =~ m{<a[^<>]+href="([^"]+/account/email/verify\?key=[^"]+)"[^<>]*>};
      ok $1;
      my $url = Web::URL->parse_string ($1);
      $current->set_o (url => $url);
    } $current->c;
    return $current->client_for ($current->o ('url'))->request (
      url => $current->o ('url'),
    );
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 400;
    } $current->c, name => 'Bad user';
    return $current->client_for ($current->o ('url'))->request (
      url => $current->o ('url'),
      cookies => $current->o ('a2')->{cookies},
    );
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 400;
    } $current->c, name => 'Bad user';
    return $current->get_json (['account', 'email', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok not grep { $_->{addr} eq $current->o ('e1') } @{$result->{json}->{items}}
    } $current->c;
    return $current->get_json (['account', 'email', 'list.json'], {}, account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      ok not grep { $_->{addr} eq $current->o ('e1') } @{$result->{json}->{items}}
    } $current->c;
    return $current->client_for ($current->o ('url'))->request (
      url => $current->o ('url'),
      cookies => $current->o ('a1')->{cookies},
    );
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 302;
      is $res->header ('location'), $current->resolve ('/dashboard/calls#emails')->stringify;
    } $current->c;
    return $current->get_json (['account', 'email', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok grep { $_->{addr} eq $current->o ('e1') } @{$result->{json}->{items}}
    } $current->c;
    return $current->client_for ($current->o ('url'))->request (
      url => $current->o ('url'),
      cookies => $current->o ('a1')->{cookies},
    );
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 400;
    } $current->c;
  });
} n => 14, name => 'email association';

RUN;

=head1 LICENSE

Copyright 2019 Wakaba <wakaba@suikawiki.org>.

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
