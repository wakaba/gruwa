use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {
      name => $current->generate_text (t1 => {}),
    }],
    [g1 => group => {
      members => ['a1'],
      title => $current->generate_text (t2 => {}),
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'search'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-nav-panel gr-account-name:not([data-filling])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-nav-panel gr-group-name:not([data-filling])',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return document.querySelector ('gr-nav-panel');
    });
  })->then (sub {
    $current->set_o (button => $_[0]->json->{value});
    return $current->b_is_hidden (1 => $current->o ('button'));
  })->then (sub {
    my $hidden = $_[0];
    test {
      ok !! $hidden, 'panel is hidden by default';
    } $current->c;
    return $current->b (1)->execute (q{
      document.querySelector ('gr-nav-button button').click ();
    });
  })->then (sub {
    return $current->b_is_hidden (1 => $current->o ('button'));
  })->then (sub {
    my $hidden = $_[0];
    test {
      ok ! $hidden, 'panel is shown';
    } $current->c;
    return $current->b (1)->execute (q{
      return [
        document.querySelector ('gr-nav-panel gr-account-name').textContent,
        document.querySelector ('gr-nav-panel gr-group-name').textContent,
        document.querySelector ('gr-nav-panel .if-has-default-index'),
      ];
    });
  })->then (sub {
    my $values = $_[0]->json->{value};
    test {
      is $values->[0], $current->o ('t1');
      is $values->[1], $current->o ('t2');
    } $current->c;
    return $current->b_is_hidden (1 => $values->[2]);
  })->then (sub {
    my $hidden = $_[0];
    test {
      ok !! $hidden, 'index link is not shown';
    } $current->c;
  });
} n => 5, name => ['account and group'], browser => 1;

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
