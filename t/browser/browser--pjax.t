use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      members => ['a1'],
      title => $current->generate_text (t1 => {}),
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'config'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-menu[type=group] a[href$="/members"]',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      window.testState = 123445;
setTimeout(() => {
      document.querySelector ('gr-menu[type=group] a[href$="/members"]').click ();
}, 0);
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#members',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      setTimeout (() => history.back (), 0);
      return {
        path: location.pathname,
        title: document.title,
        state: window.testState,
      };
    });
  })->then (sub {
    my $values = $_[0]->json->{value};
    test {
      use utf8;
      is $values->{path}, '/g/'.$current->o ('g1')->{group_id}.'/members';
      is $values->{title}, '参加者 - ' . $current->o ('t1');
      is $values->{state}, 123445;
    } $current->c;
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#edit-form',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      setTimeout (() => history.back (), 0);
      return {
        path: location.pathname,
        title: document.title,
        state: window.testState,
      };
    });
  })->then (sub {
    my $values = $_[0]->json->{value};
    test {
      use utf8;
      is $values->{path}, '/g/'.$current->o ('g1')->{group_id}.'/config';
      is $values->{title}, '設定 - ' . $current->o ('t1');
      is $values->{state}, 123445;
    } $current->c;
  });
} n => 6, name => ['/config -> /members -> back'], browser => 1;

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
