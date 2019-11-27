use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  my $site1 = 'https://' . rand . '.test/foo1/';
  my $site2 = 'https://' . rand . '.test/foo2/';
  my $page1 = $site1 . rand;
  my $page2 = $site2 . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
      source_page => $page1,
      source_site => $site1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    $current->set_o (o1 => $_[0]->{json});
    return $current->post_json (['o', 'create.json'], {
      source_page => $page2,
      source_site => $site2,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    $current->set_o (o2 => $_[0]->{json});
    return $current->get_json (['imported', 'sites.json'], {
    }, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $sites = $result->{json}->{sites};
      is 0+@$sites, 2;
      ok grep { $_ eq $site1 } @$sites;
      ok grep { $_ eq $site2 } @$sites;
    } $current->c;
    return $current->are_errors (
      ['GET', ['imported', 'sites.json'], {
      }, account => 'a1', group => 'g1'],
      [
        {path => ['g', '454544', 'imported', 'sites.json'], group => undef, status => 404},
        {account => '', status => 403},
        {account => undef, status => 403},
      ],
    );
  });
} n => 4, name => 'imported source sites';

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

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
<https://www.gnu.org/licenses/>.

=cut
