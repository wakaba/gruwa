use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {owner => 'a1'}],
    [o1 => object => {account => 'a1', group => 'g1'}],
  )->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 2, # plain text
      body => 'abcdef',
    }, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('o1')->{object_id},
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $obj = $result->{json}->{objects}->{$current->o ('o1')->{object_id}};
      is $obj->{data}->{body}, 'abcdef';
      is $obj->{data}->{body_type}, 2;
      is $obj->{data}->{body_source}, undef;
      is $obj->{data}->{body_source_type}, undef;
    } $current->c;
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 2, # plain text
      body => "abcdef https://abc.def/x Q&A<",
    }, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('o1')->{object_id},
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $obj = $result->{json}->{objects}->{$current->o ('o1')->{object_id}};
      is $obj->{data}->{body}, 'abcdef <a href="https://abc.def/x" class=url-link>https://abc.def/x</a> Q&amp;A&lt;';
      is $obj->{data}->{body_type}, 1;
      is $obj->{data}->{body_source}, 'abcdef https://abc.def/x Q&A<';
      is $obj->{data}->{body_source_type}, 4;
    } $current->c;
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      body_type => 2, # plain text
      body => 'abcdef',
    }, group => 'g1', account => 'a1');
  })->then (sub {
    return $current->get_json (['o', 'get.json'], {
      object_id => $current->o ('o1')->{object_id},
      with_data => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $obj = $result->{json}->{objects}->{$current->o ('o1')->{object_id}};
      is $obj->{data}->{body}, 'abcdef';
      is $obj->{data}->{body_type}, 2;
      is $obj->{data}->{body_source}, undef;
      is $obj->{data}->{body_source_type}, undef;
    } $current->c;
  });
} n => 12, name => 'plaintext';

RUN;

=head1 LICENSE

Copyright 2016-2019 Wakaba <wakaba@suikawiki.org>.

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
