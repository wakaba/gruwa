use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_account (a2 => {});
  })->then (sub {
    return $current->are_errors (
      ['GET', ['jump', 'list.json'], {}, account => 'a1'],
      [
        {account => undef, status => 302},
      ],
    );
  })->then (sub {
    return $current->post_json (['jump', 'add.json'], {
      url => qq<https://hoge.\x{4000}fuga.test/a/\x{50036}b/%41?abc#x%39 >,
      label => qq{\x{5000}ab },
    }, account => 'a1');
  })->then (sub {
    return $current->post_json (['jump', 'ping.json'], {
      url => qq<https://hoge.\x{4000}fuga.test/a/\x{50036}b/%41?abc#x%39 >,
    }, account => 'a1');
  })->then (sub {
    return $current->post_json (['jump', 'add.json'], {
      url => qq<https://hoge.test/ba/44232222/aaaa>,
      label => qq{abv eee 1012222},
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['jump', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 2;
      my $item1 = $result->{json}->{items}->[0];
      is $item1->{url}, q</a/%F1%90%80%B6b/A#x%39>;
      is $item1->{label}, qq{\x{5000}ab };
      is $item1->{score}, 1;
      my $item2 = $result->{json}->{items}->[1];
      is $item2->{url}, q</ba/44232222/aaaa>;
      is $item2->{label}, q<abv eee 1012222>;
      is $item2->{score}, 0;
    } $current->c;
  })->then (sub {
    return $current->get_json (['jump', 'list.json'], {}, account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 0;
    } $current->c, name => 'another user';
  });
} n => 9, name => 'list.json';

RUN;

=head1 LICENSE

Copyright 2017 Wakaba <wakaba@suikawiki.org>.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You does not have received a copy of the GNU Affero General Public
License along with this program, see <http://www.gnu.org/licenses/>.

=cut
