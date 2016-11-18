# -*- Perl -*-
use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Wanage::HTTP;
use Warabe::App;

my $config_path = path ($ENV{CONFIG_FILE} // die "No |CONFIG_FILE|");
my $Config = json_bytes2perl $config_path->slurp;

return sub {
  my $http = Wanage::HTTP->new_from_psgi_env ($_[0]);
  my $app = Warabe::App->new_from_http ($http);
  $app->execute_by_promise (sub {
    warn sprintf "ACCESS: [%s] %s %s FROM %s %s\n",
        scalar gmtime,
        $app->http->request_method, $app->http->url->stringify,
        $app->http->client_ip_addr->as_text,
        $app->http->get_request_header ('User-Agent') // '';

    if ($Config->{origin} eq $app->http->url->ascii_origin) {
      $app->http->set_response_header
          ('Strict-Transport-Security',
           'max-age=10886400; includeSubDomains; preload');

      
      return $app->send_error (404, reason_phrase => 'Page not found');
    } else {
      return $app->send_redirect ($Config->{origin});
    }
  });
};

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
