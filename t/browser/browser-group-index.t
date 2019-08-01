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
    [i1 => index => {
      group => 'g1',
      account => 'a1',
      title => $current->generate_text (t3 => {}),
      index_type => 1, # blog
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
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t3'),
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        title: document.title,
        url: location.pathname,
      };
    });
  })->then (sub {
    my $res = $_[0];
    my $values = $res->json->{value};
    test {
      use utf8;
      is $values->{title}, $current->o ('t1');
      is $values->{url}, '/g/'.$current->o ('g1')->{group_id}.'/';
    } $current->c;
  });
} n => 2, name => ['initial load'], browser => 1;

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
