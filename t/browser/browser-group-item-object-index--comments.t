use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a3 => account => {}],
    [g1 => group => {
      members => ['a1', 'a3'],
    }],
    [o1 => object => {
      group => 'g1', account => 'a1',
    }],
    [o2 => object => {
      parent_object => 'o1',
      group => 'g1', account => 'a3',
    }],
    [o3 => object => {
      parent_object => 'o1',
      group => 'g1', account => 'a3',
      author_name => $current->generate_text (t3 => {}),
    }],
    [o4 => object => {
      parent_object => 'o1',
      group => 'g1', account => 'a3',
      author_hatena_id => $current->generate_text (t4 => {}),
    }],
  )->then (sub {
    return $current->post_json (['my', 'edit.json'], {
      name => $current->generate_text (t2 => {}),
    }, group => 'g1', account => 'a3');
  })->then (sub {
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
      selector => 'article-comments',
      text => $current->o ('t2'),
      name => 'o2 author account name',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments',
      text => $current->o ('t3'),
      name => 'o3 author name',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments',
      text => $current->o ('t4'),
      name => 'o4 author Hatena ID',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return Array.prototype.slice.call (document.querySelectorAll ('article-comments article')).map (_ => {
        return (_.querySelector ('gr-account-name, gr-person') || {}).textContent;
      });
    });
  })->then (sub {
    my $res = $_[0];
    test {
      my $names = $res->json->{value};
      like $names->[2], qr{\Qid:@{[$current->o ('t4')]}\E};
      like $names->[1], qr{\Q@{[$current->o ('t3')]}\E};
      like $names->[0], qr{\Q@{[$current->o ('t2')]}\E};
    } $current->c;
  });
} n => 3, name => ['comment authors'], browser => 1;

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
