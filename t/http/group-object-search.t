use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->are_errors (
      ['GET', ['o', 'search.json'], {}, account => 'a1', group => 'g1'],
      [
        {account => '', status => 403},
        {account => undef, status => 403},
        {path => ['g', '532523', 'o', 'search.json'], status => 404},
      ],
    );
  })->then (sub {
    return $current->get_json (['o', 'search.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is ref $result->{json}->{objects}, 'ARRAY';
      ok $result->{json}->{objects};
    } $current->c;
  });
} n => 3, name => 'no params';

Test {
  my $current = shift;
  my $v1 = rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1',
                                           body => "\x{6000} " . $v1});
  })->then (sub {
    return $current->create_object (o2 => {group => 'g1', account => 'a1',
                                           title => "\x{6000} z",
                                           body => $v1});
  })->then (sub {
    return $current->get_json (['o', 'search.json'], {
      q => "$v1 \x{6000}",
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{objects}}, 2;
      my $o1 = $result->{json}->{objects}->[1];
      is $o1->{object_id}, $current->o ('o1')->{object_id};
      is $o1->{title}, "";
      ok $o1->{updated};
      ok $o1->{snippet};
      my $o2 = $result->{json}->{objects}->[0];
      is $o2->{object_id}, $current->o ('o2')->{object_id};
      is $o2->{title}, "\x{6000} z";
      ok $o2->{updated};
      ok $o2->{snippet};
      like $result->{res}->body_bytes, qr{"object_id"\s*:\s*"};
    } $current->c;
    return $current->get_json (['o', 'search.json'], {
      q => "$v1 \x{6000} -z",
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{objects}}, 1;
      my $o1 = $result->{json}->{objects}->[0];
      is $o1->{object_id}, $current->o ('o1')->{object_id};
      is $o1->{title}, "";
      ok $o1->{updated};
      ok $o1->{snippet};
    } $current->c;
  });
} n => 15;

Test {
  my $current = shift;
  my $v1 = rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_object (o1 => {group => 'g1', account => 'a1',
                                           title => $v1,
                                           body => "\x{6001}"});
  })->then (sub {
    return $current->create_object (o2 => {group => 'g1', account => 'a1',
                                           title => $v1,
                                           body => "\x{6002}"});
  })->then (sub {
    return $current->create_object (o3 => {group => 'g1', account => 'a1',
                                           title => $v1,
                                           body => "\x{6003}"});
  })->then (sub {
    return $current->get_json (['o', 'search.json'], {
      q => $v1,
      limit => 2,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{objects}}, 2;
      my $o1 = $result->{json}->{objects}->[0];
      is $o1->{object_id}, $current->o ('o3')->{object_id};
      my $o2 = $result->{json}->{objects}->[1];
      is $o2->{object_id}, $current->o ('o2')->{object_id};
    } $current->c;
    return $current->get_json (['o', 'search.json'], {
      q => $v1,
      limit => 2,
      ref => $result->{json}->{next_ref},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{objects}}, 1;
      my $o1 = $result->{json}->{objects}->[0];
      is $o1->{object_id}, $current->o ('o1')->{object_id};
    } $current->c;
    return $current->get_json (['o', 'search.json'], {
      q => $v1,
      limit => 2,
      ref => $result->{json}->{next_ref},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is 0+@{$result->{json}->{objects}}, 0;
      ok $result->{json}->{next_ref};
    } $current->c;
  });
} n => 7;

RUN;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

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
