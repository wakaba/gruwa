package CurrentTest;
use strict;
use warnings;
use Web::Transport::ConnectionClient;

sub new ($$) {
  return bless $_[1], $_[0];
} # new

sub c ($) {
  return $_[0]->{c};
} # c

sub client ($) {
  my $self = $_[0];
  return $self->{client}
      ||= Web::Transport::ConnectionClient->new_from_url ($self->{url});
} # client

sub close ($) {
  my $self = shift;
  return Promise->all ([
    defined $self->{client} ? $self->{client}->close : undef,
  ]);
} # close

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
