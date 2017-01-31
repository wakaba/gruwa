use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->are_errors (
      ['POST', ['jump', 'add.json'], {
        url => qq<https://hoge.\x{4000}fuga.test/a/\x{50036}b/%41?abc#x%39 >,
        label => qq{\x{5000}ab },
      }, account => 'a1'],
      [
        {method => 'GET', status => 405},
        {origin => undef, status => 400},
        {origin => 'http://test', status => 400},
        {account => undef, status => 403},
        {params => {}, status => 400},
        {params => {url => q<ftp://foo/bar>}, status => 400},
        {params => {url => q<about:blank>}, status => 400},
        {params => {url => q<https://hoge:abc>}, status => 400},
      ],
    );
  })->then (sub {
    return $current->post_json (['jump', 'add.json'], {
      url => qq<https://hoge.\x{4000}fuga.test/a/\x{50036}b/%41?abc#x%39 >,
      label => qq{\x{5000}ab },
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['jump', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item1 = $result->{json}->{items}->[0];
      is $item1->{url}, q</a/%F1%90%80%B6b/A#x%39>;
      is $item1->{score}, 0;
      is $item1->{label}, qq{\x{5000}ab };
    } $current->c;
  });
} n => 5, name => 'add.json';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->post_json (['jump', 'add.json'], {
      url => qq<https://hoge.\x{4000}fuga.test/a/\x{50036}b/%41?abc#x%39 >,
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['jump', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $item1 = $result->{json}->{items}->[0];
      is $item1->{url}, q</a/%F1%90%80%B6b/A#x%39>;
      is $item1->{label}, q</a/%F1%90%80%B6b/A#x%39>;
    } $current->c;
  });
} n => 2, name => 'add.json default label';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->post_json (['jump', 'add.json'], {
      url => qq<https://hoge.\x{4000}fuga.test/a/\x{50036}b/%41?abc#x%39 >,
      label => q<abcd>,
    }, account => 'a1');
  })->then (sub {
    return $current->post_json (['jump', 'add.json'], {
      url => qq<https://hoge.test/a/\x{50036}b/%41?abc#x%39 >,
      label => q<xyaa>,
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['jump', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $item1 = $result->{json}->{items}->[0];
      is $item1->{url}, q</a/%F1%90%80%B6b/A#x%39>;
      is $item1->{label}, q<xyaa>;
    } $current->c;
  });
} n => 2, name => 'add.json updates';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_account (a2 => {});
  })->then (sub {
    return $current->post_json (['jump', 'add.json'], {
      url => qq<https://hoge.\x{4000}fuga.test/a/\x{50036}b/%41?abc#x%39 >,
      label => qq{\x{5000}ab },
    }, account => 'a1');
  })->then (sub {
    return $current->post_json (['jump', 'add.json'], {
      url => qq<https://hoge.\x{4000}fuga.test/a/\x{50036}b/%41?abc#x%39 >,
      label => qq{abcde},
    }, account => 'a2');
  })->then (sub {
    return $current->get_json (['jump', 'list.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item1 = $result->{json}->{items}->[0];
      is $item1->{url}, q</a/%F1%90%80%B6b/A#x%39>;
      is $item1->{label}, qq{\x{5000}ab };
    } $current->c;
  })->then (sub {
    return $current->get_json (['jump', 'list.json'], {}, account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item1 = $result->{json}->{items}->[0];
      is $item1->{url}, q</a/%F1%90%80%B6b/A#x%39>;
      is $item1->{label}, qq{abcde};
    } $current->c;
  });
} n => 6, name => 'add.json users';

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
