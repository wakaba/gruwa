use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [ax1 => account => {xs => 1}],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['account', 'login'],
    });
  })->then (sub {
    return $current->b_set_xs_name (1 => 'ax1');
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'form button[type=submit]',
      shown => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      setTimeout (() => {
        document.querySelector ('form button[type=submit]').click ();
      }, 100);
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

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [g1 => group => {members => ['a1', 'a2']}],
  )->then (sub {
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'my', 'edit.json'], {
      name => $current->generate_text (t2 => {}),
    }, account => 'a2');
  })->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, ''],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub { # cookie staled
    return $current->b (1)->set_cookie (sk => '', path => '/');
  })->then (sub {
    return $current->b (1)->execute (q{ GR.account.check ({force: true}) });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-backdrop > .dialog',
      shown => 1, scroll => 1,
    });
  })->then (sub { # signed in at another window (but BroadcastChannel not avail)
    return $current->b (1)->set_cookie (sk => $current->o ('a2')->{cookies}->{sk}, path => '/');
  })->then (sub {
    return $current->b (1)->execute (q{ GR.account.check ({force: true}) });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-backdrop > .dialog',
      not => 1, shown => 1,
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-nav-panel gr-account[self] gr-account-name',
      text => $current->o ('t2'),
    });
  })->then (sub {
    test {
      ok 1;
    } $current->c;
  });
} n => 1, name => ['group page - cookie staled'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [g1 => group => {members => ['a1', 'a2']}],
    [ax1 => account => {xs => 1}],
  )->then (sub {
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'my', 'edit.json'], {
      name => $current->generate_text (t2 => {}),
    }, account => 'a2');
  })->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, ''],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub { # cookie staled
    return $current->b (1)->set_cookie (sk => '', path => '/', max_age => -1);
  })->then (sub {
    return $current->b (1)->execute (q{ GR.account.check ({force: true}) });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-backdrop > .dialog',
      shown => 1, scroll => 1,
    });
  })->then (sub {
    return $current->b (1)->switch_to_frame_by_selector ('gr-backdrop > .dialog');
  })->then (sub {
    return $current->b_set_xs_name (1 => 'ax1');
  })->then (sub { # signed in with new account
    return $current->b_wait (1 => {
      selector => 'form button[type=submit]',
      shown => 1, scroll => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      setTimeout (() => {
        document.querySelector ('form button[type=submit]').click ();
      }, 100);
    });
  })->then (sub {
    return $current->b (1)->http_post (['frame'], {id => undef});
  })->then (sub {
    my $res = $_[0];
    die $res if $res->is_error;
    return $current->b_wait (1 => {
      selector => 'gr-account-dialog > gr-backdrop > .dialog',
    });
  })->then (sub {
    test {
      ok 1;
    } $current->c;
  });
} n => 1, name => ['group page - another account'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [ax1 => account => {xs => 1}],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['dashboard'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub { # cookie staled
    return $current->b (1)->set_cookie (sk => '', path => '/', max_age => -1);
  })->then (sub {
    return $current->b (1)->execute (q{ GR.account.check ({force: true}) });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-backdrop > .dialog',
      shown => 1, scroll => 1,
    });
  })->then (sub {
    return $current->b (1)->switch_to_frame_by_selector ('gr-backdrop > .dialog');
  })->then (sub {
    return $current->b_set_xs_name (1 => 'ax1');
  })->then (sub { # signed in with new account
    return $current->b_wait (1 => {
      selector => 'form button[type=submit]',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      setTimeout (() => {
        document.querySelector ('form button[type=submit]').click ();
      }, 100);
    });
  })->then (sub {
    return $current->b (1)->http_post (['frame'], {id => undef});
  })->then (sub {
    my $res = $_[0];
    die $res if $res->is_error;
    return $current->b_wait (1 => {
      selector => 'gr-account-dialog:not([changed]) > gr-backdrop > .dialog',
      not => 1,
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-account-dialog[changed] > gr-backdrop > .dialog',
      html => 'javascript:location.reload',
    });
  })->then (sub {
    test {
      ok 1;
    } $current->c;
  });
} n => 1, name => ['dashboard page - another account (login)'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      members => ['a1'],
    }],
    [o1 => object => {group => 'g1', account => 'a1'}],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'o', $current->o ('o1')->{object_id}, ''],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments form button[type=submit]',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('article-comments details summary').click ();

      GR._timestamp = {}; // reset cache
    });
  })->then (sub { # cookie staled
    return $current->b (1)->set_cookie (sk => '', path => '/', max_age => -1);
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('article-comments form textarea').value = arguments[0];
      document.querySelector ('article-comments form button[type=submit]').click ();
    }, [$current->generate_text (t1 => {})]);
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-backdrop > .dialog',
      shown => 1, scroll => 1,
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments form gr-action-status', # XXX
      text => 403,
      scroll => 1, shown => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return document.querySelector ('article-comments form textarea').value;
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->json->{value}, $current->o ('t1'), 'form value unchanged';
    } $current->c;
  });
} n => 1, name => ['group form 403'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      members => ['a1'],
    }],
    [o1 => object => {
      group => 'g1', account => 'a1',
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, ''],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub { # cookie staled
    return $current->b (1)->set_cookie (sk => '', path => '/', max_age => -1);
  })->then (sub {
    return $current->b (1)->execute (q{
      GR._timestamp = {}; // reset cache

      GR.navigate.go ('o/'+arguments[0]+'/', {});
    }, [$current->o ('o1')->{object_id}]);
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-backdrop > .dialog',
      shown => 1, scroll => 1,
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-navigate-status action-status',
      text => 403,
      scroll => 1, shown => 1,
    });
  })->then (sub {
    my $res = $_[0];
    test {
      ok 1;
    } $current->c;
  });
} n => 1, name => ['group pjax 403'], browser => 1;

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
