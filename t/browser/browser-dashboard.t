use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['dashboard'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'header.page gr-menu a',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'body > header.subpage',
      not => 1, shown => 1,
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
      is $values->{title}, "\x{2066}ダッシュボード\x{2069} - \x{2066}Gruwa\x{2069}";
      is $values->{url}, '/dashboard';
      is $values->{headerTitle}, 'ダッシュボード';
      is $values->{headerURL}, '/dashboard';
      is $values->{headerLink}, $values->{headerURL};
    } $current->c;
  });
} n => 5, name => ['initial load'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['dashboard'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      var link = document.createElement ('a');
      link.href = 'http://xs.server.test/abcde';
      document.body.appendChild (link);
      link.click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'gr-backdrop .dialog .buttons a[target=_top]',
      shown => 1,
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      setTimeout (() => document.querySelector ('gr-backdrop .dialog .buttons a[target=_top]').click (), 0);
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html',
      text => 'abcde',
    });
  })->then (sub {
    return $current->b (1)->url;
  })->then (sub {
    my $url = $_[0];
    test {
      is $url->stringify, 'http://xs.server.test/abcde';
    } $current->c;
  })->then (sub {
    return $current->b (1)->execute (q{
      return {referrer: document.referrer};
    });
  })->then (sub {
    my $values = $_[0]->json->{value};
    test {
      is $values->{referrer}, '';
    } $current->c;
  });
} n => 2, name => ['external link'], browser => 1;

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
