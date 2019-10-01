use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['account', 'login'],
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'form button[type=submit]',
      shown => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('form button[type=submit]').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'a[href*="/dashboard/calls"]',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-backdrop',
      not => 1,
    });
  })->then (sub {
    test {
      ok 1;
    } $current->c;
  });
} n => 1, name => ['login'], browser => 1;

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
