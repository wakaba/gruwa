use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a3 => account => {}],
    [g1 => group => {
      owner => 'a1',
      members => ['a3'],
    }],
  )->then (sub {
    return $current->are_errors (
      ['POST', ['g', $current->o ('g1')->{group_id}, 'my', 'edit.json'], {}, account => 'a1'],
      [
        {path => ['g', int rand 10000, 'edit.json'], status => 404},
        {account => '', status => 403},
        {account => undef, status => 403},
        {method => 'GET', status => 405},
        {origin => undef, status => 400},
      ],
    );
  })->then (sub {
    return promised_for {
      my $account = shift;
      return $current->post_json (['g', $current->o ('g1')->{group_id}, 'my', 'edit.json'], {
        name => $current->generate_text ('name'.$account => {}),
      }, account => $account)->then (sub {
        return $current->post_json (['g', $current->o ('g1')->{group_id}, 'my', 'edit.json'], {
        }, account => $account); # nop
      })->then (sub {
        return $current->get_json (['g', $current->o ('g1')->{group_id}, 'my', 'info.json'], {
        }, account => $account);
      })->then (sub {
        my $result = $_[0];
        test {
          my $acc = $result->{json}->{account};
          is $acc->{name}, $current->o ('name'.$account);
        } $current->c;
      });
    } ['a1', 'a3'];
  });
} n => 1+2*1, name => '/g/{}/my/edit.json name';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      owner => 'a1',
    }],
    [o1 => object => {account => 'a1', group => 'g1'}],
  )->then (sub {
    return $current->post_json (['my', 'edit.json'], {
      icon_object_id => $current->o ('o1')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->are_errors (
      ['POST', ['my', 'edit.json'], {}, account => 'a1', group => 'g1'],
      [
        {params => {icon_object_id => 41253}, status => 400},
      ],
    );
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{account}->{icon_object_id}, $current->o ('o1')->{object_id};
      like $result->{res}->body_bytes, qr{"icon_object_id"\s*:\s*"};
    } $current->c;
  });
} n => 3, name => 'edit icon_object_id';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [g1 => group => {
      owner => 'a1',
    }],
    [o1 => object => {account => 'a1', group => 'g1'}],
  )->then (sub {
    return $current->post_json (['my', 'edit.json'], {
      guide_object_id => $current->o ('o1')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->are_errors (
      ['POST', ['my', 'edit.json'], {}, account => 'a1', group => 'g1'],
      [
        {params => {guide_object_id => 41253}, status => 400},
      ],
    );
  })->then (sub {
    return $current->get_json (['my', 'info.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{account}->{guide_object_id}, $current->o ('o1')->{object_id};
      like $result->{res}->body_bytes, qr{"guide_object_id"\s*:\s*"};
    } $current->c;
  });
} n => 3, name => 'edit guide_object_id';

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
