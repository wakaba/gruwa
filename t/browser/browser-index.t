use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create_browser (1 => {url => q</>})->then (sub {
    return $current->b (1)->execute (q{
      return document.body.textContent;
    });
  })->then (sub {
    my $value = $_[0]->json->{value};
    test {
      like $value, qr{Gruwa};
    } $current->c;
  });
} n => 1, name => ['/'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {members => ['a1']}],
  )->then (sub {
    return $current->post_json (['o', 'create.json'], {
      is_file => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    $current->set_o (o1 => $result->{json});
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'upload.json'], {
      token => $current->o ('o1')->{upload_token},
    }, account => 'a1', group => 'g1', headers => {
      'content-type' => 'application/octet-stream',
    }, body => rand);
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      file_size => 525234,
      file_closed => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'o', $current->o ('o1')->{object_id}, 'embed'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'unit-number number-value:not(:empty)',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      return document.querySelector ('unit-number').textContent;
    });
  })->then (sub {
    my $value = $_[0]->json->{value};
    test {
      is $value, '512.9KB';
    } $current->c;
  });
} n => 1, name => ['unit-number.js'], browser => 1;

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
