use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->get_json (['account', 'configsummary.json'])->then (sub {
    my $result = $_[0];
    test {
      ok ! $result->{json}->{email};
      ok ! $result->{json}->{push};
    } $current->c;
  });
} n => 2, name => 'no account';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
  )->then (sub {
    return $current->get_json (['account', 'configsummary.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok ! $result->{json}->{email};
      ok ! $result->{json}->{push};
    } $current->c;
  });
} n => 2, name => 'empty list';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {
      email => [
        $current->generate_email_addr (d1 => {}),
      ],
      terms_version => 1,
    }],
  )->then (sub {
    return $current->get_json (['account', 'configsummary.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok ! $result->{json}->{email};
      ok ! $result->{json}->{push};
    } $current->c;
  });
} n => 2, name => 'has email but bad terms_version';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {
      email => [
        $current->generate_email_addr (d1 => {}),
      ],
    }],
  )->then (sub {
    return $current->get_json (['account', 'configsummary.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok $result->{json}->{email};
      ok ! $result->{json}->{push};
    } $current->c;
  });
} n => 2, name => 'has email';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
  )->then (sub {
    return $current->post_json (['account', 'push', 'add.json'], {
      sub => perl2json_chars {endpoint => $current->generate_url (e1 => {})},
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['account', 'configsummary.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok ! $result->{json}->{email};
      ok $result->{json}->{push};
    } $current->c;
  });
} n => 2, name => 'has push';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {
      email => [
        $current->generate_email_addr (d1 => {}),
      ],
    }],
  )->then (sub {
    return $current->post_json (['account', 'push', 'add.json'], {
      sub => perl2json_chars {endpoint => $current->generate_url (e1 => {})},
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['account', 'configsummary.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok $result->{json}->{email};
      ok $result->{json}->{push};
    } $current->c;
  });
} n => 2, name => 'has email and push';

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
