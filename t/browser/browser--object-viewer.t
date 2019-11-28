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
    [o2 => object => {
      group => 'g1', account => 'a1',
      title => $current->generate_text (t2 => {}),
    }],
  )->then (sub {
    return $current->create (
      [o1 => object => {
        group => 'g1',
        account => 'a1',
        body_type => 1, # html
        body => $current->generate_text (t1 => {}) . qq{<a href="../@{[$current->o ('o2')->{object_id}]}/">link</a> <a href=https://www.example.com/>link2</a>},
      }],
    );
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
      selector => 'article.object gr-html-viewer iframe',
    });
  })->then (sub {
    return $current->b (1)->switch_to_frame_by_selector ('article.object gr-html-viewer iframe');
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
    return $current->b (1)->switch_to_frame_by_selector ('article.object gr-html-viewer iframe');
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
      return document.querySelector ('article.object gr-html-viewer iframe').offsetHeight;
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->json->{value}, 1020, 'seamlessheight';
    } $current->c;
  });
} n => 1, name => ['object html viewer'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      members => ['a1'],
    }],
    [o1 => object => {
      group => 'g1', account => 'a1',
      source_site => 'http://importedtest.g.hatena.ne.jp',
      source_page => 'http://importedtest.g.hatena.ne.jp/testuser/20191123/1574496155',
    }],
    [o2 => object => {
      group => 'g1', account => 'a1',
      parent_object => 'o1',
      body_type => 3, # data
      body_data => {
        hatena_star => [
          ["userName1",0,3,""],
          ["userName2",0,2,""],
        ],
      },
    }],
  )->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 1, # html
      body => q{<hatena-html starmap="1574496155 }.$current->o ('o2')->{object_id}.q{"><div class="section"><h3 class="title"><a href="http://importedtest.g.hatena.ne.jp/testuser/20191123/1574496155" name="1574496155">Hello, World!</a></h3></hatena-html>},
    }, group => 'g1', account => 'a1');
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
      selector => 'article.object gr-html-viewer iframe',
    });
  })->then (sub {
    return $current->b (1)->switch_to_frame_by_selector ('article.object gr-html-viewer iframe');
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'h3 a',
      name => 'link in body text',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return document.querySelector ('h3 a').href;
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->json->{value}, q{http://app.server.test/g/}.$current->o ('g1')->{group_id}.q{/imported/http%3A%2F%2Fimportedtest.g.hatena.ne.jp%2Ftestuser%2F20191123%2F1574496155/go};
    } $current->c;
    return $current->b_screenshot (1, 'view');
  })->then (sub {
    return $current->b_wait (1 => {
      name => 'shadow',
      code => sub {
        return $current->b (1)->execute (q{
          var e = document.querySelector ('h3');
          if (!e) return [false, 'no h3'];
          if (!e.shadowRoot) return [false, 'no shadow'];
          var a = e.shadowRoot.querySelector ('a');
          if (!a) return [false, 'no a'];
          return [true, ''];
        })->then (sub {
          my $v = $_[0]->json->{value};
          #warn $v->[1];
          return $v->[0];
        });
      },
    });
  });
} n => 1, name => ['imported hatena html'], browser => 1;

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
