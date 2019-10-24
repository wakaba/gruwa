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
    [o1 => object => {
      group => 'g1',
      account => 'a1',
      title => $current->generate_text (t4 => {}),
      index => 'i1',
      timestamp => 5354434455,
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'i', $current->o ('i1')->{index_id}, ''],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'header.page',
      text => $current->o ('t3'), # index title
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'header.page gr-menu a[href*="/i/"]',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t4'), # object title
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        title: document.title,
        url: location.pathname,
        headerTitle: document.querySelector ('header.page h1').textContent,
        headerURL: document.querySelector ('header.page h1 a').pathname,
        headerLink: document.querySelector ('header.page gr-menu a').pathname,
        sectionTitle: document.querySelector ('section > h1').textContent,
        //sectionTitle: document.querySelector ('header.section h1').textContent,
        //sectionURL: document.querySelector ('header.section a').pathname,
        //sectionLink: document.querySelector ('header.section gr-menu a').pathname,
      };
    });
  })->then (sub {
    my $res = $_[0];
    my $values = $res->json->{value};
    test {
      use utf8;
      is $values->{title}, $current->o ('t3') . ' - ' . $current->o ('t1');
      is $values->{url}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/';
      is $values->{headerTitle}, $current->o ('t3');
      is $values->{headerURL}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/';
      is $values->{headerLink}, $values->{headerURL};
      like $values->{sectionTitle}, qr{[0-9]};
    } $current->c;
  });
} n => 6, name => ['initial load (blog)'], browser => 1;

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
      index_type => 2, # wiki
    }],
    [o1 => object => {
      group => 'g1',
      account => 'a1',
      title => $current->generate_text (t4 => {}),
      index => 'i1',
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'i', $current->o ('i1')->{index_id}, ''],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'header.page',
      text => $current->o ('t3'), # index title
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'header.page gr-menu a[href*="/i/"]',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t4'), # object title
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        title: document.title,
        url: location.pathname,
        headerTitle: document.querySelector ('header.page h1').textContent,
        headerURL: document.querySelector ('header.page h1 a').pathname,
        headerLink: document.querySelector ('header.page gr-menu a').pathname,
        resultItemURL: document.querySelector ('.search-result list-main list-item a[href]').pathname,
      };
    });
  })->then (sub {
    my $res = $_[0];
    my $values = $res->json->{value};
    test {
      use utf8;
      is $values->{title}, $current->o ('t3') . ' - ' . $current->o ('t1');
      is $values->{url}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/';
      is $values->{headerTitle}, $current->o ('t3');
      is $values->{headerURL}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/';
      is $values->{headerLink}, $values->{headerURL};
      is $values->{resultItemURL}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/wiki/'.(percent_encode_c $current->o ('t4'));
    } $current->c;
  });
} n => 6, name => ['initial load (wiki)'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [g1 => group => {
      members => ['a1', 'a2'], title => $current->generate_text (t1 => {}),
      theme => 'red',
    }],
    [i1 => index => {
      group => 'g1',
      account => 'a1',
      title => $current->generate_text (t3 => {}),
      index_type => 3, # todos
    }],
    [i2 => index => {
      group => 'g1',
      account => 'a1',
      title => $current->generate_text (ti2 => {}),
      index_type => 4, # category
    }],
    [i3 => index => {
      group => 'g1',
      account => 'a1',
      title => $current->generate_text (ti3 => {}),
      index_type => 5, # milestone
    }],
    [o1 => object => {
      group => 'g1',
      account => 'a1',
      title => $current->generate_text (t4 => {}),
      index => ['i1', 'i2', 'i3'],
      todo_state => 1, # open
      assigned_account => ['a2'],
    }],
    [o2 => object => {
      group => 'g1',
      account => 'a1',
      title => $current->generate_text (t5 => {}),
      index => 'i1',
      todo_state => 2, # closed
      body_type => 1, # html
      body => q{<input type=checkbox><input type=checkbox checked><input type=checkbox>},
    }],
  )->then (sub {
    return $current->post_json (['my', 'edit.json'], {
      name => $current->generate_text (a2name => {}),
    }, group => 'g1', account => 'a2');
  })->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'i', $current->o ('i1')->{index_id}, ''],
      params => {
        todo => 'all',
      },
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'header.page',
      text => $current->o ('t3'), # index title
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'header.page gr-menu a[href*="/i/"]',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t4'), # object title
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t5'), # object title
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('a2name'), # assgined account name
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main list-item:nth-child(2) gr-index-list[indextype="4"]',
      text => $current->o ('ti2'),
      name => 'label index title',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main list-item:nth-child(2) gr-index-list[indextype="5"]',
      text => $current->o ('ti3'),
      name => 'milestone index title',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main gr-count progress[value][max]',
      shown => 1, scroll => 1,
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
      is $values->{title}, $current->o ('t3') . ' - ' . $current->o ('t1');
      is $values->{url}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/';
      is $values->{headerTitle}, $current->o ('t3');
      is $values->{headerURL}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/';
      is $values->{headerLink}, $values->{headerURL};
    } $current->c;
    return $current->b (1)->execute (q{
      return Array.prototype.slice.call (document.querySelectorAll ('.todo-list list-main list-item')).map (_ => {
        return {
          statusValue: _.querySelector ('enum-value.todo-state').getAttribute ('value'),
          countHidden: _.querySelector ('gr-count').hidden,
          countValue: (_.querySelector ('gr-count progress') || {}).value,
          countAll: (_.querySelector ('gr-count progress') || {}).max,
          assigned: _.querySelector ('gr-account-list').textContent,
        };
      });
    });
  })->then (sub {
    my $res = $_[0];
    my $values = $res->json->{value};
    test {
      is 0+@{$values}, 2;
      is $values->[0]->{statusValue}, 2;
      is !!$values->[0]->{countHidden}, !!0;
      is $values->[0]->{countValue}, 1;
      is $values->[0]->{countAll}, 3;
      is !!$values->[0]->{assigned}, '';
      is $values->[1]->{statusValue}, 1;
      is !!$values->[1]->{countHidden}, !!1;
      like $values->[1]->{assigned}, qr{\Q@{[$current->o ('a2name')]}\E};
    } $current->c;
  });
} n => 14, name => ['initial load (todo)'], browser => 1;

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
      index_type => 4, # label
    }],
    [o1 => object => {
      group => 'g1',
      account => 'a1',
      title => $current->generate_text (t4 => {}),
      index => 'i1',
      todo_state => 1, # open
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'i', $current->o ('i1')->{index_id}, ''],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t3'), # index title
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'header.page gr-menu a',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t4'), # object title
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        title: document.title,
        url: location.pathname,
        headerTitle: document.querySelector ('header.page h1').textContent,
        headerURL: document.querySelector ('header.page h1 a').pathname,
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
      is $values->{title}, $current->o ('t3') . ' - ' . $current->o ('t1');
      is $values->{url}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/';
      is $values->{headerTitle}, $current->o ('t1');
      is $values->{headerURL}, '/g/'.$current->o ('g1')->{group_id}.'/';
      is $values->{headerLink}, $values->{headerURL};
      is $values->{sectionTitle}, $current->o ('t3');
      is $values->{sectionURL}, $values->{url};
      is $values->{sectionLink}, $values->{url};
    } $current->c;
  });
} n => 8, name => ['initial load (label)'], browser => 1;

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
      index_type => 5, # milestone
    }],
    [o1 => object => {
      group => 'g1',
      account => 'a1',
      title => $current->generate_text (t4 => {}),
      index => 'i1',
      todo_state => 1, # open
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'i', $current->o ('i1')->{index_id}, ''],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t3'), # index title
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'header.page gr-menu a',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t4'), # object title
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        title: document.title,
        url: location.pathname,
        headerTitle: document.querySelector ('header.page h1').textContent,
        headerURL: document.querySelector ('header.page h1 a').pathname,
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
      is $values->{title}, $current->o ('t3') . ' - ' . $current->o ('t1');
      is $values->{url}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/';
      is $values->{headerTitle}, $current->o ('t1');
      is $values->{headerURL}, '/g/'.$current->o ('g1')->{group_id}.'/';
      is $values->{headerLink}, $values->{headerURL};
      is $values->{sectionTitle}, $current->o ('t3');
      is $values->{sectionURL}, $values->{url};
      is $values->{sectionLink}, $values->{url};
    } $current->c;
  });
} n => 8, name => ['initial load (milestone)'], browser => 1;

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
      index_type => 6, # fileset
      subtype => 'image',
    }],
    [o1 => object => {
      group => 'g1',
      account => 'a1',
      title => $current->generate_text (t4 => {}),
      index => 'i1',
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'i', $current->o ('i1')->{index_id}, ''],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t3'), # index title
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'header.page gr-menu a',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'header.section gr-menu a',
    });
  })->then (sub {
              #XXX
#    return $current->b_wait (1 => {
#      selector => 'page-main',
#      html => $current->o ('o1')->{object_id},
#    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        title: document.title,
        url: location.pathname,
        headerTitle: document.querySelector ('header.page h1').textContent,
        headerURL: document.querySelector ('header.page h1 a').pathname,
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
      is $values->{title}, $current->o ('t3') . ' - ' . $current->o ('t1');
      is $values->{url}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/';
      is $values->{headerTitle}, $current->o ('t1');
      is $values->{headerURL}, '/g/'.$current->o ('g1')->{group_id}.'/';
      is $values->{headerLink}, $values->{headerURL};
      is $values->{sectionTitle}, $current->o ('t3');
      is $values->{sectionURL}, $values->{url};
      is $values->{sectionLink}, $values->{url};
    } $current->c;
  });
} n => 8, name => ['initial load (fileset image)'], browser => 1;

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
      index_type => 6, # fileset
      subtype => 'file',
    }],
    [o1 => object => {
      group => 'g1',
      account => 'a1',
      title => $current->generate_text (t4 => {}),
      index => 'i1',
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'i', $current->o ('i1')->{index_id}, ''],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t3'), # index title
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'header.page gr-menu a',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'header.section gr-menu a',
    });
  })->then (sub {
              # XXX
#    return $current->b_wait (1 => {
#      selector => 'page-main',
#      html => $current->o ('o1')->{object_id},
#    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        title: document.title,
        url: location.pathname,
        headerTitle: document.querySelector ('header.page h1').textContent,
        headerURL: document.querySelector ('header.page h1 a').pathname,
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
      is $values->{title}, $current->o ('t3') . ' - ' . $current->o ('t1');
      is $values->{url}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/';
      is $values->{headerTitle}, $current->o ('t1');
      is $values->{headerURL}, '/g/'.$current->o ('g1')->{group_id}.'/';
      is $values->{headerLink}, $values->{headerURL};
      is $values->{sectionTitle}, $current->o ('t3');
      is $values->{sectionURL}, $values->{url};
      is $values->{sectionLink}, $values->{url};
    } $current->c;
  });
} n => 8, name => ['initial load (fileset file)'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      members => ['a1'], title => $current->generate_text (t1 => {}),
      theme => 'red',
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'i', 5235244, ''],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-navigate-status',
      text => '404 Index |5235244| not found',
    });
  })->then (sub {
    test {
      ok 1;
    } $current->c;
  });
} n => 1, name => ['index not found'], browser => 1;

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
