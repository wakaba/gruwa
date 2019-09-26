package AppServer;
use strict;
use warnings;
use Warabe::App;
push our @ISA, qw(Warabe::App);
use Web::URL;
use Web::Transport::BasicClient;
use JSON::PS;

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

sub accounts ($$$) {
  my ($app, $path, $params) = @_;
  my $accounts = $app->{accounts_client} ||= Web::Transport::BasicClient->new_from_url
      (Web::URL->parse_string ($app->config->{accounts}->{url}));
  return $accounts->request (
    method => 'POST',
    path => $path,
    bearer => $app->config->{accounts}->{key},
    params => $params,
  )->then (sub {
    my $res = $_[0];
    if ($res->status == 200) {
      return json_bytes2perl $res->body_bytes;
    } elsif (not $res->is_network_error and
             ($res->header ('Content-Type') // '') =~ m{^application/json}) {
      my $json = json_bytes2perl $res->body_bytes;
      if (defined $json and ref $json eq 'HASH' and defined $json->{reason}) {
        die $json;
      }
    }
    die $res;
  });
} # accounts

sub close ($) {
  my $self = $_[0];
  return Promise->all ([
    (defined $self->{db} ? $self->{db}->disconnect : undef),
    (defined $self->{accounts_client} ? $self->{accounts_client}->close : undef),
    (defined $self->{apploach_client} ? $self->{apploach_client}->close : undef),
  ]);
} # close

1;

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
