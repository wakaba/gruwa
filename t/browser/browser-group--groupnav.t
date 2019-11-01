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

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {
    }],
    [g1 => group => {
      members => ['a1'],
    }],
    [o2 => object => {account => 'a1', group => 'g1',
                      title => $current->generate_text (t1 => {})}],
  )->then (sub {
    return $current->create (
      [o1 => object => {account => 'a1', group => 'g1',
                        body_type => 1, # html
                        body => qq{<a href=../@{[$current->o ('o2')->{object_id}]}/ style="display:block;width:100%;
                                   height: 100%" class=o2-link>object</a>}}],
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
      selector => 'article iframe',
    });
  })->then (sub {
    return $current->b (1)->switch_to_frame_by_selector ('article iframe');
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '.o2-link',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      var link = document.querySelector ('.o2-link');
      return {
        element: link,
        left: link.offsetLeft, top: link.offsetTop,
        width: link.offsetWidth, height: link.offsetHeight,
      };
    });
  })->then (sub {
    $current->set_o (iframelink => $_[0]->json->{value});
    return $current->b_pointer_move (1, {
      element => $current->o ('iframelink')->{element},
    });
  })->then (sub {
    return $current->b (1)->http_post (['frame'], {id => undef});
  })->then (sub {
    my $res = $_[0];
    die $res if $res->is_error;
    return $current->b_wait (1 => {
      selector => 'gr-tooltip-box:not([hidden])',
      text => $current->o ('t1'),
    });
  })->then (sub {
    test {
      ok 1;
    } $current->c;
  });
} n => 1, name => ['group object link, tooltip'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {
    }],
    [g1 => group => {
      members => ['a1'],
    }],
    [o2 => object => {account => 'a1', group => 'g1',
                      title => $current->generate_text (t1 => {}),
                      source_site => 'https://'.$current->generate_domain (d1 => {}),
                      source_page => 'https://'.$current->o ('d1').'/abc'}],
  )->then (sub {
    return $current->create (
      [o1 => object => {account => 'a1', group => 'g1',
                        body_type => 1, # html
                        body => qq{<a href=../../imported/@{[percent_encode_c "https://".$current->o ('d1')."/abc"]}/go style="display:block;width:100%;
                                   height: 100%" class=o2-link>object</a>}}],
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
      selector => 'article iframe',
    });
  })->then (sub {
    return $current->b (1)->switch_to_frame_by_selector ('article iframe');
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '.o2-link',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      var link = document.querySelector ('.o2-link');
      return {
        element: link,
        left: link.offsetLeft, top: link.offsetTop,
        width: link.offsetWidth, height: link.offsetHeight,
        href: link.href,
      };
    });
  })->then (sub {
    $current->set_o (iframelink => $_[0]->json->{value});
    #warn $current->o ('iframelink')->{href};
    return $current->b_pointer_move (1, {
      element => $current->o ('iframelink')->{element},
    });
  })->then (sub {
    return $current->b (1)->http_post (['frame'], {id => undef});
  })->then (sub {
    my $res = $_[0];
    die $res if $res->is_error;
    return $current->b_wait (1 => {
      selector => 'gr-tooltip-box:not([hidden])',
      text => $current->o ('t1'),
    });
  })->then (sub {
    test {
      ok 1;
    } $current->c;
  });
} n => 1, name => ['imported same group object link, tooltip'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {
    }],
    [g1 => group => {
      members => ['a1'],
    }],
    [o2 => object => {account => 'a1', group => 'g1',
                      title => $current->generate_text (t2 => {})}],
  )->then (sub {
    return $current->create (
      [o1 => object => {account => 'a1', group => 'g1',
                        body_type => 1, # html
                        body => qq{<a href=../@{[$current->o ('o2')->{object_id}]}/ style="display:block;width:100%;
                                   height: 100%" class=o2-link>object</a>}}],
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
      selector => 'article iframe',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      window.abc = 12345;
    });
  })->then (sub {
    return $current->b (1)->switch_to_frame_by_selector ('article iframe');
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '.o2-link',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      var link = document.querySelector ('.o2-link');
      link.click ();
    });
  })->then (sub {
    return $current->b (1)->http_post (['frame'], {id => undef});
  })->then (sub {
    my $res = $_[0];
    die $res if $res->is_error;
    return $current->b_wait (1 => {
      selector => 'article h1',
      text => $current->o ('t2'),
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-tooltip-box:not([hidden])',
      not => 1, shown => 1,
    });
  })->then (sub {
    return $current->b (1)->http_post (['frame'], {id => undef});
  })->then (sub {
    my $res = $_[0];
    die $res if $res->is_error;
    return $current->b (1)->execute (q{
      return window.abc;
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->json->{value}, 12345, 'not navigated';
    } $current->c;
  });
} n => 1, name => ['group object link, clicked'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {
    }],
    [g1 => group => {
      members => ['a1'],
    }],
    [o2 => object => {account => 'a1', group => 'g1',
                      title => $current->generate_text (t2 => {}),
                      source_site => 'https://'.$current->generate_domain (d1 => {}),
                      source_page => 'https://'.$current->o ('d1').'/abc'}],
  )->then (sub {
    return $current->create (
      [o1 => object => {account => 'a1', group => 'g1',
                        body_type => 1, # html
                        body => qq{<a href=../../imported/@{[percent_encode_c "https://".$current->o ('d1')."/abc"]}/go style="display:block;width:100%;
                                   height: 100%" class=o2-link>object</a>}}],
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
    return $current->b (1)->execute (q{
      window.abc = 12345;
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article iframe',
    });
  })->then (sub {
    return $current->b (1)->switch_to_frame_by_selector ('article iframe');
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '.o2-link',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      var link = document.querySelector ('.o2-link');
      link.click ();
    });
  })->then (sub {
    return $current->b (1)->http_post (['frame'], {id => undef});
  })->then (sub {
    my $res = $_[0];
    die $res if $res->is_error;
    return $current->b_wait (1 => {
      selector => 'article h1',
      text => $current->o ('t2'),
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-tooltip-box:not([hidden])',
      not => 1, shown => 1,
    });
  })->then (sub {
    return $current->b (1)->http_post (['frame'], {id => undef});
  })->then (sub {
    my $res = $_[0];
    die $res if $res->is_error;
    return $current->b (1)->execute (q{
      return window.abc;
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->json->{value}, 12345;
    } $current->c;
  });
} n => 1, name => ['imported same group object link, clicked'], browser => 1;

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
