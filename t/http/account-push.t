use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [u1 => account => {}],
  )->then (sub {
    return $current->are_errors (
      ['POST', ['account', 'push', 'add.json'], {
        sub => perl2json_chars ({endpoint => $current->generate_url (e2 => {})}),
      }, account => 'u1', headers => {
        'user-agent' => $current->generate_key (k1 => {}),
      }],
      [
        {method => 'GET', status => 405},
        {origin => undef, status => 400},
        {params => {}, status => 400, name => 'No |url|'},
        {params => {sub => '"abc'}, status => 400, name => 'No |url|'},
        {params => {sub => '"abc"'}, status => 400, name => 'No |url|'},
        {params => {sub => '[]'}, status => 400, name => 'No |url|'},
        {params => {sub => '{}'}, status => 400, name => 'No |url|'},
        {params => {sub => perl2json_chars {endpoint => rand}}, status => 400, name => 'Bad |url|'},
        {params => {sub => perl2json_chars {endpoint => 'ftp://abc/'}}, status => 400, name => 'Bad |url|'},
        {account => undef, status => 403, name => 'No account'},
      ],
    );
  })->then (sub {
    return $current->post_json (['account', 'push', 'add.json'], {
      sub => perl2json_chars {endpoint => $current->generate_url (e1 => {})},
    }, account => 'u1', headers => {
      'user-agent' => $current->generate_key (k1 => {}),
    });
  })->then (sub {
    return $current->get_json (['account', 'push', 'list.json'], {
    }, account => 'u1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
      my $item = $result->{json}->{items}->[0];
      ok $item->{created};
      ok $item->{expires};
      ok $item->{url_sha};
      is $item->{ua}, $current->o ('k1');
      is $item->{url}, undef;
      is $item->{data}, undef;
    } $current->c;
    return $current->get_json (['account', 'push', 'list.json'], {
    }, account => undef);
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 0;
    } $current->c;
  });
} n => 9, name => 'push add / list';

Test {
  my $current = shift;
  return $current->create (
    [u1 => account => {}],
  )->then (sub {
    return $current->post_json (['account', 'push', 'add.json'], {
      sub => perl2json_chars {endpoint => $current->generate_url (e1 => {})},
    }, account => 'u1');
  })->then (sub {
    return $current->get_json (['account', 'push', 'list.json'], {
    }, account => 'u1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
    } $current->c;
    return $current->post_json (['account', 'push', 'delete.json'], {
      url_sha => $result->{json}->{items}->[0]->{url_sha},
    }, account => undef);
  })->then (sub {
    return $current->get_json (['account', 'push', 'list.json'], {
    }, account => 'u1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
    } $current->c, name => 'unchanged';
    return $current->post_json (['account', 'push', 'delete.json'], {
      url_sha => $result->{json}->{items}->[0]->{url_sha},
    }, account => 'u1');
  })->then (sub {
    return $current->get_json (['account', 'push', 'list.json'], {
    }, account => 'u1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 0;
    } $current->c;
  });
} n => 3, name => 'push delete';

Test {
  my $current = shift;
  return $current->create (
    [u1 => account => {}],
  )->then (sub {
    return $current->post_json (['account', 'push', 'add.json'], {
      sub => perl2json_chars {endpoint => $current->generate_url (e1 => {})},
    }, account => 'u1');
  })->then (sub {
    return $current->get_json (['account', 'push', 'list.json'], {
    }, account => 'u1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
    } $current->c;
    return $current->post_json (['account', 'push', 'delete.json'], {
      url => $current->o ('e1'),
    }, account => undef);
  })->then (sub {
    return $current->get_json (['account', 'push', 'list.json'], {
    }, account => 'u1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 1;
    } $current->c, name => 'unchanged';
    return $current->post_json (['account', 'push', 'delete.json'], {
      url => $current->o ('e1'),
    }, account => 'u1');
  })->then (sub {
    return $current->get_json (['account', 'push', 'list.json'], {
    }, account => 'u1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{items}}, 0;
    } $current->c;
  });
} n => 3, name => 'push delete by url';

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
