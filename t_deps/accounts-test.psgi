# -*- perl -*-
use strict;
use warnings;
use Wanage::HTTP;
use Warabe::App;
use JSON::PS;

sub json ($$) {
  my $app = $_[0];
  $app->http->set_response_header ('content-type', 'application/json');
  $app->http->send_response_body_as_ref (\perl2json_bytes $_[1]);
  $app->http->close_response_body;
} # json

sub error ($$) {
  my $app = $_[0];
  $app->http->set_status (400);
  $app->http->set_response_header ('content-type', 'application/json');
  $app->http->send_response_body_as_ref (\perl2json_bytes $_[1]);
  $app->http->close_response_body;
} # error

my $Accounts = {};

return sub {
  my $http = Wanage::HTTP->new_from_psgi_env ($_[0]);
  my $app = Warabe::App->new_from_http ($http);
  return $app->execute_by_promise (sub {
    my $path = $app->http->url->{path};
    if ($path eq '/session') {
      return json $app, {
        sk => rand,
        set_sk => 1,
        sk_expires => time + 3600,
      };
    } elsif ($path eq '/login') {
      return json $app, {
        authorization_url => "https://test1/authorize",
      };
    } elsif ($path eq '/cb') {
      my $code = $app->text_param ('code');
      if (defined $code) {
        return json $app, {};
      } else {
        return error $app, {reason => 'Bad |code|'};
      }
    } elsif ($path eq '/info') {
      my $sk = $app->bare_param ('sk') // '';
      my $data = $Accounts->{$sk};
      if (defined $data) {
        return json $app, $data;
      } else {
        return json $app, {};
      }
    } elsif ($path eq '/create-for-test') {
      my $sk = int rand 100000000000;
      my $data = json_bytes2perl $app->bare_param ('data');
      $data->{account_id} = int rand 100000000000;
      $data->{has_account} = 1;
      $Accounts->{$sk} = $data;
      return json $app, {cookies => {sk => $sk},
                         account_id => $data->{account_id}};
    }
    return $app->send_error (404);
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
