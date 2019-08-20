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
      document.querySelector ('gr-menu[type=group] a[href$="/members"]').click ();
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
    return $current->b (1)->execute (q{
      window.testState = 123445;
      var a = document.createElement ('a');
      a.href = 'i/32523533/config';
      document.body.appendChild (a);
      a.click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      setTimeout (() => history.back (), 0);
      return {
        path: location.pathname,
        state: window.testState,
        statusHidden: document.querySelector ('gr-navigate-status').hidden,
        status: document.querySelector ('gr-navigate-status action-status-message').textContent,
        pageMain: document.querySelector ('page-main').textContent,
      };
    });
  })->then (sub {
    my $values = $_[0]->json->{value};
    test {
      use utf8;
      is $values->{path}, '/g/'.$current->o ('g1')->{group_id}.'/i/32523533/config';
      is $values->{state}, 123445;
      ok ! $values->{statusHidden}, $values->{statusHidden};
      like $values->{status}, qr{404 Not Found};
      is $values->{pageMain}, '';
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
} n => 8, name => ['/config -> 404 -> back'], browser => 1;

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
      GR._state.navigateInitiated = - 3 * 24*60*60 * 1000; // stale

      window.testState = 123445;
      document.querySelector ('gr-menu[type=group] button').click ();
      document.querySelector ('gr-menu[type=group] a[href$="/members"]').click ();
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
      is $values->{state}, undef;
    } $current->c;
  });
} n => 3, name => ['pjax session timeout'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      members => ['a1'],
    }],
    [i1 => index => {
      group => 'g1', account => 'a1',
    }],
    [o1 => object => {
      account => 'a1', group => 'g1', index => 'i1',
      title => $current->generate_text (t1 => {}),
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'i', $current->o ('i1')->{index_id}, ''],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article header popup-menu button',
      shown => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('article header popup-menu button').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article header popup-menu a[is=copy-url]',
      shown => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('article header popup-menu a[is=copy-url]').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article header popup-menu a[is=copy-url]',
      not => 1, shown => 1,
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        path: location.pathname,
      };
    });
  })->then (sub {
    my $values = $_[0]->json->{value};
    test {
      is $values->{path}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/', 'not navigated';
    } $current->c;
    return $current->b (1)->execute (q{
      document.querySelector ('article header popup-menu button').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article header popup-menu a[is=gr-jump-add]',
      shown => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('article header popup-menu a[is=gr-jump-add]').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article header popup-menu a[is=gr-jump-add]',
      not => 1, shown => 1,
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-nav-panel',
      text => $current->o ('t1'),
      name => 'label added',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        path: location.pathname,
      };
    });
  })->then (sub {
    my $values = $_[0]->json->{value};
    test {
      is $values->{path}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/', 'not navigated';
    } $current->c;
  });
} n => 2, name => ['copy button'], browser => 1;

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
