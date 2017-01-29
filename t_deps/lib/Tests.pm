package Tests;
use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child
    ('t_deps/modules/*/lib');
use Test::More;
use Test::X1;
use JSON::PS;
use Promise;
use Promised::Flow;
use Exporter::Lite;
use Web::URL;
use Web::URL::Encoding;

use TestServers;
use CurrentTest;

our @EXPORT = grep { not /^\$/ }
    @Test::More::EXPORT,
    @Test::X1::EXPORT,
    @Promised::Flow::EXPORT,
    @JSON::PS::EXPORT,
    @Web::URL::Encoding::EXPORT;

{
  use Socket;
  my $EphemeralStart = 1024;
  my $EphemeralEnd = 5000;

  sub is_listenable_port ($) {
    my $port = $_[0];
    return 0 unless $port;
    
    my $proto = getprotobyname('tcp');
    socket(my $server, PF_INET, SOCK_STREAM, $proto) || die "socket: $!";
    setsockopt($server, SOL_SOCKET, SO_REUSEADDR, pack("l", 1)) || die "setsockopt: $!";
    bind($server, sockaddr_in($port, INADDR_ANY)) || return 0;
    listen($server, SOMAXCONN) || return 0;
    close($server);
    return 1;
  } # is_listenable_port

  my $using = {};
  sub find_listenable_port () {
    for (1..10000) {
      my $port = int rand($EphemeralEnd - $EphemeralStart);
      next if $using->{$port}++;
      return $port if is_listenable_port $port;
    }
    die "Listenable port not found";
  } # find_listenable_port
}

my $ServerURL;
my $AccountsData;

push @EXPORT, qw(Test);
sub Test (&;%) {
  my $code = shift;
  test {
    my $c = shift;
    my $current = CurrentTest->new ({
      c => $c,
      url => $ServerURL,
      accounts => $AccountsData,
    });
    Promise->resolve ($current)->then ($code)->catch (sub {
      my $error = $_[0];
      test {
        ok 0, "promise resolved";
        is $error, undef, "no exception";
      } $c;
    })->then (sub {
      done $c;
      return $current->close;
    });
  } @_;
} # Test

push @EXPORT, qw(RUN);
sub RUN () {
  my $port = find_listenable_port;
  $ServerURL = Web::URL->parse_string ("http://localhost:$port");
  my $accounts_port = find_listenable_port;
  my $stop = TestServers->servers (
    port => $port,
    config => {
      origin => $ServerURL->get_origin->to_ascii,
    },
    onaccounts => sub {
      $AccountsData = shift;
    },
  )->to_cv->recv;
  run_tests;
  $stop->[0]->();
  $stop->[1]->()->to_cv->recv;
} # RUN

1;

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
