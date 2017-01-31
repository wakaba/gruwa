use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->are_errors (
      ['POST', ['jump', 'ping.json'], {
        url => qq<https://hoge.\x{4000}fuga.test/a/\x{50036}b/%41?abc#x%39 >,
      }, account => 'a1'],
      [
        {method => 'GET', status => 405},
        {origin => undef, status => 400},
        {origin => 'http://test', status => 400},
        {account => undef, status => 403},
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
    return $current->get_json (['jump', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item = $result->{json}->{items}->[0];
      is $item->{score}, 1;
    } $current->c;
    return $current->post_json (['jump', 'ping.json'], {
      url => qq<https://test/a/\x{50036}b/%41?aa.abc#x%39 >,
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['jump', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item = $result->{json}->{items}->[0];
      is $item->{score}, 2;
    } $current->c;
  });
} n => 5, name => 'ping.json';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->post_json (['jump', 'add.json'], {
      url => qq<https://hoge.\x{4000}fuga.test/a/\x{50036}b/%41?abc#x%39 >,
      label => qq{\x{5000}ab },
    }, account => 'a1');
  })->then (sub {
    return $current->post_json (['jump', 'ping.json'], {
      url => qq<https://hoge.\x{4000}fuga.test:x/a/\x{50036}b/%41?abc#x%39 >,
    }, account => 'a1');
  })->then (sub {
    return $current->post_json (['jump', 'ping.json'], {
      url => qq<ftp://hoge.\x{4000}fuga.test/a/\x{50036}b/%41?abc#x%39 >,
    }, account => 'a1');
  })->then (sub {
    return $current->post_json (['jump', 'ping.json'], {
      url => q<mailto:foo@bar>,
    }, account => 'a1');
  })->then (sub {
    return $current->post_json (['jump', 'ping.json'], {
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['jump', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item1 = $result->{json}->{items}->[0];
      is $item1->{score}, 0;
    } $current->c;
  });
} n => 2, name => 'ping.json nop';

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
