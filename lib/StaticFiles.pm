package StaticFiles;
use strict;
use warnings;
use Path::Tiny;
use Promised::File;

my $RootPath = path (__FILE__)->parent->parent;

sub static ($$$) {
  my ($app, $path, $mime) = @_;
  my $file = Promised::File->new_from_path ($RootPath->child (@$path));
  return $file->stat->then (sub {
    return $_[0]->mtime;
  }, sub {
    return $app->throw_error (404, reason_phrase => 'File not found');
  })->then (sub {
    $app->http->set_response_last_modified ($_[0]);
    return $file->read_byte_string->then (sub {
      $app->http->add_response_header ('Content-Type' => $mime);
      $app->http->send_response_body_as_ref (\($_[0]));
      return $app->http->close_response_body;
    });
  });
} # static

sub main ($$$$) {
  my ($class, $app, $path, $db) = @_;

  if (@$path == 2 and
      $path->[0] eq 'css' and $path->[1] =~ /\A[A-Za-z0-9-]+\.css\z/) {
    return static $app, [$path->[0], $path->[1]], 'text/css;charset=utf-8';
  }

  if (@$path == 2 and
      $path->[0] eq 'js' and $path->[1] =~ /\A[A-Za-z0-9-]+\.js\z/) {
    return static $app, [$path->[0], $path->[1]], 'text/javascript;charset=utf-8';
  }

  return $app->throw_error (404);
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
