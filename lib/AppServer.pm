package AppServer;
use strict;
use warnings;
use Warabe::App;
push our @ISA, qw(Warabe::App);

sub new_from_http_and_config ($$$) {
  my $self = $_[0]->new_from_http ($_[1]);
  $self->{app_config} = $_[2];
  return $self;
} # new_from_http_and_config

sub config ($) {
  return $_[0]->{app_config};
} # config

sub rev ($) {
  return $_[0]->{app_config}->{git_sha};
} # rev

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
