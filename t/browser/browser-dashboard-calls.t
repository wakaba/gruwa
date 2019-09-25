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
    [g1 => group => {
      members => ['a1', 'a2'],
      title => $current->generate_text (t1 => {}),
    }],
    [o1 => object => {group => 'g1', account => 'a2',
                      called_account => 'a1',
                      title => $current->generate_text (t2 => {}),
                      body => $current->generate_text (t3 => {})}],
  )->then (sub {
    return $current->post_json (['g', $current->o ('g1')->{group_id}, 'my', 'edit.json'], {
      name => $current->generate_text ('t4' => {}),
    }, account => 'a2');
  })->then (sub {
    return $current->create_browser (1 => {
      url => ['dashboard', 'calls'],
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
      name => 'call list (group title)',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t2'),
      name => 'call list (title)',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t3'),
      name => 'call list (body snippet)',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t4'),
      name => 'call list (from account name)',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'body > header.subpage',
      shown => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        title: document.title,
        url: location.pathname,
        headerTitle: document.querySelector ('header.page h1').textContent,
        headerURL: document.querySelector ('header.page h1 a').pathname,
        headerLink: document.querySelector ('header.page gr-menu a').pathname,
        subTitle: document.querySelector ('body > header.subpage gr-subpage-title').textContent,
        subBackURL: document.querySelector ('body > header.subpage a').pathname,
      };
    });
  })->then (sub {
    my $res = $_[0];
    my $values = $res->json->{value};
    test {
      use utf8;
      is $values->{title}, '記事通知 - Gruwa';
      is $values->{url}, '/dashboard/calls';
      is $values->{headerTitle}, 'ダッシュボード';
      is $values->{headerURL}, '/dashboard';
      is $values->{headerLink}, $values->{headerURL};
      is $values->{subTitle}, '記事通知';
      is $values->{subBackURL}, '/dashboard';
    } $current->c;
  });
} n => 7, name => ['initial load'], browser => 1;

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
