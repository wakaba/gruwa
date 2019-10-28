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
    }],
    [i1 => index => {
      group => 'g1', account => 'a1',
    }],
    [g2 => group => {
      members => ['a1'], title => $current->generate_text (t2 => {}),
    }],
  )->then (sub {
    return $current->post_json (['i', $current->o ('i1')->{index_id}, 'my.json'], {
      is_default => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->create_browser (1 => {
      url => ['dashboard', 'groups'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t1'),
      name => 'group list (name1)',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main',
      text => $current->o ('t2'),
      name => 'group list (name2)',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main a.default-index-button:not([hidden])',
      html => '/g/'.$current->o ('g1')->{group_id}.'/i/'.$current->o ('i1')->{index_id},
      name => 'default index link (i1)',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'page-main a.default-index-button[hidden]',
      not => 1, shown => 1,
      name => 'default index link (group2)',
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
      is $values->{title}, "\x{2066}グループ\x{2069} - \x{2066}Gruwa\x{2069}";
      is $values->{url}, '/dashboard/groups';
      is $values->{headerTitle}, 'ダッシュボード';
      is $values->{headerURL}, '/dashboard';
      is $values->{headerLink}, $values->{headerURL};
    } $current->c;
    return $current->b (1)->execute (q{
      var t = document.querySelector ('#create-title');
      t.value = arguments[0];
      t.form.removeAttribute ('data-prompt');
      t.form.querySelector ('button[type=submit]').click ();
    }, [$current->generate_text (t4 => {})]);
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'header.page',
      text => $current->o ('t4'),
      name => 'new group title',
    });
  })->then (sub {
    return $current->b (1)->url;
  })->then (sub {
    my $url = $_[0];
    test {
      ok $url->stringify =~ m{/g/([0-9]+)/};
      $current->set_o (g3 => {group_id => $1});
    } $current->c;
    return $current->get_json (['i', 'list.json'], {}, account => 'a1', group => 'g3');
  })->then (sub {
    my $result = $_[0];
    test {
      my $indexes = $result->{json}->{index_list};
      my $wikis = [grep { $_->{index_type} == 2 } values %$indexes];
      is 0+@$wikis, 1;
      ok $wikis->[0]->{title};
      my $files = [grep { $_->{index_type} == 6 } values %$indexes];
      is 0+@$files, 1;
      ok $files->[0]->{title};
      is $files->[0]->{subtype}, 'icon';
    } $current->c;
  });
} n => 11, name => ['initial load'], browser => 1;

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
