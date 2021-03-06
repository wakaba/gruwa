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
      group => 'g1', account => 'a1', index_type => 1, # blog
      theme => 'blue',
      title => $current->generate_text (t2 => {}),
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id},
              'i', $current->o ('i1')->{index_id}, 'config'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-menu[type=index] a[href*="/i/"][href$="/config"]',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return {
        config_url: document.querySelector ('gr-menu[type=index] menu-main a[href$="/config"]').pathname,
        title: document.title,
        theme: document.documentElement.getAttribute ('data-theme'),
        header: document.querySelector ('header.page h1').textContent,
      };
    });
  })->then (sub {
    my $res = $_[0];
    my $values = $res->json->{value};
    test {
      use utf8;
      is $values->{config_url}, '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id}.'/config';
      is $values->{title}, "\x{2066}設定\x{2069} - \x{2066}" . $current->o ('t2') . "\x{2069} - \x{2066}" . $current->o ('t1') . "\x{2069}";
      is $values->{header}, $current->o ('t2');
      is $values->{theme}, 'blue';
    } $current->c;
  });
} n => 4, name => ['page'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {members => ['a1']}],
    [i1 => index => {
      group => 'g1', account => 'a1', index_type => 1, # blog
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'i', $current->o ('i1')->{index_id}, 'config'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'form[action$="edit.json"] button[type=submit]:enabled',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'form[action$="edit.json"] select option[value=red]',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      var form = document.querySelector ('form[action$="edit.json"]');
      form.querySelector ('input[name=title]').value = arguments[0];
      var select = form.querySelector ('select#edit-theme');

      // select editing
      select.value = arguments[1];
      select.dispatchEvent (new Event ('change', {bubbles: true}));

      form.querySelector ('button[type=submit]').click ();
    }, [$current->generate_text (t1 => {}), 'red']);
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'form[action$="edit.json"] button[type=submit]:enabled',
    });
  })->then (sub {
    return $current->get_json (['i', $current->o ('i1')->{index_id}, 'info.json'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $g = $result->{json};
      is $g->{title}, $current->o ('t1');
      is $g->{theme}, 'red';
    } $current->c;
  });
} n => 2, name => ['edit'], browser => 1;

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
