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
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'guide'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      html => q{config#guide},
    });
  })->then (sub {
    return $current->b (1)->url;
  })->then (sub {
    my $url = $_[0];
    test {
      is $url->{path}, '/g/'.$current->o ('g1')->{group_id}.'/guide';
    } $current->c;
  });
} n => 1, name => ['no guide page'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      members => ['a1'],
    }],
    [o1 => object => {
      group => 'g1', account => 'a1',
      title => $current->generate_text (t1 => {}),
    }],
  )->then (sub {
    return $current->post_json (['edit.json'], {
      guide_object_id => $current->o ('o1')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'guide'],
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
    });
  })->then (sub {
    return $current->b (1)->url;
  })->then (sub {
    my $url = $_[0];
    test {
      is $url->{path}, '/g/'.$current->o ('g1')->{group_id}.'/guide';
    } $current->c;
  });
} n => 1, name => ['has guide page'], browser => 1;

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
