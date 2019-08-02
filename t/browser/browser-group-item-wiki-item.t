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
      account => 'a1', group => 'g1',
      title => $current->generate_text (t2 => {}),
      index_type => 2, # wiki
      is_default_wiki => 1,
    }],
    [o1 => object => {
      group => 'g1',
      account => 'a1',
      index => 'i1',
      title => $current->generate_text (t3 => {}),
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'wiki', $current->o ('t3')],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t3'), # object title (wiki name)
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        title: document.title,
        url: location.pathname,
        headerTitle: document.querySelector ('header.page h1').textContent,
        headerURL: document.querySelector ('header.page a').pathname,
        headerLink: document.querySelector ('header.page gr-menu a').pathname,
        sectionTitle: document.querySelector ('header.section h1').textContent,
        sectionURL: document.querySelector ('header.section a').pathname,
        sectionLink: document.querySelector ('header.section gr-menu a').pathname,
      };
    });
  })->then (sub {
    my $res = $_[0];
    my $values = $res->json->{value};
    test {
      use utf8;
      is $values->{title}, $current->o ('t3') . ' - ' . $current->o ('t2') . ' - ' . $current->o ('t1');
      is $values->{url}, '/g/'.$current->o ('g1')->{group_id}.'/wiki/' . percent_encode_c $current->o ('t3');
      is $values->{headerTitle}, $current->o ('t2');
      is $values->{headerURL}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/';
      is $values->{headerLink}, $values->{headerURL};
      is $values->{sectionTitle}, $current->o ('t3');
      is $values->{sectionURL}, $values->{url};
      is $values->{sectionLink}, $values->{url};
    } $current->c;
  });
} n => 8, name => ['initial load (wiki name)'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      members => ['a1'], title => $current->generate_text (t1 => {}),
      theme => 'red',
    }],
    [i1 => index => {
      account => 'a1', group => 'g1',
      title => $current->generate_text (t2 => {}),
      index_type => 2, # wiki
      is_default_wiki => 1,
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'wiki', $current->generate_text ('t3' => {})],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t3'), # wiki name
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
      is $values->{title}, $current->o ('t3') . ' - ' . $current->o ('t2') . ' - ' . $current->o ('t1');
      is $values->{url}, '/g/'.$current->o ('g1')->{group_id}.'/wiki/' . percent_encode_c $current->o ('t3');
    } $current->c;
  });
} n => 2, name => ['initial load (wiki name, no object)'], browser => 1;

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
