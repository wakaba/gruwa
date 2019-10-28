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
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'config'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'body > header.subpage',
      shown => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        config_url: document.querySelector ('gr-menu[type=group] menu-main a[href$="/config"]').pathname,
        title: document.title,
        theme_color: document.querySelector ('meta[name=theme-color]').content,
        header: document.querySelector ('header.page h1').textContent,
        subTitle: document.querySelector ('body > header.subpage gr-subpage-title').textContent,
        subBackURL: document.querySelector ('body > header.subpage a').pathname,
      };
    });
  })->then (sub {
    my $res = $_[0];
    my $values = $res->json->{value};
    test {
      use utf8;
      is $values->{config_url}, '/g/'.$current->o ('g1')->{group_id}.'/config';
      is $values->{title}, '設定 - ' . $current->o ('t1');
      is $values->{header}, $current->o ('t1');
      ok $values->{theme_color};
      is $values->{subTitle}, '設定';
      is $values->{subBackURL}, '/g/' . $current->o ('g1')->{group_id} . '/';
    } $current->c;
  });
} n => 6, name => ['page'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      members => ['a1'],
      title => $current->generate_text (t1 => {}),
      theme => 'abcdef',
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'config'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'form[action="edit.json"] button[type=submit]:enabled',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'form[action="edit.json"] select option[value=red]',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      var form = document.querySelector ('form[action="edit.json"]');
      return [
        form.querySelector ('input[name=title]').value,
        form.querySelector ('[name=theme]').getAttribute ('value'),
      ];
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->json->{value}->[0], $current->o ('t1');
      is $res->json->{value}->[1], 'abcdef';
    } $current->c;
  })->then (sub {
    return $current->b (1)->execute (q{
      var form = document.querySelector ('form[action="edit.json"]');
      form.querySelector ('input[name=title]').value = arguments[0];
      var select = form.querySelector ('select#edit-theme');

      // select editing
      select.value = arguments[1];
      select.dispatchEvent (new Event ('change', {bubbles: true}));

      form.querySelector ('button[type=submit]').click ();
    }, [$current->generate_text (t1 => {}), 'red']);
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'form[action="edit.json"] button[type=submit]:enabled',
    });
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $g = $result->{json}->{group};
      is $g->{title}, $current->o ('t1');
      is $g->{theme}, 'red';
    } $current->c;
  });
} n => 4, name => ['edit'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {members => ['a1']}],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'config'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#create-blog form button[type=submit]:enabled',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      var form = document.querySelector ('#create-blog form');
      form.querySelector ('input[name=title]').value = arguments[0];
      form.querySelector ('button[type=submit]').click ();
    }, [$current->generate_text (t1 => {})]);
  })->then (sub {
    return $current->b_wait (1 => {
      name => 'redirected to index config',
      code => sub {
        return $current->b (1)->url->then (sub {
          my $url = $_[0];
          return $url->stringify =~ m{/i/};
        });
      },
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#edit-form input[name=title]:valid',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      var form = document.querySelector ('#edit-form');
      return form.querySelector ('input[name=title]').value;
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->json->{value}, $current->o ('t1');
    } $current->c;
  });
} n => 1, name => ['create an index (blog)'], browser => 1;

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
      url => ['g', $current->o ('g1')->{group_id}, 'config'],
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
      my $g = $result->{json}->{group};
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
      my $g = $result->{json}->{group};
      is $g->{icon_object_id}, $current->o ('o1')->{object_id};
    } $current->c;
});
} n => 6, name => ['edit icon'], browser => 1;

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
