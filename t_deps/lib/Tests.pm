package Tests;
use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child
    ('t_deps/modules/*/lib');
use AbortController;
use Test::More;
use Test::X1;
use JSON::PS;
use Promise;
use Promised::Flow;
use Exporter::Lite;
use Web::URL;
use Web::URL::Encoding;

use GruwaSS;
use CurrentTest;

our @EXPORT = grep { not /^\$/ }
    @Test::More::EXPORT,
    @Test::X1::EXPORT,
    @Promised::Flow::EXPORT,
    @JSON::PS::EXPORT,
    @Web::URL::Encoding::EXPORT;

my $RootPath = path (__FILE__)->parent->parent->parent;

our $ServerData;
push @EXPORT, qw(Test);
sub Test (&;%) {
  my $code = shift;
  test {
    my $c = shift;
    my $current = CurrentTest->new ({
      c => $c,
      server_data => $ServerData,
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
  note "Servers...";
  my $ac = AbortController->new;
  my $v = GruwaSS->run (
    signal => $ac->signal,
    mysqld_database_name_suffix => '_test',
    app_config_path => $RootPath->child ('config/test.json'),
    accounts_servers_path => $RootPath->child ('t_deps/config/test-accounts-servers.json'),
  )->to_cv->recv;

  note "Tests...";
  local $ServerData = $v->{data};
  run_tests;

  note "Done";
  $ac->abort;
  $v->{done}->to_cv->recv;
} # RUN

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
