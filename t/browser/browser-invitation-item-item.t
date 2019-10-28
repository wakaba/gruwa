use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {owner => 'a1'}],
    [inv1 => invitation => {account => 'a1', group => 'g1'}],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['invitation', $current->o ('g1')->{group_id}, $current->o ('inv1')->{invitation_key}, ''],
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '.login-button',
      shown => 1,
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '.save-button',
      shown => 1, not => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      setTimeout (() => document.querySelector ('.login-button').click (), 10);
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '.main-menu-list button',
    });
  })->then (sub {
    return $current->b (1)->url;
  })->then (sub {
    my $url = $_[0];
    test {
      like $url->stringify, qr{/account/login\?next=.+@{[
        $current->o ('g1')->{group_id}
      ]}.+@{[$current->o ('inv1')->{invitation_key}]}};
    } $current->c;
  });
} n => 1, name => ['invitation (no account)'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [g1 => group => {owner => 'a1'}],
    [inv1 => invitation => {account => 'a1', group => 'g1'}],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['invitation', $current->o ('g1')->{group_id}, $current->o ('inv1')->{invitation_key}, ''],
      account => 'a2',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '.save-button',
      shown => 1,
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '.login-button',
      shown => 1, not => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      setTimeout (() => document.querySelector ('.save-button').click (), 10);
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
    });
  })->then (sub {
    return $current->b (1)->url;
  })->then (sub {
    my $url = $_[0];
    test {
      like $url->stringify, qr{/g/@{[
        $current->o ('g1')->{group_id}
      ]}/my/config};
    } $current->c;
  });
} n => 1, name => ['invitation (has account)'], browser => 1;

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
