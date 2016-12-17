package CommonPages;
use strict;
use warnings;

use Results;

sub main ($$$$) {
  my ($class, $app, $path, $db) = @_;

  if ($path->[0] eq '') {
    # /
    return temma $app, 'index.html.tm', {};
  }

  if ($path->[0] eq 'help') {
    # /help
    return temma $app, 'help.html.tm', {};
  }

  return $app->send_error (404);
} # main

1;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

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
