use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [a3 => account => {}],
    [g1 => group => {
      members => ['a1', 'a2', 'a3'],
    }],
    [o1 => object => {
      group => 'g1', account => 'a1',
    }],
  )->then (sub {
    return $current->post_json (['my', 'edit.json'], {
      name => $current->generate_text (t2 => {}),
    }, group => 'g1', account => 'a2');
  })->then (sub {
    return $current->post_json (['my', 'edit.json'], {
      name => $current->generate_text (t3 => {}),
    }, group => 'g1', account => 'a3');
  })->then (sub {
    return $current->add_star ({object => 'o1', delta => 13,
                                account => 'a2', group => 'g1'});
  })->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'o', $current->o ('o1')->{object_id}, ''],
      account => 'a3',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '.object-info gr-stars',
      html => $current->o ('t2'),
      name => 'star author account name',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('.object-info gr-stars .add-star-button').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '.object-info gr-stars',
      html => $current->o ('t3'),
      name => 'star author account name (new)',
    });
  })->then (sub {
    return $current->b_wait (1 => {code => sub {
      return $current->get_json (['star', 'list.json'], {
        o => $current->o ('o1')->{object_id},
      }, account => 'a1', group => 'g1')->then (sub {
        my $result = $_[0];
        my $stars = $result->{json}->{items}->{$current->o ('o1')->{object_id}};
        return 0+@$stars == 2;
      });
    }, name => 'new star added'});
  })->then (sub {
    return $current->get_json (['star', 'list.json'], {
      o => $current->o ('o1')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $stars = $result->{json}->{items}->{$current->o ('o1')->{object_id}};
      is 0+@$stars, 2;
      is $stars->[0]->{count}, 13;
      is $stars->[1]->{count}, 1;
    } $current->c;
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('.object-info gr-stars .remove-star-button').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {code => sub {
      return $current->get_json (['star', 'list.json'], {
        o => $current->o ('o1')->{object_id},
      }, account => 'a1', group => 'g1')->then (sub {
        my $result = $_[0];
        my $stars = $result->{json}->{items}->{$current->o ('o1')->{object_id}};
        return 0+@$stars == 1;
      });
    }, name => 'star removed'});
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '.object-info gr-stars gr-star-item',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => '.object-info gr-stars',
      html => $current->o ('t3'),
      not => 1,
      name => 'star removed',
    });
  });
} n => 3, name => ['object stars'], browser => 1;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [a3 => account => {}],
    [g1 => group => {
      members => ['a1', 'a2', 'a3'],
    }],
    [o1 => object => {
      group => 'g1', account => 'a1',
    }],
    [o2 => object => {
      group => 'g1', account => 'a1', parent_object => 'o1',
    }],
  )->then (sub {
    return $current->post_json (['my', 'edit.json'], {
      name => $current->generate_text (t2 => {}),
    }, group => 'g1', account => 'a2');
  })->then (sub {
    return $current->post_json (['my', 'edit.json'], {
      name => $current->generate_text (t3 => {}),
    }, group => 'g1', account => 'a3');
  })->then (sub {
    return $current->add_star ({object => 'o2', delta => 13,
                                account => 'a2', group => 'g1'});
  })->then (sub {
    return $current->create_browser (1 => {
      url => ['g', $current->o ('g1')->{group_id}, 'o', $current->o ('o1')->{object_id}, ''],
      account => 'a3',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'html:not([data-navigating])',
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments gr-stars',
      html => $current->o ('t2'),
      name => 'star author account name',
    });
  })->then (sub {
    return $current->b (1)->execute (q{
      document.querySelector ('article-comments gr-stars .add-star-button').click ();
    });
  })->then (sub {
    return $current->b_wait (1 => {
      selector => 'article-comments gr-stars',
      html => $current->o ('t3'),
      name => 'star author account name (new)',
    });
  })->then (sub {
    return $current->b_wait (1 => {code => sub {
      return $current->get_json (['star', 'list.json'], {
        o => $current->o ('o2')->{object_id},
      }, account => 'a1', group => 'g1')->then (sub {
        my $result = $_[0];
        my $stars = $result->{json}->{items}->{$current->o ('o2')->{object_id}};
        return 0+@$stars == 2;
      });
    }, name => 'new star added'});
  })->then (sub {
    return $current->get_json (['star', 'list.json'], {
      o => $current->o ('o2')->{object_id},
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $stars = $result->{json}->{items}->{$current->o ('o2')->{object_id}};
      is 0+@$stars, 2;
      is $stars->[0]->{count}, 13;
      is $stars->[1]->{count}, 1;
    } $current->c;
  });
} n => 3, name => ['comment object stars'], browser => 1;

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
