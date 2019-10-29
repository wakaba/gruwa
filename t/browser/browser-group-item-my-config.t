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
    return $current->post_json (['my', 'edit.json'], {
      name => $current->generate_text (t1 => {}),
    }, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'my', 'config'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main gr-if-welcome',
      not => 1, shown => 1,
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main gr-if-not-welcome',
      shown => 1,
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main input[name=name]:valid',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      var input = document.querySelector ('page-main input[name=name]');
      var value = input.value;
      input.value = arguments[0];
      document.querySelector ('page-main button[type=submit]').click ();
      return value;
    }, [$current->generate_text (t2 => {})]);
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main button[type=submit]:enabled',
    });
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{account}->{name}, $current->o ('t2');
    } $current->c;
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('gr-menu a[href$=members]').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#members table',
      text => $current->o ('t2'),
    }); # member list updated
  });
} n => 1, name => ['edit name'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      members => ['a1'],
    }],
    [i1 => index => {index_type => 6, subtype => 'icon',
                     account => 'a1', group => 'g1'}],
    [o1 => object => {account => 'a1', group => 'g1',
                      index => 'i1'}],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'my', 'config'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-select-icon popup-menu .generate-icon-button',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-select-icon gr-select-index option',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('gr-select-icon popup-menu > button').click ();
      document.querySelector ('gr-select-icon popup-menu .generate-icon-button').click ();
      return document.querySelector ('gr-select-icon popup-menu > button img').src;
    });
  })->then (sub {
    my $res = $_[0];
    test {
      like $res->json->{value}, qr{^data:image/png};
    } $current->c;
    return $current->b (1)->execute (q{
      document.querySelector ('#edit-form button[type=submit]').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#edit-form button[type=submit]:enabled',
    });
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $g = $result->{json}->{account};
      ok $g->{icon_object_id};
      $current->set_o (icon => {object_id => $g->{icon_object_id}});
    } $current->c;
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('icon')->{object_id},
      with_data => 1,
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $obj = $result->{json}->{objects}->{$current->o ('icon')->{object_id}};
      ok $obj->{data}->{index_ids}->{$current->o ('i1')->{index_id}};
      is $obj->{data}->{mime_type}, 'image/png';
    } $current->c;
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-select-icon popup-menu list-item button',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('gr-select-icon popup-menu list-item button').click ();
      return document.querySelector ('gr-select-icon popup-menu > button img').src;
    });
  })->then (sub {
    my $res = $_[0];
    test {
      like $res->json->{value}, qr{/o/@{[$current->o ('o1')->{object_id}]}/image};
    } $current->c;
    return $current->b (1)->execute (q{
      document.querySelector ('#edit-form button[type=submit]').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#edit-form button[type=submit]:enabled',
    });
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $g = $result->{json}->{account};
      is $g->{icon_object_id}, $current->o ('o1')->{object_id};
    } $current->c;
});
} n => 6, name => ['edit icon'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      members => ['a1'],
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'my', 'config'],
      params => {welcome => 1},
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main gr-if-not-welcome',
      not => 1, shown => 1,
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main gr-if-welcome',
      shown => 1,
    });
  })->then (sub {
    test {
      ok 1;
    } $current->c;
  });
} n => 1, name => ['welcome'], browser => 1;

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
