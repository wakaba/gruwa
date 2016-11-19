package Results;
use strict;
use warnings;
use Promise;
use Path::Tiny;
use JSON::PS;
use Exporter::Lite;
use Web::DOM::Document;
use Temma::Parser;
use Temma::Processor;

our @EXPORT;

push @EXPORT, qw(json);
sub json ($$) {
  my ($app) = @_;
  $app->http->set_response_header
      ('Content-Type' => 'application/json; charset=utf-8');
  $app->http->send_response_body_as_ref (\perl2json_bytes $_[1]);
  $app->http->close_response_body;
} # json

my $RootPath = path (__FILE__)->parent->parent;
my $TemplatePath = $RootPath->child ('templates');

push @EXPORT, qw(temma);
sub temma ($$$) {
  my ($app, $template_path, $args) = @_;
  my $http = $app->http;
  my $path = $TemplatePath->child ($template_path);
  return Promised::File->new_from_path ($path)->read_char_string->then (sub {
    my $fh = Results::Temma::Printer->new_from_http ($http);
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
    $http->set_response_header ('Content-Type' => 'text/html; charset=utf-8');
    return Promise->new (sub {
      my $ok = $_[0];
      $processor->process_document ($doc => $fh, ondone => sub {
        undef $fh;
        $http->close_response_body;
        $ok->();
      }, args => {%$args, app => $app});
    });
  });
} # temma

package Results::Temma::Printer;

sub new_from_http ($$) {
  return bless {http => $_[1], value => ''}, $_[0];
} # new_from_http

sub print ($$) {
  $_[0]->{value} .= $_[1];
  if (length $_[0]->{value} > 1024*10 or length $_[1] == 0) {
    $_[0]->{http}->send_response_body_as_text ($_[0]->{value});
    $_[0]->{value} = '';
  }
} # print

sub DESTROY {
  $_[0]->{http}->send_response_body_as_text ($_[0]->{value})
      if length $_[0]->{value};
} # DESTROY

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
