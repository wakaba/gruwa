package StaticFiles;
use strict;
use warnings;
use Path::Tiny;
use Promised::File;
use Web::DOM::Document;
use Temma::Parser;
use Temma::Processor;

use Results;

my $RootPath = path (__FILE__)->parent->parent;

sub static ($$$) {
  my ($app, $path, $mime) = @_;
  my $file = Promised::File->new_from_path ($RootPath->child (@$path));
  my $r = $app->bare_param ('r');
  return $file->stat->then (sub {
    if (not defined $r or
        $r eq $app->rev) {
      $app->http->set_response_last_modified ($_[0]->mtime);
    } else {
      $app->http->add_response_header ('cache-control', 'no-cache');
    }
    return $file->read_byte_string;
  }, sub {
    return $app->throw_error (404, reason_phrase => 'File not found');
  })->then (sub {
    $app->http->add_response_header ('Content-Type' => $mime);
    if ($mime eq 'text/css;charset=utf-8' and
        defined $r and
        (($r eq $app->rev and $r =~ /\A[0-9A-Za-z.]+\z/) or
         $r =~ /\Alocal-[0-9A-Za-z.]+\z/)) {
      my $x = $_[0];
      $x =~ s{(\@import '[A-Za-z0-9-]+\.css)(';)}{$1?r=$r$2}g;
      $app->http->send_response_body_as_ref (\$x);
    } else {
      $app->http->send_response_body_as_ref (\($_[0]));
    }
    return $app->http->close_response_body;
  });
} # static

my $TemplatePath = path (__FILE__)->parent->parent->child ('templates');
my $HTMLCache = {};

sub temma_html ($$$$$$) {
  my (undef, $app, $mime, $name, $params, $key) = @_;
  my $r = $app->bare_param ('r');
  my $http = $app->http;
  if (defined $HTMLCache->{$name, $key}) {
    if ((not defined $r and not $app->config->{is_local}) or
        $r eq $app->rev) {
      $http->set_response_last_modified ($HTMLCache->{$name, $key}->[0]);
    } else {
      $http->add_response_header ('cache-control', 'no-cache');
    }
    $http->set_response_header ('Content-Type' => $mime.'; charset=utf-8');
    $http->send_response_body_as_ref ($HTMLCache->{$name, $key}->[1]);
    $http->close_response_body;
    return;
  }
  my $path = $TemplatePath->child ($name);
  my $file = Promised::File->new_from_path ($path);
  my $mtime;
  return $file->stat->then (sub {
    if (not defined $r or $r eq $app->rev) {
      $http->set_response_last_modified ($mtime = $_[0]->mtime);
    } else {
      $http->add_response_header ('cache-control', 'no-cache');
    }
    return $file->read_byte_string;
  }, sub {
    return $app->throw_error (404, reason_phrase => 'File not found');
  })->then (sub {
    return Promised::File->new_from_path ($path)->read_char_string;
  })->then (sub {
    my $copy = '';
    my $fh = Results::Temma::Printer->new_from_http ($http, \$copy);
    my $doc = new Web::DOM::Document;
    my $parser = Temma::Parser->new;
    $parser->parse_char_string ($_[0] => $doc);
    my $processor = Temma::Processor->new;
    $processor->oninclude (sub {
      my $x = $_[0];
      my $path = path ($x->{path})->absolute ($TemplatePath);
      my $parser = $x->{get_parser}->();
      $parser->onerror (sub {
        $x->{onerror}->(@_, path => $path);
      });
      return Promised::File->new_from_path ($path)->read_char_string->then (sub {
        my $doc = Web::DOM::Document->new;
        $parser->parse_char_string ($_[0] => $doc);
        return $doc;
      });
    });
    $http->set_response_header ('Content-Type' => $mime.'; charset=utf-8');
    return Promise->new (sub {
      my $ok = $_[0];
      $processor->process_document ($doc => $fh, ondone => sub {
        $http->close_response_body;
        $HTMLCache->{$name, $key} = [$mtime, \$copy];
        undef $fh;
        $ok->();
      }, args => $params);
    });
  });
} # temma_html

sub main ($$$) {
  my ($class, $app, $path) = @_;

  if (@$path == 2 and
      $path->[0] eq 'css' and $path->[1] =~ /\A[A-Za-z0-9-]+\.css\z/) {
    return static $app, [$path->[0], $path->[1]], 'text/css;charset=utf-8';
  }

  if (@$path == 2 and
      $path->[0] eq 'js' and $path->[1] =~ /\A[A-Za-z0-9-]+\.js\z/) {
    if ($path->[1] eq 'sw.js') {
      $app->http->set_response_header ('Service-Worker-Allowed' => '/');
    }
    return static $app, [$path->[0], $path->[1]], 'text/javascript;charset=utf-8';
  }

  if (@$path == 2 and
      $path->[0] eq 'images' and $path->[1] =~ /\A[A-Za-z0-9-]+\.svg\z/) {
    return static $app, [$path->[0], $path->[1]], 'image/svg+xml;charset=utf-8';
  }

  if (@$path == 2 and $path->[0] eq 'theme' and $path->[1] eq 'list.json') {
    # /theme/list.json
    return static $app, ['themes.json'], 'application/json;charset=utf-8';
  }

  if (@$path == 1 and $path->[0] eq 'favicon.ico') {
    # /favicon.ico
    return static $app, ['images', 'group.svg'], 'image/svg+xml;charset=utf-8';
  }


  if (@$path == 1 and $path->[0] eq 'robots.txt') {
    $app->http->set_response_header ('X-Rev' => $app->rev);
    $app->http->set_response_last_modified (1556636400);
    if ($app->config->{is_live} or $app->config->{is_test_script}) {
      return $app->send_plain_text ("User-agent: *\x0ADisallow: /g/\x0ADisallow: /invitation/\x0A");
    } else {
      return $app->send_plain_text ("User-agent: *\x0ADisallow: /\x0A");
    }
  } # /robots.txt

  return $app->throw_error (404);
} # main

sub html ($$$) {
  my ($class, $app, $path) = @_;

  if (@$path == 2 and $path->[1] =~ /\A[A-Za-z0-9-]+\.htt\z/) {
    # /html/{file}.htt
    return $class->temma_html ($app, 'text/plain', $path->[1] . '.tm', {}, '');
  }
  
  return $app->throw_error (404);
} # html

sub dashboard ($$) {
  my ($class, $app) = @_;
  ## Pjax (partition=dashboard)
  # /dashboard
  # /dashboard/...
  # /jump
  return $class->temma_html ($app, 'text/html', 'dashboard.html.tm', {
    app_env => $app->config->{env_name},
    app_rev => $app->rev,
    push_key => $app->config->{push_server_public_key},
  }, $app->rev);
} # dashboard

sub group_pjax ($$) {
  my ($class, $app) = @_;
  return $class->temma_html ($app, 'text/html', 'group.index.html.tm', {
    app_env => $app->config->{env_name},
    formatter_url_prefix => $app->config->{formatter}->{url},
    app_rev => $app->rev,
  }, $app->rev);
} # group_pjax

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

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
<https://www.gnu.org/licenses/>.

=cut
