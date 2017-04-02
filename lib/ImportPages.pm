package ImportPages;
use strict;
use warnings;
use Web::Host;
use Web::URL;
use Web::Transport::ConnectionClient;
use Web::DOM::Document;
use Web::XML::Parser;
use Web::Feed::Parser;

use Results;

sub main ($$$) {
  my ($class, $app, $path) = @_;

  if (@$path == 3 and $path->[1] eq 'hatenagroup' and
      ($path->[2] eq 'bare' or $path->[2] eq 'feed')) {
    # /hatenagroup/bare
    # /hatenagroup/feed
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;

    my $group_name = $app->text_param ('group_name') // '';
    my $host = Web::Host->parse_string ("$group_name.g.hatena.ne.jp");
    return $app->throw_error (400, reason_phrase => 'Bad |group_name|')
        unless defined $host;
    my $pathq = $app->text_param ('path') // ''; # pathquery
    my $url = Web::URL->parse_string ('https://' . $host->to_ascii . $pathq);
    return $app->throw_error (400, reason_phrase => 'Bad |path|')
        unless defined $url;

    my $client = Web::Transport::ConnectionClient->new_from_url ($url);
    return $client->request (
      url => $url,
    )->then (sub {
      my $res = $_[0];
      if ($res->is_network_error) {
        warn $res;
        $app->http->set_status (400, 'Remote server connection error');
        return json $app, {status => 0};
      } elsif ($res->status == 200) {
        if ($path->[2] eq 'feed') {
          my $doc = new Web::DOM::Document;
          my $parser = Web::XML::Parser->new;
          $parser->parse_byte_string ('utf-8', $res->body_bytes, $doc);
          my $fparser = Web::Feed::Parser->new;
          my $parsed = $fparser->parse_document ($doc);
          for (@{$parsed->{entries}}) {
            $_->{updated} = $_->{updated}->to_unix_number;
            if (defined $_->{content}) {
              if ($_->{content}->owner_document->manakai_is_html) {
                $_->{content_html} = $_->{content}->inner_html;
              } else {
                $_->{content_xml} = $_->{content}->inner_html;
              }
              delete $_->{content};
            }
          }
          return json $app, $parsed;
        } else {
          $app->http->set_response_header
              ('content-type', $res->header ('content-type'));
          $app->http->set_response_header
              ('content-disposition', 'attachment');
          $app->http->set_response_header
              ('content-security-policy', 'sandbox');
          $app->http->send_response_body_as_ref (\($res->body_bytes));
          return $app->http->close_response_body;
        }
      } else {
        $app->http->set_status (400, 'Remote server error');
        return json $app, {status => $res->status,
                           location => $res->header ('location')};
      }
    });
  }

  if (@$path == 2 and $path->[1] eq 'embedded') {
    # /import/embedded
    return temma $app, 'import.embedded.html.tm', {};
  }

  return $app->throw_error (404);
} # main

1;
