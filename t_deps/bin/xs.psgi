#!/usr/bin/perl
use strict;
use warnings;
use Wanage::HTTP;
use Warabe::App;
use JSON::PS;
use Web::URL::Encoding;

my $Tokens = {};
my $Counts = {};
my $NamedToken = {};
my $Mails = {};

return sub {
  my $http = Wanage::HTTP->new_from_psgi_env (shift);
  my $app = Warabe::App->new_from_http ($http);
  $app->execute_by_promise (sub {
    my $path = $app->http->url->{path};
    if ($path eq '/authorize') {
      my $state = $app->bare_param ('state');
      my $code = rand;
      my $token = rand;
      my $token_name = $app->bare_param ('name') // $app->http->request_cookies->{name};
      #warn "TOKEN name : |$token_name|";
      if (defined $token_name) {
        $NamedToken->{$token_name} //= $token;
        $token = $NamedToken->{$token_name};
      }
      $Tokens->{$code} = $token;
      $app->http->set_response_header ('X-Code', $code);
      $app->http->set_response_header ('X-State', $state);
      my $next_url = $app->text_param ('redirect_uri') // '';
      $next_url .= $next_url =~ /\?/ ? '&' : '?';
      $next_url .= 'state=' . percent_encode_c $state;
      $next_url .= '&code=' . percent_encode_c $code;
      #warn $next_url;
      $app->http->set_response_header ('content-type', 'text/html;charset=utf-8');
      $app->http->send_response_body_as_ref (\sprintf q{<!DOCTYPE HTML><meta http-equiv=refresh content="0;url=%s">}, $next_url);
      return $app->http->close_response_body;
    }
    if ($path eq '/token') {
            my $code = $app->bare_param ('code');
            my $token = delete $Tokens->{$code};
            return $app->send_error (404) unless defined $token;
            my $result = {access_token => $token, token_type => 'bearer'};
            $app->http->set_response_header ('Content-Type', 'application/json');
            $app->http->send_response_body_as_ref (\perl2json_bytes $result);
            return $app->http->close_response_body;
          }
    if ($path eq '/setname') {
      my $name = $app->bare_param ('name');
      #warn "Set cookie |$name|";
      $app->http->set_response_header
          ('set-cookie', 'name=' . $name . '; path=/');
      $app->http->set_response_header ('access-control-allow-origin', '*');
      return $app->send_error (200);
    }

    if ($path eq '/abcde') {
      return $app->send_plain_text (q{abcde});
    }

    if ($path =~ m{^/push/([0-9A-Za-z._-]+)$}) {
      my $key = $1;
      if ($http->request_method eq 'POST') {
        $Counts->{$key}++;
        $http->set_status (200);
        return $http->close_response_body;
      }
      $http->set_status (200);
      $http->send_response_body_as_ref (\perl2json_bytes {
        count => $Counts->{$key} || 0,
      });
      return $http->close_response_body;
    }

    if ($path eq '/news') {
      $http->set_response_header ('access-control-allow-origin', '*');
      return $app->send_plain_text (q{
        <!DOCTYPE HTML>
        <section id=2012-04-02>
          <h1>News 4</h1>
        </section>
        <section id=2012-03-14 data-important>
          <h1>News 3</h1>
        </section>
        <section id=2012-03-12>
          <h1>News 2</h1>
        </section>
        <section id=2012-01-02 data-important>
          <h1>News 1</h1>
        </section>
      });
    }

    if ($path eq '/mailgun/send') {
      my $params = $http->request_body_params;
      push @{$Mails->{$params->{to}->[0]} ||= []}, {
        from => $params->{from}->[0],
        to => $params->{to}->[0],
        message => (scalar $http->request_uploads->{message}->[0]->as_f->slurp),
      };
      
      $http->set_status (200);
      return $http->close_response_body;
    } elsif ($http->url->stringify =~ m{/mailgun/get\?addr=([^&]+)$}) {
      my $addr = percent_decode_c $1;

      $http->set_status (200);
      $http->send_response_body_as_ref (\perl2json_bytes ($Mails->{$addr} || []));
      return $http->close_response_body;
    }
    
    return $app->send_error (404);
  });
};

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
