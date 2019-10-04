use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->get_html (['account', 'agree'])->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('X-Frame-Options'), 'sameorigin';
      is $result->{res}->header ('Set-Cookie'), undef;
    } $current->c;
  });
} n => 2, name => '/account/agree GET';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {terms_version => 2}],
  )->then (sub {
    return $current->are_errors (
      ['POST', ['account', 'agree'], {agree => 1}, account => 'a1'],
      [
        {origin => undef,
         status => 400,
         name => 'Bad |Origin:|'},
        {origin => 'foo',
         status => 400,
         name => 'Bad |Origin:|'},
      ],
    );
  })->then (sub {
    return $current->post_redirect (['account', 'agree'], {
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{terms_version}, 2, 'unchanged';
    } $current->c;
    return $current->post_redirect (['account', 'agree'], {
      agree => 1,
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{terms_version}, 12;
    } $current->c;
    return $current->post_redirect (['account', 'agree'], {
      agree => 1,
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{terms_version}, 12, 'same';
    } $current->c;
    return $current->post_redirect (['account', 'agree'], {
      disagree => 1,
    }, account => 'a1');
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{terms_version}, 1;
    } $current->c;
  });
} n => 5, name => '/account/agree POST';

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
