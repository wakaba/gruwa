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
      title => $current->generate_text (t4 => {}),
      timestamp => 634646444,
    }],
  )->then (sub {
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
      selector => 'page-main',
      text => $current->o ('t4'), # object title
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main big-banner',
      not => 1,
    }); # no revision info
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        title: document.title,
        url: location.pathname,
        headerTitle: document.querySelector ('header.page h1').textContent,
        headerURL: document.querySelector ('header.page h1 a').pathname,
        headerLink: document.querySelector ('header.page gr-menu a').pathname,
        sectionTitle: document.querySelector ('header.section h1').textContent,
        //sectionURL: document.querySelector ('header.section a').pathname,
        //sectionLink: document.querySelector ('header.section gr-menu a').pathname,
      };
    });
  })->then (sub {
    my $res = $_[0];
    my $values = $res->json->{value};
    test {
      use utf8;
      is $values->{title}, $current->o ('t4') . ' - ' . $current->o ('t1');
      is $values->{url}, '/g/'.$current->o ('g1')->{group_id}.'/o/'.$current->o ('o1')->{object_id}.'/';
      is $values->{headerTitle}, $current->o ('t1');
      is $values->{headerURL}, '/g/'.$current->o ('g1')->{group_id}.'/';
      is $values->{headerLink}, $values->{headerURL};
      like $values->{sectionTitle}, qr{[0-9]};
    } $current->c;
  });
} n => 6, name => ['initial load (orphan object)'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      members => ['a1'], title => $current->generate_text (t1 => {}),
      theme => 'red',
    }],
    [i1 => index => {
      account => 'a1',
      group => 'g1',
      title => $current->generate_text (t2 => {}),
      index_type => 1, # blog
    }],
    [o1 => object => {
      group => 'g1',
      account => 'a1',
      index => ['i1'],
      title => $current->generate_text (t4 => {}),
      timestamp => 1234646444,
    }],
  )->then (sub {
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
        //sectionURL: document.querySelector ('header.section a').pathname,
        //sectionLink: document.querySelector ('header.section gr-menu a').pathname,
      };
    });
  })->then (sub {
    my $res = $_[0];
    my $values = $res->json->{value};
    test {
      use utf8;
      is $values->{title}, $current->o ('t4') . ' - ' . $current->o ('t2') . ' - ' . $current->o ('t1');
      is $values->{url}, '/g/'.$current->o ('g1')->{group_id}.'/o/'.$current->o ('o1')->{object_id}.'/';
      is $values->{headerTitle}, $current->o ('t2');
      is $values->{headerURL}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/';
      is $values->{headerLink}, $values->{headerURL};
      like $values->{sectionTitle}, qr{[0-9]};
    } $current->c;
  });
} n => 6, name => ['initial load (blog object)'], browser => 1;

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
      account => 'a1',
      group => 'g1',
      title => $current->generate_text (t2 => {}),
      index_type => 3, # todo
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
      index => ['i1', 'i2', 'i3'],
      assigned_account => ['a2'],
      title => $current->generate_text (t4 => {}),
      timestamp => 1234646444,
    }],
  )->then (sub {
    return $current->post_json (['my', 'edit.json'], {
      name => $current->generate_text (a2name => {}),
    }, group => 'g1', account => 'a2');
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
      selector => 'page-main',
      text => $current->o ('t4'), # object title
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('a2name'), # assgined account name
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article.object footer gr-index-list',
      text => $current->o ('ti2'),
      name => 'label index title',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article.object footer gr-index-list',
      text => $current->o ('ti3'),
      name => 'milestone index title',
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
        //sectionURL: document.querySelector ('header.section a').pathname,
        //sectionLink: document.querySelector ('header.section gr-menu a').pathname,
      };
    });
  })->then (sub {
    my $res = $_[0];
    my $values = $res->json->{value};
    test {
      use utf8;
      #is $values->{title}, $current->o ('t4') . ' - ' . $current->o ('t2') . ' - ' . $current->o ('t1');
      is $values->{url}, '/g/'.$current->o ('g1')->{group_id}.'/o/'.$current->o ('o1')->{object_id}.'/';
      #is $values->{headerTitle}, $current->o ('t2');
      #is $values->{headerURL}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/';
      is $values->{headerLink}, $values->{headerURL};
      like $values->{sectionTitle}, qr{[0-9]};
    } $current->c;
  });
} n => 3, name => ['initial load (todo object)'], browser => 1;

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
      url => ['g', $current->o ('g1')->{group_id}, 'o', 5235244, ''],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-navigate-status',
      text => 'Object not found',
    });
  })->then (sub {
    test {
      ok 1;
    } $current->c;
  });
} n => 1, name => ['object not found'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      members => ['a1'],
    }],
    [o1 => object => {
      group => 'g1',
      account => 'a1',
    }],
  )->then (sub {
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
      selector => 'page-main article.object header popup-menu button',
      shown => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('page-main article.object header popup-menu button').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main article.object header popup-menu .delete-button',
      shown => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('page-main article.object header popup-menu form[data-confirm]').removeAttribute ('data-confirm');
      document.querySelector ('page-main article.object header popup-menu .delete-button').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main article.object.deleted',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      setTimeout (() => location.reload (), 0);
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main article.object.deleted',
    });
  })->then (sub {
    test {
      ok 1;
    } $current->c;
  });
} n => 1, name => ['delete'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a3 => account => {}],
    [g1 => group => {
      members => ['a1', 'a3'],
    }],
    [o1 => object => {
      group => 'g1',
      account => 'a1',
    }],
  )->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      title => $current->generate_text (t1 => {}),
    }, group => 'g1', account => 'a3');
  })->then (sub {
    $current->set_o (rev1 => $_[0]->{json});
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      title => $current->generate_text (t2 => {}),
    }, group => 'g1', account => 'a1');
  })->then (sub {
    $current->set_o (rev2 => $_[0]->{json});
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'o', $current->o ('o1')->{object_id}, ''],
      params => {
        object_revision_id => $current->o ('rev1')->{object_revision_id},
      },
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main article.object header',
      text => $current->o ('t1'),
      name => 'rev1 title',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main big-banner',
      html => $current->o ('a3')->{account_id},
    });
  })->then (sub {
    test {
      ok 1;
    } $current->c;
  });
} n => 1, name => ['object_revision_id'], browser => 1;

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
