use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

## See |dashboard.t|.

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->are_errors (
      ['GET', ['jump', 'abc'], {}],
      [
        {account => undef, status => 403},
        {account => 'a1', status => 404},
        {account => 'a1', path => ['jump', ''], status => 404},
      ],
    );
  });
} n => 1, name => '/jump/...';

RUN;

=head1 LICENSE

Copyright 2017-2019 Wakaba <wakaba@suikawiki.org>.

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
