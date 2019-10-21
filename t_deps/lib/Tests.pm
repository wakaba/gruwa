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
use Time::HiRes qw(time);
use Promise;
use Promised::Flow;
use Exporter::Lite;
use Web::Encoding;
use Web::URL;
use Web::URL::Encoding;

use GruwaSS;
use CurrentTest;

our @EXPORT = grep { not /^\$/ }
    @Test::More::EXPORT,
    @Test::X1::EXPORT,
    @Promised::Flow::EXPORT,
    @JSON::PS::EXPORT,
    @Web::Encoding::EXPORT,
    @Web::URL::Encoding::EXPORT,
    'time';

my $RootPath = path (__FILE__)->parent->parent->parent;
my $TestScriptPath = path ($0)->relative ($RootPath->child ('t'));

our $ServerData;
my $NeedBrowser;
push @EXPORT, qw(Test);
sub Test (&;%) {
  my $code = shift;
  my %args = @_;
  $NeedBrowser = 1 if delete $args{browser};
  $args{timeout} //= 120;
  test {
    my $current = CurrentTest->new ({
      context => shift,
      server_data => $ServerData,
      test_script_path => $TestScriptPath,
    });
    Promise->resolve ($current)->then ($code)->catch (sub {
      my $error = $_[0];
      test {
        ok 0, "promise resolved";
        is $error, undef, "no exception";
      } $current->c;
    })->then (sub {
      return $current->done;
    });
  } %args;
} # Test

push @EXPORT, qw(RUN);
sub RUN () {
  note "Servers...";
  my $ac = AbortController->new;
  my $v = GruwaSS->run (
    signal => $ac->signal,
    mysqld_database_name_suffix => '_test',
    app_config_path => $RootPath->child ('config/test.json'),
    apploach_config_path => $RootPath->child ('t_deps/config/test-apploach.json'),
    accounts_servers_path => $RootPath->child ('t_deps/config/test-accounts-servers.json'),
    need_browser => $NeedBrowser,
    browser_type => $ENV{TEST_WD_BROWSER}, # or undef
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
