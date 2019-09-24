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
      members => ['a1'], title => $current->generate_text (t1 => {}),
    }],
    [i1 => index => {
      group => 'g1', account => 'a1',
    }],
    [g2 => group => {
      members => ['a1'], title => $current->generate_text (t2 => {}),
    }],
  )->then (sub {
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'my.json'], {
      is_default => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->create_browser (1 => {
      url => ['dashboard'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t1'),
      name => 'group list (name1)',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t2'),
      name => 'group list (name2)',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main a.default-index-button:not([hidden])',
      html => '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id},
      name => 'default index link (i1)',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main a.default-index-button[hidden]',
      not => 1, shown => 1,
      name => 'default index link (group2)',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        title: document.title,
        url: location.pathname,
        headerTitle: document.querySelector ('header.page h1').textContent,
        headerURL: document.querySelector ('header.page h1 a').pathname,
        headerLink: document.querySelector ('header.page gr-menu a').pathname,
      };
    });
  })->then (sub {
    my $res = $_[0];
    my $values = $res->json->{value};
    test {
      use utf8;
      is $values->{title}, 'ダッシュボード';
      is $values->{url}, '/dashboard';
      is $values->{headerTitle}, 'ダッシュボード';
      is $values->{headerURL}, '/dashboard';
      is $values->{headerLink}, $values->{headerURL};
    } $current->c;
  });
} n => 5, name => ['initial load'], browser => 1;

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
