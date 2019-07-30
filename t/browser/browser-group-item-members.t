use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {
      name => $current->generate_text (t2 => {}),
    }],
    [g1 => group => {
      members => ['a1'],
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'members'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#members table',
      text => $current->o ('t2'),
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#invite form',
      not => 1,
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#invitations table',
      not => 1,
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#members .edit-button',
      not => 1, shown => 1,
    });
  })->then (sub {
    test {
      ok 1;
    } $current->c;
  });
} n => 1, name => ['page, normal member'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {
      name => $current->generate_text (t2 => {}),
    }],
    [g1 => group => {
      owners => ['a1'],
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'members'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#members table',
      text => $current->o ('t2'),
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#invite form',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#invitations table',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#members .edit-button',
      shown => 1,
    });
  })->then (sub {
    test {
      ok 1;
    } $current->c;
  });
} n => 1, name => ['page, owner'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {
      name => $current->generate_text (t1 => {}),
    }],
    [a2 => account => {
      name => $current->generate_text (t2 => {}),
    }],
    [g1 => group => {
      owners => ['a1'], members => ['a2'],
    }],
  )->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'members'],
      account => 'a1',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#members .edit-button',
      shown => 1,
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '#members table',
      text => $current->o ('t2'),
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      var e = document.querySelector ('gr-account[value="'+arguments[0]+'"]');
      while (e && e.localName !== 'tr') {
        e = e.parentNode;
      }
      return e;
    }, [$current->o ('a2')->{account_id}]);
  })->then (sub {
    $current->set_o (e1 => $_[0]->json->{value});
    return $current->b (1)->execute (q{
      var v = arguments[0].querySelector ('[name=desc]').hidden;
      arguments[0].querySelector ('.edit-button').click ();
      return [v];
    }, [$current->o ('e1')]);
  })->then (sub {
    my $values = $_[0]->json->{value};
    test {
      ok !! $values->[0], 'textarea is hidden before editing';
    } $current->c;
    return $current->b (1)->execute (q{
      var v = arguments[0].querySelector ('[name=desc]').hidden;
      arguments[0].querySelector ('[name=desc]').value = arguments[1];
      arguments[0].querySelector ('.save-button').click ();
      return [v];
    }, [$current->o ('e1'), $current->generate_text (t3 => {})]);
  })->then (sub {
    my $values = $_[0]->json->{value};
    test {
      ok ! $values->[0], 'textarea is not hidden';
    } $current->c;
    return $current->b_wait (1 => {
      selector => 'gr-editable-tr action-status[status=ok]',
    });
  })->then (sub {
    return $current->get_json (['members', 'list.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{json}->{members}->{$current->o ('a2')->{account_id}}->{desc}, $current->o ('t3');
    } $current->c;
  });
} n => 3, name => ['edit member desc'], browser => 1;

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
