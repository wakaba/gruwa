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
      members => ['a1', 'a3', 'a4'],
      owners => ['a2'],
    }],
    [o1 => object => {
      group => 'g1',
      account => 'a1',
    }],
  )->then (sub {
    return $current->post_json (['my', 'edit.json'], {
      name => $current->generate_text (t2 => {}),
    }, group => 'g1', account => 'a2');
  })->then (sub {
    return $current->post_json (['my', 'edit.json'], {
      name => $current->generate_text (t3 => {}),
    }, group => 'g1', account => 'a3');
  })->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'o', $current->o ('o1')->{object_id}, ''],
      account => 'a4',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article .edit-button',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('article .edit-button').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'edit-container gr-called-editor button',
      scroll => 1, shown => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('edit-container gr-called-editor button').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'edit-container gr-called-editor menu-main',
      text => $current->o ('t2'),
      scroll => 1,
      name => 'a2 name (t2)',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'edit-container gr-called-editor menu-main',
      text => $current->o ('t3'),
      scroll => 1,
      name => 'a3 name (t3)',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('edit-container gr-called-editor menu-main input[type=checkbox][value="'+arguments[0]+'"]').click ();
    }, [$current->o ('a3')->{account_id}]);
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('edit-container .save-button').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'edit-container .save-button:enabled',
    });
  })->then (sub {
    return $current->get_json (['my', 'calls.json'], {}, account => 'a3');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item = $result->{json}->{items}->[0];
      is $item->{group_id}, $current->o ('g1')->{group_id};
      is $item->{object_id}, $current->o ('o1')->{object_id};
      is $item->{from_account_id}, $current->o ('a4')->{account_id};
      is $item->{reason}, 0b10;
    } $current->c;
    return $current->get_json (['my', 'calls.json'], {}, account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 0;
    } $current->c;
  });
} n => 6, name => ['object_revision_id'], browser => 1;

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
        body_type => 1,
        body_source => $current->generate_text (t1 => {}) . qq{<a href="../@{[$current->o ('o2')->{object_id}]}/">link</a>},
        body_source_type => 3, # hatena
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
      selector => 'article .edit-button',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('article .edit-button').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'edit-container body-control a[data-name=preview]',
      scroll => 1, shown => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('edit-container body-control textarea').value += Math.random ();
    });
  })->then (sub {
    return $current->b_screenshot (1, 'before preview click');
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('edit-container body-control a[data-name=preview]').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'edit-container body-control body-control-tab[name=preview] gr-html-viewer iframe',
    });
  })->then (sub {
    return $current->b (1)->switch_to_frame_by_selector ('edit-container body-control body-control-tab[name=preview] gr-html-viewer iframe');
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
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-tooltip-box',
      text => $current->o ('t2'),
      name => 'referenced object title in tooltip',
    });
  })->then (sub {
    test {
      ok 1;
    } $current->c;
  });
} n => 1, name => ['preview html viewer'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      members => ['a1'],
    }],
    [o1 => object => {
      group => 'g1', account => 'a1',
      body_type => 1, # html
      body => q{},
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
      selector => 'article .edit-button',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('article .edit-button').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'edit-container body-control gr-html-viewer iframe',
      scroll => 1, shown => 1,
    });
  })->then (sub {
    return $current->b (1)->switch_to_frame_by_selector ('edit-container body-control gr-html-viewer iframe');
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-body[contenteditable]',
    });
  })->then (sub {
    return $current->b (1)->http_post (['frame'], {id => undef});
  })->then (sub {
    my $res = $_[0];
    die $res if $res->is_error;
    return $current->b (1)->execute (q{
      return document.querySelector ('edit-container body-control gr-html-viewer iframe');
    });
  })->then (sub {
    return $current->b (1)->click ($_[0]->json->{value});
  })->then (sub {
    return $current->b (1)->http_post (['keys'], {
      value => [split //, $current->generate_key (t1 => {})],
    })->then (sub {
      my $res = $_[0];
      die $res if $res->is_error;
    });
  })->then (sub {
    return $current->b_screenshot (1, 'before textarea click');
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('edit-container body-control a[data-name=textarea]').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'edit-container body-control textarea',
      shown => 1,
    });
  })->then (sub {
    return $current->b_screenshot (1, 'textarea ');
  })->then (sub {
    return $current->b (1)->execute (q{
      return document.querySelector ('edit-container body-control textarea').value;
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->json->{value}, $current->o ('t1');
    } $current->c;
    return $current->b (1)->execute (q{
      return document.querySelector ('edit-container .save-button').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'edit-container .save-button:enabled',
    });
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('o1')->{object_id},
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $obj = $result->{json}->{objects}->{$current->o ('o1')->{object_id}};
      is $obj->{data}->{body_type}, 1; # html
      is $obj->{data}->{body}, $current->o ('t1');
      is $obj->{data}->{body_source_type}, undef;
      is $obj->{data}->{body_source}, undef;
    } $current->c;
  });
} n => 5, name => ['WYSIWYG HTML editor'], browser => 1
    unless $ENV{CIRCLECI}; # //keys is somewhat broken...
    #unless $ENV{TEST_WD_BROWSER} =~ /firefox/; # XXX //keys is Chrome only

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
