use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  my $site = 'https://' . rand . '.test/foo/';
  my $site2 = $site;
  $site2 =~ s/^https:/http:/;
  my $page = $site . rand;
  my $page2 = $page;
  $page2 =~ s/^https:/http:/;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {});
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
      source_page => $page,
      source_site => $site,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->set_o (o1 => $_[0]->{json});
  })->then (sub {
    return $current->are_errors (
      ['GET', ['imported', $page, 'go'], {}, group => 'g1', account => 'a1'],
      [
        {account => undef, status => 302, name => 'No account'},
        {account => '', status => 403, name => 'Other account'},
        {group => 'g2', status => 403, name => 'Bad group'},
        {path => ['imported', rand, 'go'], status => 404, name => 'relative'},
        {path => ['imported', 'null', 'go'], status => 404, name => 'relative'},
        {path => ['imported', 'http://foo:bar', 'go'], status => 404, name => 'unparsable'},
        {path => ['imported', 'javascript:alert(1)', 'go'], status => 404, name => 'non http'},
        {path => ['imported', 'https://example.com/', 'go'], status => 404, name => 'non imported'},
      ],
    );
  })->then (sub {
    return $current->get_redirect
        (['imported', $page, 'go'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
          $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/o/' . $current->o ('o1')->{object_id} . '/')->stringify;
    } $current->c;
    return $current->get_redirect
        (['imported', $page2, 'go'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
          $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/o/' . $current->o ('o1')->{object_id} . '/')->stringify;
    } $current->c;
    return $current->get_redirect
        (['imported', $page . '#' . $current->generate_text ('f1'), 'go'], {},
         group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
          $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/o/' . $current->o ('o1')->{object_id} . '/#' . $current->o ('f1'))->stringify;
    } $current->c;
    return $current->get_redirect
        (['imported', $page2 . '#' . $current->generate_text ('f1'), 'go'], {},
         group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
          $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/o/' . $current->o ('o1')->{object_id} . '/#' . $current->o ('f1'))->stringify;
    } $current->c;
    return $current->get_redirect
        (['imported', $site . '/' . $current->generate_text ('p1'), 'go'], {},
         group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'), 
          $current->resolve ($site . '/' . $current->o ('p1'))->stringify;
    } $current->c;
    return $current->get_redirect
        (['imported', $site2 . '/' . $current->generate_text ('p1'), 'go'], {},
         group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'), 
          $current->resolve ($site2 . '/' . $current->o ('p1'))->stringify;
    } $current->c;
  });
} n => 7, name => 'redirecting non-fragment object URL';

Test {
  my $current = shift;
  my $site = 'https://' . rand . '.test/foo/#foo';
  my $site2 = $site;
  $site2 =~ s/^https:/http:/;
  my $page = $site . rand;
  my $page2 = $page;
  $page2 =~ s/^https:/http:/;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
      source_page => $page,
      source_site => $site,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->set_o (o1 => $_[0]->{json});
  })->then (sub {
    return $current->get_redirect
        (['imported', $page, 'go'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
          $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/o/' . $current->o ('o1')->{object_id} . '/')->stringify;
    } $current->c;
    return $current->get_redirect
        (['imported', $page2, 'go'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
          $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/o/' . $current->o ('o1')->{object_id} . '/')->stringify;
    } $current->c;
  });
} n => 2, name => 'redirecting fragment object URL';

Test {
  my $current = shift;
  my $site = 'https://' . rand . '.test/foo/';
  my $site2 = $site;
  $site2 =~ s/^https:/http:/;
  my $page = $site . rand;
  my $page2 = $page;
  $page2 =~ s/^https:/http:/;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->post_json (['i', 'create.json'], {
      index_type => 6,
      title => $current->generate_text,
      source_page => $page,
      source_site => $site,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->set_o (i1 => $_[0]->{json});
  })->then (sub {
    return $current->get_redirect
        (['imported', $page, 'go'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
          $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/i/' . $current->o ('i1')->{index_id} . '/')->stringify;
    } $current->c;
    return $current->get_redirect
        (['imported', $page2, 'go'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
          $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/i/' . $current->o ('i1')->{index_id} . '/')->stringify;
    } $current->c;
  });
} n => 2, name => 'redirecting index URL';

Test {
  my $current = shift;
  my $site = 'https://' . rand . '.g.hatena.ne.jp/';
  my $site2 = $site;
  $site2 =~ s/^https:/http:/;
  my $page = $site . rand . '/' . int rand 10000000;
  my $page2 = $page;
  $page2 =~ s/^https:/http:/;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {});
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
      source_page => $page,
      source_site => $site,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->set_o (o1 => $_[0]->{json});
  })->then (sub {
    return $current->get_redirect
        (['imported', $page, 'go'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
          $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/o/' . $current->o ('o1')->{object_id} . '/')->stringify;
    } $current->c;
    return $current->get_redirect
        (['imported', $page . '/' . $current->generate_text ('t1'), 'go'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
          $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/o/' . $current->o ('o1')->{object_id} . '/#' . $current->o ('t1'))->stringify;
    } $current->c;
    return $current->get_redirect
        (['imported', $page2 . '/' . $current->generate_text ('t2'), 'go'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
          $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/o/' . $current->o ('o1')->{object_id} . '/#' . $current->o ('t2'))->stringify;
    } $current->c;
  });
} n => 3, name => 'hatena group day section URL';

Test {
  my $current = shift;
  my $site = 'https://' . rand . '.g.hatena.ne.jp/';
  my $site2 = $site;
  $site2 =~ s/^https:/http:/;
  my $page = $site . 'files/group/' . int rand 10000000;
  my $page2 = $page;
  $page2 =~ s/^https:/http:/;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {});
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
      source_page => $page,
      source_site => $site,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->set_o (o1 => $_[0]->{json});
  })->then (sub {
    return $current->get_redirect
        (['imported', $page . '.png', 'go'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
          $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/o/' . $current->o ('o1')->{object_id} . '/image')->stringify;
    } $current->c;
    return $current->get_redirect
        (['imported', $page2 . '.png', 'go'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
          $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/o/' . $current->o ('o1')->{object_id} . '/image')->stringify;
    } $current->c;
    return $current->get_redirect
        (['imported', $page . '.dat', 'go'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
          $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/o/' . $current->o ('o1')->{object_id} . '/file')->stringify;
    } $current->c;
    return $current->get_redirect
        (['imported', $page, 'go'], {}, group => 'g1', account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
          $current->resolve ('/g/' . $current->o ('g1')->{group_id} . '/o/' . $current->o ('o1')->{object_id} . '/file')->stringify;
    } $current->c;
  });
} n => 4, name => 'hatena group file URL';

RUN;

=head1 LICENSE

Copyright 2016-2017 Wakaba <wakaba@suikawiki.org>.

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
