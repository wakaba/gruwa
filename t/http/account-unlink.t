use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {
      email => [
        $current->generate_email_addr (d1 => {}),
        $current->generate_email_addr (d2 => {}),
      ],
    }],
  )->then (sub {
    return $current->get_json (['account', 'email', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    my $link = [grep { $_->{addr} eq $current->o ('d1') } @{$result->{json}->{items}}]->[0] // die;
    my $link2 = [grep { $_->{addr} eq $current->o ('d2') } @{$result->{json}->{items}}]->[0] // die;
    return $current->are_errors (
      ['POST', ['account', 'unlink.json'], {
        server => 'email',
        account_link_id => $link2->{account_link_id},
      }, account => 'a1'],
      [
        {method => 'GET', status => 405},
        {origin => undef, status => 400},
        {params => {
          account_link_id => $link2->{account_link_id},
        }, status => 400},
        {params => {
          account_link_id => $link2->{account_link_id},
          server => rand,
        }, status => 400},
        {params => {
          account_link_id => undef,
          server => 'email',
        }, status => 200},
        {params => {
          account_link_id => '',
          server => 'email',
        }, status => 200},
      ],
    )->then (sub {
      return $current->post_json (['account', 'unlink.json'], {
        server => 'email',
        account_link_id => $link->{account_link_id},
      }, account => 'a1');
    });
  })->then (sub {
    return $current->post_json (['account', 'unlink.json'], {
      server => 'email',
      account_link_id => rand, # bad id
    }, account => 'a1');
  })->then (sub {
    return $current->post_json (['account', 'unlink.json'], {
      server => 'email',
      account_link_id => int rand 100000, # not found
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['account', 'email', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      is $result->{json}->{items}->[0]->{addr}, $current->o ('d2');
    } $current->c;
    my $link = [@{$result->{json}->{items}}]->[0];
    return $current->post_json (['account', 'unlink.json'], {
      server => 'email',
      account_link_id => $link->{account_link_id},
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['account', 'email', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 0;
    } $current->c;
  });
} n => 4, name => 'unlink';

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
