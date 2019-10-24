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
      theme => 'red',
    }],
    [o1 => object => {
      group => 'g1',
      account => 'a1',
      body => $current->generate_text (t2 => {}),
      title => $current->generate_text (t3 => {}),
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'search'],
      params => {q => $current->o ('t2')},
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '.search-result',
      text => $current->o ('t3'),
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        title: document.title,
        url: location.href,
        resultItemURL: document.querySelector ('.search-result list-main list-item a[href]').pathname,
      };
    });
  })->then (sub {
    my $res = $_[0];
    my $values = $res->json->{value};
    test {
      use utf8;
      is $values->{title}, $current->o ('t2') . ' - 検索 - ' . $current->o ('t1');
      like $values->{url}, qr{/search\?q=.+};
      is $values->{resultItemURL}, '/g/'.$current->o ('g1')->{group_id}.'/o/'.$current->o ('o1')->{object_id}.'/';
    } $current->c;
  });
} n => 3, name => ['search found'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      members => ['a1'], title => $current->generate_text (t1 => {}),
      theme => 'red',
    }],
    [o1 => object => {
      group => 'g1',
      account => 'a1',
      body => $current->generate_text (t2 => {}),
      title => $current->generate_text (t3 => {}),
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
      window.testState = 53554;
      document.querySelector ('form[is=gr-search] input[type=search]').value = arguments[0];
      document.querySelector ('form[is=gr-search] button[type=submit]').click ();
    }, [$current->o ('t2')]);
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '.search-result',
      text => $current->o ('t3'),
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        title: document.title,
        url: location.href,
        state: window.testState,
      };
    });
  })->then (sub {
    my $res = $_[0];
    my $values = $res->json->{value};
    test {
      is $values->{state}, 53554, 'page not changed';
    } $current->c;
  });
} n => 1, name => ['pjax searched'], browser => 1;

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
