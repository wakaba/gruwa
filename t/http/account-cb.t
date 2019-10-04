use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [ax1 => account => {xs => 1}],
  )->then (sub {
    return $current->client->request (path => ['account', 'login'], headers => {
      origin => $current->client->origin->to_ascii,
    }, method => 'POST', params => {
      server => 'test1',
    });
  })->then (sub {
    my $res = $_[0];
    $res->header ('Set-Cookie') =~ /sk=([^;]+)/;
    my $sk = $1;
    my $url = Web::URL->parse_string ($res->header ('Location'));
    my $client = $current->client_for ($url);
    return $client->request (url => $url, params => {
      name => $current->o ('ax1')->{xs_name},
    })->then (sub {
      my $res = $_[0];
      die $res unless $res->status == 200;
      my $code = $res->header ('X-Code');
      my $state = $res->header ('X-State');
      return $current->are_errors (
        ['GET', ['account', 'cb'], {
          code => $code,
          state => $state,
        }],
        [
          {params => {state => $state}, status => 400,
           response_headers => {location => undef, 'set-cookie' => undef},
           name => 'no |code|'},
        ],
        [
          {params => {code => $code}, status => 400,
           response_headers => {location => undef, 'set-cookie' => undef},
           name => 'no |state|'},
        ],
        [
          {account => undef, status => 400,
           response_headers => {location => undef, 'set-cookie' => undef},
           name => 'no |sk|'},
        ],
      )->then (sub {
        return $current->client->request (path => ['account', 'cb'], params => {
          code => $code,
          state => $state,
        }, cookies => {sk => $sk});
      });
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 302;
      is $res->header ('Set-Cookie'), undef;
      is $res->header ('Location'), $current->resolve ("/dashboard")->stringify;
    } $current->c;
  });
} n => 4, name => '/account/cb';

Test {
  my $current = shift;
  return $current->client->request (path => ['account', 'login'], headers => {
    origin => $current->client->origin->to_ascii,
  }, method => 'POST', params => {
    server => 'test1',
    next => $current->resolve ('/hoge/fuga?abc')->stringify,
  })->then (sub {
    my $res = $_[0];
    $res->header ('Set-Cookie') =~ /sk=([^;]+)/;
    my $sk = $1;
    my $url = Web::URL->parse_string ($res->header ('Location'));
    my $client = $current->client_for ($url);
    return $client->request (url => $url)->then (sub {
      my $res = $_[0];
      die $res unless $res->status == 200;
      my $code = $res->header ('X-Code');
      my $state = $res->header ('X-State');
      return $current->client->request (path => ['account', 'cb'], params => {
        code => $code,
        state => $state,
      }, cookies => {sk => $sk});
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 302;
      is $res->header ('Set-Cookie'), undef;
      is $res->header ('Location'), 'http://app.server.test/account/agree?next=http%3A%2F%2Fapp.server.test%2Fhoge%2Ffuga%3Fabc';
    } $current->c;
  });
} n => 3, name => '/account/cb with next (new account)';

Test {
  my $current = shift;
  return $current->create (
    [ax1 => account => {xs => 1}],
  )->then (sub {
    return $current->client->request (path => ['account', 'login'], headers => {
      origin => $current->client->origin->to_ascii,
    }, method => 'POST', params => {
      server => 'test1',
      next => $current->resolve ('/hoge/fuga?abc')->stringify,
    });
  })->then (sub {
    my $res = $_[0];
    $res->header ('Set-Cookie') =~ /sk=([^;]+)/;
    my $sk = $1;
    my $url = Web::URL->parse_string ($res->header ('Location'));
    my $client = $current->client_for ($url);
    return $client->request (url => $url, params => {
      name => $current->o ('ax1')->{xs_name},
    })->then (sub {
      my $res = $_[0];
      die $res unless $res->status == 200;
      my $code = $res->header ('X-Code');
      my $state = $res->header ('X-State');
      return $current->client->request (path => ['account', 'cb'], params => {
        code => $code,
        state => $state,
      }, cookies => {sk => $sk});
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 302;
      is $res->header ('Set-Cookie'), undef;
      is $res->header ('Location'), $current->resolve ("/hoge/fuga?abc")->stringify;
    } $current->c;
  });
} n => 3, name => '/account/cb with next (not new account)';

Test {
  my $current = shift;
  return $current->create (
    [ax1 => account => {xs => 1}],
  )->then (sub {
    return $current->client->request (path => ['account', 'login'], headers => {
      origin => $current->client->origin->to_ascii,
    }, method => 'POST', params => {
      server => 'test1',
      next => 'https://hoge.test/foo',
    });
  })->then (sub {
    my $res = $_[0];
    $res->header ('Set-Cookie') =~ /sk=([^;]+)/;
    my $sk = $1;
    my $url = Web::URL->parse_string ($res->header ('Location'));
    my $client = $current->client_for ($url);
    return $client->request (url => $url, params => {
      name => $current->o ('ax1')->{xs_name},
    })->then (sub {
      my $res = $_[0];
      die $res unless $res->status == 200;
      my $code = $res->header ('X-Code');
      my $state = $res->header ('X-State');
      return $current->client->request (path => ['account', 'cb'], params => {
        code => $code,
        state => $state,
      }, cookies => {sk => $sk});
    });
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 302;
      is $res->header ('Set-Cookie'), undef;
      is $res->header ('Location'), $current->resolve ("/dashboard")->stringify;
    } $current->c;
  });
} n => 3, name => '/account/cb with bad next';

RUN;

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
