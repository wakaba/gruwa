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
