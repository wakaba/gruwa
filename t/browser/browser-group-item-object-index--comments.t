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
      selector => 'article-comments details summary',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('article-comments details summary').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments details textarea',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('article-comments details textarea').value = arguments[0];
      document.querySelector ('article-comments button[type=submit]').click ();
    }, [$current->generate_text (t4 => {})]);
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments details button[type=submit]:enabled',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments',
      text => $current->o ('t2'),
      name => 'new comment author',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments details button[type=submit][name=todo_state]',
      shown => 1, not => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return document.querySelector ('article-comments details textarea').value;
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->json->{value}, '', 'reset';
    } $current->c;
  });
} n => 1, name => ['post a new comment'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a3 => account => {}],
    [g1 => group => {
      members => ['a1', 'a3'],
    }],
    [i1 => index => {
      account => 'a1',
      group => 'g1',
      index_type => 3, # todo
      todo_state => 1, # open
    }],
    [o1 => object => {
      group => 'g1', account => 'a1',
      index => 'i1',
    }],
    [o2 => object => {
      parent_object => 'o1',
      group => 'g1', account => 'a3',
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
      selector => 'article-comments details summary',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('article-comments details summary').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments details textarea',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments details button[type=submit][name=todo_state][value="2"]',
      shown => 1,
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments details button[type=submit][name=todo_state][value="1"]',
      shown => 1, not => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('article-comments details textarea').value = arguments[0];
      document.querySelector ('article-comments button[type=submit][name=todo_state][value="2"]').click ();
    }, [$current->generate_text (t4 => {})]);
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments details button[type=submit]:enabled',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments',
      text => $current->o ('t2'),
      name => 'new comment author',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments details button[type=submit][name=todo_state][value="2"]',
      shown => 1, not => 1,
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments details button[type=submit][name=todo_state][value="1"]',
      shown => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return document.querySelector ('article-comments details textarea').value;
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->json->{value}, '', 'reset';
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('o1')->{object_id},
      with_data => 1,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $obj = $result->{json}->{objects}->{$current->o ('o1')->{object_id}};
      is $obj->{data}->{todo_state}, 2;
    } $current->c;
    return $current->b_wait (1 => {
      selector => 'article-comments',
      text => $current->o ('t4'),
    });
  });
} n => 2, name => ['post a new comment'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a3 => account => {}],
    [g1 => group => {
      members => ['a1', 'a3'],
    }],
    [i1 => index => {
      account => 'a1',
      group => 'g1',
      index_type => 3, # todo
      todo_state => 1, # open
    }],
    [o1 => object => {
      group => 'g1', account => 'a1',
      index => 'i1',
    }],
    [o2 => object => {
      parent_object => 'o1',
      group => 'g1', account => 'a3',
      body_type => 2, # plaintext
      body => q{Hello,ttps://foo.bar/ba?an#xttp://a.b.},
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
      selector => 'article-comments article gr-plaintext-body',
      text => 'ttps://foo.bar/',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return [
        document.querySelector ('article-comments article gr-plaintext-body').innerHTML,
      ];
    });
  })->then (sub {
    my $res = $_[0];
    test {
      my ($html) = @{$res->json->{value}};
      is $html, q{Hello,ttps://foo.bar/ba?an#xttp://a.b.};
    } $current->c;
  });
} n => 1, name => ['plaintext HTML'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      members => ['a1'],
    }],
    [i1 => index => {
      account => 'a1',
      group => 'g1',
      index_type => 3, # todo
      todo_state => 1, # open
    }],
    [o3 => object => {
      group => 'g1', account => 'a1',
      title => $current->generate_text (t2 => {}),
    }],
    [o2 => object => {
      group => 'g1', account => 'a1',
      index => 'i1',
    }],
  )->then (sub {
    return $current->create (
      [o1 => object => {
        parent_object => 'o2',
        group => 'g1', account => 'a1',
        body_type => 1, # html
        body => q{<p style="min-height: 20em">} . $current->generate_text (t1 => {}) . qq{<a href="../@{[$current->o ('o3')->{object_id}]}/">link</a> <a href=https://www.example.com/>link2</a>},
      }],
    );
  })->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'o', $current->o ('o2')->{object_id}, ''],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments article gr-html-viewer iframe',
      shown => 1, scroll => 1,
    });
  })->then (sub {
    return $current->b_screenshot (1, 'before switch');
  })->then (sub {
    return $current->b (1)->switch_to_frame_by_selector ('article-comments article gr-html-viewer iframe');
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'body',
      text => $current->o ('t1'),
      name => 'body text',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'body a',
      name => 'link in body text',
    });
  })->then (sub {
    return $current->b_screenshot (1, 'before move');
  })->then (sub {
    return $current->b (1)->execute (q{
      return document.querySelector ('body a');
    });
  })->then (sub {
    return $current->b_pointer_move (1, {
      element => $_[0]->json->{value},
    });
  })->then (sub {
    return $current->b (1)->http_post (['frame'], {id => undef});
  })->then (sub {
    my $res = $_[0];
    die $res if $res->is_error;
    return $current->b_wait (1 => {
      selector => 'gr-tooltip-box',
      text => $current->o ('t2'),
      name => 'referenced object title in tooltip',
    });
  })->then (sub {
    return $current->b (1)->switch_to_frame_by_selector ('article-comments article gr-html-viewer iframe');
  })->then (sub {
    return $current->b (1)->execute (q{
      var link = document.querySelector ('body a:nth-of-type(2)');
      link.click ();

      document.body.style.margin = 0;
      document.body.style.padding = 0;
      var e = document.createElement ('div');
      e.style.top = 0;
      e.style.left = 0;
      e.style.height = 1020 + 'px';
      e.style.width = 100 + "px";
      document.body.textContent = '';
      document.body.appendChild (e);
    });
  })->then (sub {
    return $current->b (1)->http_post (['frame'], {id => undef});
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-navigate-dialog',
      text => 'www.example.com',
      name => 'external link dialog',
    });
  })->then (sub {
    return $current->b_screenshot (1, 'after dialog');
  })->then (sub {
    return $current->b (1)->execute (q{
      return document.querySelector ('article-comments article gr-html-viewer iframe').offsetHeight;
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->json->{value}, 1020, 'seamlessheight';
    } $current->c;
  });
} n => 1, name => ['HTML and links'], browser => 1;

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

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
<https://www.gnu.org/licenses/>.

=cut
