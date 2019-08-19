use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

for my $path (
  [''],
  ['members'],
  ['config'],
  ['search'],
  ['wiki', rand],
  ['my', 'config'],
) {
  Test {
    my $current = shift;
    return $current->create (
      [a1 => account => {}],
      [a2 => account => {}],
      [g1 => group => {
        title => $current->generate_text (t1 => {}),
        owner => 'a1',
        members => ['a2'],
      }],
    )->then (sub {
      return $current->are_errors (
        ['GET', ['g', $current->o ('g1')->{group_id}, @$path], {}, account => 'a1'],
        [
          {path => ['g', int rand 10000, @$path],
           name => 'Group not found',  status => 404},
          {path => ['g', 0 . $current->o ('g1')->{group_id}, @$path],
           name => 'Leading zero', status => 404},
          {account => '', status => 403, name => 'Not a member'},
          {account => undef, status => 302, name => 'No account'},
        ],
      );
    })->then (sub {
      return promised_for {
        my $account = shift;
        return $current->get_html ($path, {}, account => $account, group => 'g1');
      } ['a1', 'a2'];
    })->then (sub {
      test {
        ok 1;
      } $current->c;
    });
  } n => 2, name => $path;
}

for my $path (
  [''],
  ['config'],
  ['wiki', rand],
) {
  Test {
    my $current = shift;
    return $current->create (
      [a1 => account => {}],
      [a2 => account => {}],
      [g1 => group => {
        title => $current->generate_text (t1 => {}),
        owner => 'a1',
        members => ['a2'],
      }],
    )->then (sub {
      return $current->are_errors (
        ['GET', ['g', $current->o ('g1')->{group_id}, 'i', 425533, @$path], {}, account => 'a1'],
        [
          {path => ['g', int rand 10000, 'i', 425533, @$path],
           name => 'Group not found', status => 404},
          {path => ['g', 0 . $current->o ('g1')->{group_id}, 'i', 425533, @$path],
           name => 'Leading zero', status => 404},
          {path => ['g', $current->o ('g1')->{group_id}, 'i', '0425533', @$path],
           name => 'Leading zero', status => 404},
          {account => '', status => 403, name => 'Not a member'},
          {account => undef, status => 302, name => 'No account'},
        ],
      );
    })->then (sub {
      return promised_for {
        my $account = shift;
        return $current->get_html (['i', 425533, @$path], {}, account => $account, group => 'g1');
      } ['a1', 'a2'];
    })->then (sub {
      test {
        ok 1;
      } $current->c;
    });
  } n => 2, name => ['i', 425533, @$path];
}

for my $path (
  [''],
) {
  Test {
    my $current = shift;
    return $current->create (
      [a1 => account => {}],
      [a2 => account => {}],
      [g1 => group => {
        title => $current->generate_text (t1 => {}),
        owner => 'a1',
        members => ['a2'],
      }],
    )->then (sub {
      return $current->are_errors (
        ['GET', ['g', $current->o ('g1')->{group_id}, 'account', 425533, @$path], {}, account => 'a1'],
        [
          {path => ['g', int rand 10000, 'account', 425533, @$path],
           name => 'Group not found', status => 404},
          {path => ['g', 0 . $current->o ('g1')->{group_id}, 'account', 425533, @$path],
           name => 'Leading zero', status => 404},
          {path => ['g', $current->o ('g1')->{group_id}, 'account', '0425533', @$path],
           name => 'Leading zero', status => 404},
          {account => '', status => 403, name => 'Not a member'},
          {account => undef, status => 302, name => 'No account'},
        ],
      );
    })->then (sub {
      return promised_for {
        my $account = shift;
        return $current->get_html (['account', 425533, @$path], {}, account => $account, group => 'g1');
      } ['a1', 'a2'];
    })->then (sub {
      test {
        ok 1;
      } $current->c;
    });
  } n => 2, name => ['account', 425533, @$path];
}

for my $path (
  [''],
  ['revisions'],
) {
  Test {
    my $current = shift;
    return $current->create (
      [a1 => account => {}],
      [a2 => account => {}],
      [g1 => group => {
        title => $current->generate_text (t1 => {}),
        owner => 'a1',
        members => ['a2'],
      }],
    )->then (sub {
      return $current->are_errors (
        ['GET', ['g', $current->o ('g1')->{group_id}, 'o', 425533, @$path], {}, account => 'a1'],
        [
          {path => ['g', int rand 10000, 'o', 425533, @$path],
           name => 'Group not found', status => 404},
          {path => ['g', 0 . $current->o ('g1')->{group_id}, 'o', 425533, @$path],
           name => 'Leading zero', status => 404},
          {path => ['g', $current->o ('g1')->{group_id}, 'o', '0425533', @$path],
           name => 'Leading zero', status => 404},
          {account => '', status => 403, name => 'Not a member'},
          {account => undef, status => 302, name => 'No account'},
        ],
      );
    })->then (sub {
      return promised_for {
        my $account = shift;
        return $current->get_html (['o', 425533, @$path], {}, account => $account, group => 'g1');
      } ['a1', 'a2'];
    })->then (sub {
      test {
        ok 1;
      } $current->c;
    });
  } n => 2, name => ['o', 425533, @$path];
}

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [g1 => group => {
      title => $current->generate_text (t1 => {}),
      owner => 'a1',
      members => ['a2'],
    }],
  )->then (sub {
    return $current->are_errors (
      ['GET', ['g', $current->o ('g1')->{group_id}, ''], {}, account => 'a1'],
      [
        {path => ['g', $current->o ('g1')->{group_id}, 'wiki', ''],
         status => 404},
        {path => ['g', $current->o ('g1')->{group_id}, 'i', 5444, 'wiki', ''],
         status => 404},
      ],
    );
  });
} n => 1, name => '404';

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
