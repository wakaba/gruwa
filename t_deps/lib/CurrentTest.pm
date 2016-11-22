package CurrentTest;
use strict;
use warnings;
use Promise;
use JSON::PS;
use Web::URL;
use Web::Transport::ConnectionClient;
use Test::More;
use Test::X1;

sub new ($$) {
  return bless $_[1], $_[0];
} # new

sub c ($) {
  return $_[0]->{c};
} # c

sub client ($) {
  my $self = $_[0];
  return $self->{client}
      ||= Web::Transport::ConnectionClient->new_from_url ($self->{url});
} # client

sub get_html ($$;$%) {
  my ($self, $path, $params, %args) = @_;
  my $cookies = {%{$args{cookies} or {}}};
  return $self->_account ($args{account})->then (sub {
    $cookies->{sk} = $_[0]->{cookies}->{sk}; # or undef
    return $self->client->request (
      path => $path,
      params => $params,
      cookies => $cookies,
    );
  })->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 200;
    my $mime = $res->header ('Content-Type') // '';
    die "Bad MIME type |$mime|"
        unless $mime eq 'text/html; charset=utf-8';
    return {status => $res->status,
            res => $res};
  });
} # get_html

sub get_json ($$;$%) {
  my ($self, $path, $params, %args) = @_;
  my $cookies = {%{$args{cookies} or {}}};
  return $self->_account ($args{account})->then (sub {
    $cookies->{sk} = $_[0]->{cookies}->{sk}; # or undef
    return $self->client->request (
      path => $path,
      params => $params,
      cookies => $cookies,
    );
  })->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 200;
    my $mime = $res->header ('Content-Type') // '';
    die "Bad MIME type |$mime|"
        unless $mime eq 'application/json; charset=utf-8';
    return {status => $res->status,
            json => (json_bytes2perl $res->body_bytes),
            res => $res};
  });
} # get_json

sub post_json ($$$;%) {
  my ($self, $path, $params, %args) = @_;
  my $cookies = {%{$args{cookies} or {}}};
  return $self->_account ($args{account})->then (sub {
    $cookies->{sk} = $_[0]->{cookies}->{sk}; # or undef
    return $self->client->request (
      path => $path,
      method => 'POST',
      params => $params,
      headers => {
        origin => $self->client->origin->to_ascii,
      },
      cookies => $cookies,
    );
  })->then (sub {
    my $res = $_[0];
    die $res unless $res->status == 200;
    my $mime = $res->header ('Content-Type') // '';
    die "Bad MIME type |$mime|"
        unless $mime eq 'application/json; charset=utf-8';
    return {status => $res->status,
            json => (json_bytes2perl $res->body_bytes),
            res => $res};
  });
} # post_json

sub create_group ($$$) {
  my ($self, $name, $opts) = @_;
  return $self->post_json (['g', 'create.json'], {
    title => $opts->{title} // rand,
  }, account => $opts->{owner} // '')->then (sub {
    $self->{objects}->{$name // 'X'} = $_[0]->{json};
  });
} # create_group

sub group ($$;%) {
  my ($self, $group, %args) = @_;
  return $self->get_json (['g', $group->{group_id}, 'info.json'], {}, account => $args{account})->then (sub {
    return $_[0]->{json};
  });
} # group

sub accounts_client ($) {
  my $self = $_[0];
  return $self->{accounts_client}
      ||= Web::Transport::ConnectionClient->new_from_url ($self->{accounts_url});
} # accounts_client

sub create_account ($$$) {
  my ($self, $name => $account) = @_;
  $account->{name} //= rand;
  return $self->accounts_client->request (
    method => 'POST',
    path => ['create-for-test'],
    params => {
      data => perl2json_chars $account,
    },
  )->then (sub {
    die $_[0] unless $_[0]->status == 200;
    $self->{objects}->{$name // 'X'} = json_bytes2perl $_[0]->body_bytes;
  });
} # create_account

## account => undef - no account
## account => ''    - new account
## account => $hash - account object
## account => $name - account object by name
sub _account ($$) {
  my ($self, $account) = @_;
  if (defined $account) {
    if (ref $account) {
      return Promise->resolve ($account);
    } elsif ($account eq '') {
      return $self->create_account (undef, {});
    } else {
      return Promise->resolve ($self->o ($account));
    }
  } else {
    return Promise->resolve (undef);
  }
} # _account

sub resolve ($$) {
  my $self = shift;
  return Web::URL->parse_string (shift, $self->{url});
} # resolve

sub o ($$) {
  return $_[0]->{objects}->{$_[1]} // die "No object |$_[1]|";
} # o

sub are_errors ($$$) {
  my ($self, $base, $tests) = @_;
  my ($base_method, $base_path, $base_params, %base_args) = @$base;

  my $has_error = 0;
  my @p;
  
  for my $test (@$tests) {
    my %opt = (
      method => $base_method,
      path => $base_path,
      params => $base_params,
      basic_auth => [key => 'test'],
      %base_args,
      %$test,
      headers => {Origin => $self->client->origin->to_ascii},
    );
    $opt{cookies} = {%{$opt{cookies} or {}}};
    $opt{headers}->{Origin} = $opt{origin} if exists $opt{origin};
    push @p, $self->_account ($opt{account})->then (sub {
      $opt{cookies}->{sk} = $_[0]->{cookies}->{sk}; # or undef
    })->then (sub {
      return $self->client->request (
        method => $opt{method}, path => $opt{path}, params => $opt{params},
        basic_auth => $opt{basic_auth},
        headers => $opt{headers}, cookies => $opt{cookies},
      );
    })->then (sub {
      my $res = $_[0];
      unless ($opt{status} == $res->status) {
        test {
          is $res->status, $opt{status}, $res;
        } $self->c, name => $opt{name};
        $has_error = 1;
      }
      for my $name (keys %{$opt{response_headers} or {}}) {
        my $expected_value = $opt{response_headers}->{$name};
        my $actual_value = $res->header ($name);
        if (defined $actual_value and defined $expected_value and
            $actual_value eq $expected_value) {
          #
        } elsif (not defined $actual_value and not defined $expected_value) {
          #
        } else {
          test {
            is $expected_value, $actual_value, "Response header $name:";
          } $self->c;
          $has_error = 1;
        }
      }
    });
  }

  return Promise->all (\@p)->then (sub {
    unless ($has_error) {
      test {
        ok 1, 'no error';
      } $self->c;
    }
  });
} # are_errors

sub close ($) {
  my $self = shift;
  return Promise->all ([
    defined $self->{client} ? $self->{client}->close : undef,
    defined $self->{accounts_client} ? $self->{accounts_client}->close : undef,
  ]);
} # close

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
