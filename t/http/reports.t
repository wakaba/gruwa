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
    [g1 => group => {members => ['a1']}],
  )->then (sub {
    return $current->reset_email_count ('e1');
  })->then (sub {
    return $current->create (
      [o1 => object => {group => 'g1', account => 'a1'}],
    );
  })->then (sub {
    return $current->get_email ('e1');
  })->then (sub {
    my $item = $_[0];
    test {
      is $item->{from}, 'info@gruwa.test';
      is $item->{to}, $current->o ('e1');
      my $msg = $item->{message};
      $msg =~ s/=([0-9A-F]{2})/pack 'C', hex $1/ge;
      #warn $msg;
      like $msg, qr{daily-report};
    } $current->c;
  });
} n => 3, name => 'daily report';

Test {
  my $current = shift;
  $current->generate_email_addr (e1 => {});
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {email => [$current->o ('e1')]}],
    [g1 => group => {members => ['a1', 'a2']}],
  )->then (sub {
    return $current->reset_email_count ('e1');
  })->then (sub {
    return $current->create (
      [o1 => object => {group => 'g1', account => 'a1',
                        called_account => 'a2'}],
    );
  })->then (sub {
    return $current->get_email ('e1', pattern => qr/call-report/);
  })->then (sub {
    my $item1 = $_[0];
    test {
      use utf8;
      is $item1->{from}, 'info@gruwa.test';
      is $item1->{to}, $current->o ('e1');
      my $msg1 = $item1->{message};
      $msg1 =~ s/=([0-9A-F]{2})/pack 'C', hex $1/ge;
      #warn $msg1;
    } $current->c;
  });
} n => 2, name => 'call report';

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
