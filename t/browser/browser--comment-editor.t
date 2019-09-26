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
    [a3 => account => {}],
    [a4 => account => {}],
    [g1 => group => {
      members => ['a1', 'a3', 'a4'],
      owners => ['a2'],
    }],
    [o1 => object => {
      group => 'g1',
      account => 'a1',
    }],
  )->then (sub {
    return $current->post_json (['my', 'edit.json'], {
      name => $current->generate_text (t2 => {}),
    }, group => 'g1', account => 'a2');
  })->then (sub {
    return $current->post_json (['my', 'edit.json'], {
      name => $current->generate_text (t3 => {}),
    }, group => 'g1', account => 'a3');
  })->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'o', $current->o ('o1')->{object_id}, ''],
      account => 'a4',
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
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments form gr-called-editor button',
      shown => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('article-comments form gr-called-editor button').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments form gr-called-editor menu-main',
      text => $current->o ('t2'),
      scroll => 1,
      name => 'a2 name (t2)',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments form gr-called-editor menu-main',
      text => $current->o ('t3'),
      scroll => 1,
      name => 'a3 name (t3)',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('article-comments form [data-name=body]').value = arguments[1];
      document.querySelector ('article-comments form gr-called-editor menu-main input[type=checkbox][value="'+arguments[0]+'"]').click ();
    }, [$current->o ('a3')->{account_id}, $current->generate_text (b1 => {})]);
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('article-comments form button[type=submit]').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments form button[type=submit]:enabled',
    });
  })->then (sub {
    return $current->get_json (['my', 'calls.json'], {}, account => 'a3');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item = $result->{json}->{items}->[0];
      is $item->{group_id}, $current->o ('g1')->{group_id};
      is $item->{thread_id}, $current->o ('o1')->{object_id};
      isnt $item->{object_id}, $current->o ('o1')->{object_id};
      is $item->{from_account_id}, $current->o ('a4')->{account_id};
      is $item->{reason}, 0b10;
    } $current->c;
    return $current->get_json (['my', 'calls.json'], {}, account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 0;
    } $current->c;
  });
} n => 7, name => ['comment with object call'], browser => 1;

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
