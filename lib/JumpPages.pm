package JumpPages;
use strict;
use warnings;
use Digest::SHA qw(sha1_hex);
use Web::URL;
use Dongry::Type;
use Time::HiRes qw(time);

use Results;

sub main ($$$$) {
  my ($class, $app, $path, $db, $account_data) = @_;

  if (@$path == 2 and $path->[1] eq 'list.json') {
    # /jump/list.json
    return $db->execute ('select `url`, `label`, `score` / greatest(unix_timestamp(now()) - `timestamp`, 1) as `s`, `score` from `jump` where `account_id` = :account_id order by `s` desc, `url` asc limit 100', {
      account_id => Dongry::Type->serialize ('text', $account_data->{account_id}),
    })->then (sub {
      my $jumps = $_[0]->all->to_a;
      for (@$jumps) {
        $_->{url} = Dongry::Type->parse ('text', $_->{url});
        $_->{label} = Dongry::Type->parse ('text', $_->{label});
      }
      return json $app, {items => $jumps};
    });
  }

  if (@$path == 2 and $path->[1] eq 'ping.json') {
    # /jump/ping.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;
    my $url = Web::URL->parse_string ($app->text_param ('url') // '');
    return json $app, {}
        unless defined $url and $url->is_http_s;
    my $v = $url->path;
    $v .= '#' . $url->fragment if defined $url->fragment;
    my $key = sha1_hex (Dongry::Type->serialize ('text', $account_data->{account_id} . '-' . $v));
    return $db->update ('jump', {
      score => $db->bare_sql_fragment ('`score` + 1'),
    }, where => {
      key => $key,
    })->then (sub {
      return json $app, {};
    });
  }

  if (@$path == 2 and $path->[1] eq 'delete.json') {
    # /jump/delete.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;
    my $url = Web::URL->parse_string ($app->text_param ('url') // '');
    return json $app, {}
        unless defined $url and $url->is_http_s;
    my $v = $url->path;
    $v .= '#' . $url->fragment if defined $url->fragment;
    my $key = sha1_hex (Dongry::Type->serialize ('text', $account_data->{account_id} . '-' . $v));
    return $db->delete ('jump', {
      key => $key,
    })->then (sub {
      return json $app, {};
    });
  }

  if (@$path == 2 and $path->[1] eq 'add.json') {
    # /jump/add.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;
    my $url = Web::URL->parse_string ($app->text_param ('url') // '');
    return $app->throw_error (400, reason_phrase => 'Bad |url|')
        unless defined $url and $url->is_http_s;
    my $v = $url->path;
    $v .= '#' . $url->fragment if defined $url->fragment;
    my $label = $app->text_param ('label') // $v;
    my $key = sha1_hex (Dongry::Type->serialize ('text', $account_data->{account_id} . '-' . $v));
    return $db->insert ('jump', [{
      key => $key,
      account_id => Dongry::Type->serialize ('text', $account_data->{account_id}),
      url => Dongry::Type->serialize ('text', $v),
      label => Dongry::Type->serialize ('text', $label),
      score => 0,
      timestamp => time,
    }], duplicate => {
      label => $db->bare_sql_fragment ('values(`label`)'),
    })->then (sub {
      return json $app, {};
    });
  }

  return $app->throw_error (404);
} # main

1;

=head1 LICENSE

Copyright 2017 Wakaba <wakaba@suikawiki.org>.

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
