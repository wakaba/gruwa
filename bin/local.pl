use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/lib');
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
BEGIN {
  $ENV{WEBUA_DEBUG} //= 1;
  $ENV{WEBSERVER_DEBUG} //= 1;
  $ENV{PROMISED_COMMAND_DEBUG} //= 1;
  $ENV{SQL_DEBUG} //= 1;
}
use JSON::PS;
use TestServers;

my $RootPath = path (__FILE__)->parent->parent->absolute;
my $Port = 5521;
my $DBName = 'gruwa_local';

my $Config = json_bytes2perl $RootPath->child ('config/local.json')->slurp;
my $keys = json_bytes2perl $RootPath->child ('local/local-keys.json')->slurp;
for my $name (keys %$keys) {
  my $c = $Config;
  my @name = split /\./, $name;
  my $n = pop @name;
  for (@name) {
    $c = $c->{$_} ||= {};
  }
  $c->{$n} = $keys->{$name};
}

my $stop = TestServers->servers (
  port => $Port,
  db_name => $DBName,
  db_dir => $RootPath->child ('local/local/mysqld'),
  migration_status_file => $RootPath->child ('local/local/migration.json'),
  dumped_file => $RootPath->child ('local/local/dumped.sql'),
  storage_data_path => $RootPath->child ('local/local/minic/data'),
  storage_config_path => $RootPath->child ('local/local/minic/config'),
  config => $Config,
)->to_cv->recv->[1];

warn "Server is ready: <http://localhost:$Port>\n";

$stop->()->to_cv->recv;

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
