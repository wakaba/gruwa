package CurrentTest;
use strict;
use warnings;
use JSON::PS;
use Web::URL;
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

sub accounts_client ($) {
  my $self = $_[0];
  return $self->{accounts_client}
      ||= Web::Transport::ConnectionClient->new_from_url ($self->{accounts_url});
} # accounts_client

sub create_account ($$$) {
  my ($self, $name => $account) = @_;
  $account->{name} //= rand;
  return $self->accounts_client->request (
    method => 'POST',
    path => ['create-for-test'],
    params => {
      data => perl2json_chars $account,
    },
  )->then (sub {
    die $_[0] unless $_[0]->status == 200;
    $self->{objects}->{$name} = json_bytes2perl $_[0]->body_bytes;
  });
} # create_account

sub resolve ($$) {
  my $self = shift;
  return Web::URL->parse_string (shift, $self->{url});
} # resolve

sub o ($$) {
  return $_[0]->{objects}->{$_[1]} // die "No object |$_[1]|";
} # o

sub close ($) {
  my $self = shift;
  return Promise->all ([
    defined $self->{client} ? $self->{client}->close : undef,
    defined $self->{accounts_client} ? $self->{accounts_client}->close : undef,
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
