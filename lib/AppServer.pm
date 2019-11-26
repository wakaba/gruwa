package AppServer;
use strict;
use warnings;
use Warabe::App;
push our @ISA, qw(Warabe::App);
use Path::Tiny;
use Promise;
use Promised::File;
use Web::Encoding;
use Web::DOM::Document;
use Temma::Parser;
use Temma::Processor;
use Web::URL;
use Web::Transport::BasicClient;
use JSON::PS;
use Dongry::Database;

sub new_from_http_and_config ($$$) {
  my $self = $_[0]->new_from_http ($_[1]);
  $self->{app_config} = $_[2];
  return $self;
} # new_from_http_and_config

sub config ($) {
  return $_[0]->{app_config};
} # config

sub db ($) {
  return $_[0]->http->server_state->data->{dbs}->{main} ||= Dongry::Database->new (%{$_[0]->config->{_db_sources}});
} # db

sub rev ($) {
  return $_[0]->{app_config}->{git_sha};
} # rev

sub accounts ($$$) {
  my ($app, $path, $params) = @_;
  my $accounts = $app->http->server_state->data->{clients}->{accounts} ||= Web::Transport::BasicClient->new_from_url
      (Web::URL->parse_string ($app->config->{accounts}->{url}), {
        #debug => 2,
      });
  return $accounts->request (
    method => 'POST',
    path => $path,
    bearer => $app->config->{accounts}->{key},
    params => $params,
  )->then (sub {
    my $res = $_[0];
    if ($res->status == 200) {
      return json_bytes2perl $res->body_bytes;
    } elsif (not $res->is_network_error and
             ($res->header ('Content-Type') // '') =~ m{^application/json}) {
      my $json = json_bytes2perl $res->body_bytes;
      if (defined $json and ref $json eq 'HASH' and defined $json->{reason}) {
        die $json;
      }
    }
    die $res;
  });
} # accounts

sub apploach ($$$) {
  my ($self, $path, $params) = @_;
  my $config = $self->config;
  my $client = $self->http->server_state->data->{clients}->{apploach} ||= do {
    my $url = Web::URL->parse_string ($config->{apploach}->{url});
    Web::Transport::BasicClient->new_from_url ($url);
  };
  for (keys %$params) {
    if (ref $params->{$_} eq 'HASH') {
      $params->{$_} = perl2json_chars $params->{$_};
    }
  }
  return $client->request (
    method => 'POST',
    bearer => $config->{apploach}->{key},
    path => [$config->{apploach}->{app_id}, @$path],
    params => $params,
  )->then (sub {
    my $res = $_[0];
    if ($res->status == 200) {
      return json_bytes2perl $res->body_bytes;
    } elsif ($res->status == 400 and
             $res->header ('content-type') =~ m{^application/json}) {
      my $json = json_bytes2perl $res->body_bytes;
      if (ref $json eq 'HASH' and defined $json->{reason}) {
        return $self->throw_error (400, reason_phrase => $json->{reason});
      }
    }
    die $res;
  });
} # apploach

my $TemplatePath = path (__FILE__)->parent->parent->child ('templates');

sub temma_email ($$$$$$) {
  my ($app, $template_path, $args, $from_name, $to_name, $to_addr) = @_;
  my $path = $TemplatePath->child ('emails', $template_path);
  return Promised::File->new_from_path ($path)->read_char_string->then (sub {
    my $doc = new Web::DOM::Document;
    my $parser = Temma::Parser->new;
    $parser->parse_char_string ($_[0] => $doc);
    my $processor = Temma::Processor->new;
    $processor->oninclude (sub {
      my $x = $_[0];
      my $path = path ($x->{path})->absolute ($TemplatePath->child ('emails'));
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
    my $result = '';
    open my $fh, '>', \$result;
    binmode $fh, ':utf8';
    
    return Promise->new (sub {
      my $ok = $_[0];
      $processor->process_document ($doc => $fh, ondone => sub {
        $ok->();
      }, args => {%$args, app => $app});
    })->then (sub {
      my $doc = new Web::DOM::Document;
      $doc->manakai_is_html (1);
      $result = decode_web_utf8 $result;
      $doc->inner_html ($result);
      return $app->_send_to_addr (
        from_display_name => (defined $from_name ? "Gruwa ($from_name)" : 'Gruwa'),
        to_addr => $to_addr,
        to_display_name => $to_name,
        subject => $doc->title,
        html => $result,
      );
    });
  });
} # temma_email

sub _send_to_addr ($$%) {
  my ($app, %args) = @_;
  my $to_addr = $args{to_addr} // '';
  die "Bad |to_addr| ($to_addr)"
      unless $to_addr =~ /\A[\x21-\x3B\x3D\x3E-\x7E]+\z/;

  my $display_to_addr = $args{display_to_addr} // $to_addr;
  die "Bad |display_to_addr| ($display_to_addr)"
      unless $display_to_addr =~ /\A[\x21-\x3B\x3D\x3E-\x7E]+\z/;

  my $display_cc_addrs = $args{display_cc_addrs} || [];
  for (@$display_cc_addrs) {
    die "Bad |display_cc_addrs| ($_)"
        unless $_ =~ /\A[\x21-\x3B\x3D\x3E-\x7E]+\z/;
  }

  my $reply_to_addr = $args{reply_to_addr} // '';
  if (length $reply_to_addr) {
    die "Bad |reply_to_addr| ($reply_to_addr)"
        unless $reply_to_addr =~ /\A[\x21-\x3B\x3D\x3E-\x7E]+\z/;
  }

  my $subject = $args{subject} // '';
  if ($subject =~ /[^\x20-\x7E]/ or $subject =~ /=\?/) {
    $subject = encode_web_utf8 $subject;
    $subject =~ s/([^0-9A-Za-z-])/sprintf '=%02X', ord $1/ge;
    $subject = "=?utf-8?q?$subject?=";
  }

  my $from_name = 'Gruwa';
  if (defined $args{from_display_name}) {
    $from_name = encode_web_utf8 $args{from_display_name};
    $from_name =~ s/([^0-9A-Za-z-])/sprintf '=%02X', ord $1/ge;
    $from_name = "=?utf-8?q?$from_name?=";
  }

  my $to_name = '';
  if (defined $args{to_display_name}) {
    $to_name = encode_web_utf8 $args{to_display_name};
    $to_name =~ s/([^0-9A-Za-z-])/sprintf '=%02X', ord $1/ge;
    $to_name = "=?utf-8?q?$to_name?=";
  }

  my $body = encode_web_utf8 $args{html};
  $body =~ s/([=\x80-\xFF])/sprintf '=%02X', ord $1/ge;

  my $email = encode_web_utf8 join "\x0D\x0A",
      'From: '.$from_name.' <'.$app->config->{emails}->{from_addr}.'>',
      'To: '.$to_name.' <'.$display_to_addr.'>',
      (map { 'Cc: <' . $_ . '>' } @$display_cc_addrs),
      'Subject: ' . $subject,
      (length $reply_to_addr ? "Reply-To: <$reply_to_addr>" : ()),
      'MIME-Version: 1.0',
      'Content-Type: text/html; charset=utf-8',
      'Content-Transfer-Encoding: quoted-printable',
      '',
      $body,
      ;

  my $url = Web::URL->parse_string ($app->config->{emails}->{mailgun_url});
  unless (defined $url) { # dev
    warn "==========\n";
    warn $email . "\n";
    warn "==========\n";
    return Promise->resolve;
  }

  ## <https://documentation.mailgun.com/api-sending.html#sending>
  my $client = Web::Transport::BasicClient->new_from_url ($url);
  return $client->request (
    url => $url,
    method => 'POST',
    basic_auth => ['api', $app->config->{emails}->{mailgun_key}],
    params => {
      from => $app->config->{emails}->{from_addr},
      to => $to_addr,
    },
    files => {
      message => {body_ref => \$email},
    },
  )->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 200;
  })->finally (sub {
    return $client->close;
  });
} # _send_to_addr

sub close ($) {
  return Promise->resolve;
} # close

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
