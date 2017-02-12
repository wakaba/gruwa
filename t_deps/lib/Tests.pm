package Tests;
use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child
    ('t_deps/modules/*/lib');
use Test::More;
use Test::X1;
use File::Temp qw(tempdir);
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
  my $tempdir = tempdir (CLEANUP => 1);
  my $work_path = path ($tempdir);
  my $stop = TestServers->servers (
    work_path => $work_path,
    config => {
      storage => {
        #aws4
        #url
        bucket => rand,
      },
    },
    onaccounts => sub {
      $AccountsData = shift;
    },
    onurl => sub {
      $ServerURL = shift;
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
