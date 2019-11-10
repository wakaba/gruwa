use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  $current->generate_email_addr (e1 => {});
  return $current->create (
    [a1 => account => {email => [$current->o ('e1')]}],
    [a2 => account => {}],
    [g1 => group => {members => ['a1', 'a2'],
                     title => $current->generate_text (t1 => {})}],
    [o1 => object => {group => 'g1', account => 'a1',
                      title => $current->generate_text (t2 => {})}],
  )->then (sub {
    return $current->reset_email_count ('e1');
  })->then (sub {
    return $current->post_json (['star', 'add.json'], {
      object_id => $current->o ('o1')->{object_id},
      delta => 24,
    }, account => 'a2', group => 'g1');
  })->then (sub {
    return $current->get_email ('e1');
  })->then (sub {
    my $item = $_[0];
    test {
      is $item->{from}, 'info@gruwa.test';
      is $item->{to}, $current->o ('e1');
      my $msg = $item->{message};
      $msg =~ s/=([0-9A-F]{2})/pack 'C', hex $1/ge;
      $msg = decode_web_utf8 $msg;
      #warn $msg;
      like $msg, qr{daily-report};
      like $msg, qr{\Q@{[$current->o ('t1')]}\E};
      like $msg, qr{\Qhttp://app.server.test/g/@{[$current->o ('g1')->{group_id}]}/\E};
      like $msg, qr{\Q@{[$current->o ('t2')]}\E};
      like $msg, qr{\Qhttp://app.server.test/g/@{[$current->o ('g1')->{group_id}]}/o/@{[$current->o ('o1')->{object_id}]}/\E};
      like $msg, qr{<data>24</data>};
    } $current->c;
  });
} n => 8, name => 'daily report (star)';

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
