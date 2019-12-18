use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  my $body = "\xFE\x00\x01\x81" . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
      is_file => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok $result->{json}->{upload_token};
    } $current->c;
    $current->set_o (o1 => $result->{json});
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'upload.json'], {
      token => $current->o ('o1')->{upload_token},
    }, account => 'a1', group => 'g1', headers => {
      'content-type' => 'application/octet-stream',
    }, body => $body);
  })->then (sub {
    return $current->get_redirect (['o', $current->o ('o1')->{object_id}, 'file'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      like $result->{res}->header ('location'), qr{^http://storage.server.test/.+\?.+$};
      is $result->{res}->header ('cache-control'), 'private,max-age=600';
    } $current->c;
    my $url = Web::URL->parse_string ($result->{res}->header ('location'));
    return $current->client_for ($url)->request (
      url => $url,
    );
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 200;
      is $res->header ('content-type'), 'application/octet-stream';
      is $res->header ('content-disposition'), 'attachment; filename=""';
      is $res->body_bytes, $body;
    } $current->c;
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $obj = $_[0];
    test {
      is $obj->{data}->{upload_token}, $current->o ('o1')->{upload_token};
      is $obj->{data}->{title}, undef;
      is $obj->{data}->{mime_type}, undef;
      is $obj->{data}->{file_size}, undef;
      is $obj->{data}->{file_name}, undef;
      is $obj->{data}->{file_closed}, undef;
    } $current->c;
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      title => "aaae\x{5233}",
      mime_type => "text/plain; hoge=fuga",
      file_size => 52523,
      file_name => "ho\x{2244}ge.png",
      file_closed => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->object ($current->o ('o1'), account => 'a1');
  })->then (sub {
    my $obj = $_[0];
    test {
      is $obj->{data}->{upload_token}, undef;
      is $obj->{data}->{title}, "aaae\x{5233}";
      is $obj->{data}->{mime_type}, "text/plain;hoge=fuga";
      is $obj->{data}->{file_size}, 52523;
      is $obj->{data}->{file_name}, "ho\x{2244}ge.png";
      is $obj->{data}->{file_closed}, 1;
    } $current->c;
    return $current->get_file (['o', $current->o ('o1')->{object_id}, 'file'], {}, account => 'a1', group => 'g1', redirected => 1);
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('content-type'), 'text/plain;hoge=fuga';
      is $result->{res}->header ('content-disposition'),
          q{attachment; filename=ho%E2%89%84ge.png; filename*=utf-8''ho%E2%89%84ge.png};
      #is $result->{res}->header ('Content-Security-Policy'), 'sandbox';
      is $result->{res}->body_bytes, $body;
    } $current->c;
    return $current->are_errors (
      ['POST', ['o', $current->o ('o1')->{object_id}, 'upload.json'], {
        token => $current->o ('o1')->{upload_token},
      }, account => 'a1', group => 'g1', headers => {
        'content-type' => 'application/octet-stream',
      }, body => rand],
      [
        {status => 403, name => 'File closed'},
      ],
    );
  })->then (sub {
    return $current->get_file (['o', $current->o ('o1')->{object_id}, 'file'], {}, account => 'a1', group => 'g1', redirected => 1);
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('content-type'), 'text/plain;hoge=fuga';
      is $result->{res}->header ('content-disposition'),
          q{attachment; filename=ho%E2%89%84ge.png; filename*=utf-8''ho%E2%89%84ge.png};
      #is $result->{res}->header ('Content-Security-Policy'), 'sandbox';
      is $result->{res}->body_bytes, $body;
    } $current->c, name => 'unchanged';
    return $current->are_errors (
      ['GET', ['o', $current->o ('o1')->{object_id}, 'image'], {}, account => 'a1', group => 'g1'],
      [
        {status => 404, name => 'Not an image'},
      ],
    );
  });
} n => 27, name => 'file upload';

Test {
  my $current = shift;
  my $body1 = "\xFE\x00\x01\x81" . rand;
  my $body2 = "\xFE\x00\x01\x81" . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_group (g2 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->create_object (o2 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
      is_file => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    $current->set_o (o1 => $result->{json});
  })->then (sub {
    return $current->get_redirect (['o', $current->o ('o1')->{object_id}, 'file'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    my $url = Web::URL->parse_string ($result->{res}->header ('location'));
    return $current->client_for ($url)->request (
      url => $url,
    );
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 404;
    } $current->c;
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'upload.json'], {
      token => $current->o ('o1')->{upload_token},
    }, account => 'a1', group => 'g1', headers => {
      'content-type' => 'application/octet-stream',
    }, body => $body1);
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'upload.json'], {
      token => $current->o ('o1')->{upload_token},
    }, account => 'a1', group => 'g1', headers => {
      'content-type' => 'application/octet-stream',
    }, body => $body2);
  })->then (sub {
    return $current->are_errors (
      ['POST', ['o', $current->o ('o1')->{object_id}, 'upload.json'], {
        token => $current->o ('o1')->{upload_token},
      }, account => 'a1', group => 'g1', headers => {
        'content-type' => 'application/octet-stream',
      }, body => $body1],
      [
        {method => 'GET', status => 405},
        {origin => 'null', status => 400, name => 'null origin'},
        {group => 'g2', status => 404},
        {path => ['o', '524444343', 'upload.json'], status => 404},
        {account => '', status => 403},
        {account => undef, status => 403},
        {params => {}, status => 403},
        {params => {token => rand}, status => 403},
      ],
    );
  })->then (sub {
    return $current->get_file (['o', $current->o ('o1')->{object_id}, 'file'], {}, account => 'a1', group => 'g1', redirected => 1);
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->body_bytes, $body2;
    } $current->c;
    return $current->are_errors (
      ['GET', ['o', $current->o ('o1')->{object_id}, 'file'], {
      }, account => 'a1', group => 'g1'],
      [
        {group => 'g2', status => 404},
        {path => ['o', '524444343', 'file'], status => 404},
        {path => ['o', $current->o ('o2')->{object_id}, 'file'], status => 404, name => 'not a file'},
        {account => '', status => 403},
        {account => undef, status => 302},
      ],
    );
  });
} n => 4, name => 'file content can be altered until the file is closed';

Test {
  my $current = shift;
  my $body = "\xFE\x00\x01\x81" . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
      is_file => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok $result->{json}->{upload_token};
    } $current->c;
    $current->set_o (o1 => $result->{json});
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'upload.json'], {
      token => $current->o ('o1')->{upload_token},
    }, account => 'a1', group => 'g1', headers => {
      'content-type' => 'application/octet-stream',
    }, body => $body);
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      title => "aaae\x{5233}",
      mime_type => "text/plain",
      file_size => 52523,
      file_name => "ho\x{2244}ge.png",
      file_closed => 1,
      timestamp => 5253111442,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_file (['o', $current->o ('o1')->{object_id}, 'file'], {}, account => 'a1', group => 'g1', redirected => 1);
  })->then (sub {
    my $result = $_[0];
    test {
      #is $result->{res}->header ('last-modified'),
      #    'Mon, 18 Jun 2136 21:37:22 GMT';
      is $result->{res}->header ('content-type'), 'text/plain';
    } $current->c;
  });
} n => 2, name => 'file last modified timestamp';

Test {
  my $current = shift;
  my $body = "\xFE\x00\x01\x81" . rand;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {members => ['a1']});
  })->then (sub {
    return $current->create_index (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_json (['o', 'create.json'], {
      is_file => 1,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      ok $result->{json}->{upload_token};
    } $current->c;
    $current->set_o (o1 => $result->{json});
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'upload.json'], {
      token => $current->o ('o1')->{upload_token},
    }, account => 'a1', group => 'g1', headers => {
      'content-type' => 'application/octet-stream',
    }, body => $body);
  })->then (sub {
    return $current->post_json (['o', $current->o ('o1')->{object_id}, 'edit.json'], {
      title => "aaae\x{5233}",
      mime_type => "Image/PnG",
      file_size => 52523,
      file_name => "ho\x{2244}ge.pngx",
      file_closed => 1,
      timestamp => 25253151333,
    }, account => 'a1', group => 'g1');
  })->then (sub {
    return $current->get_redirect (['o', $current->o ('o1')->{object_id}, 'image'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      like $result->{res}->header ('location'), qr{^http://storage.server.test/.+\?.+$};
      is $result->{res}->header ('cache-control'), 'private,max-age=600';
    } $current->c;
    my $url = Web::URL->parse_string ($result->{res}->header ('location'));
    return $current->client_for ($url)->request (
      url => $url,
    );
  })->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 200;
      is $res->header ('content-type'), 'image/png';
      is $res->header ('content-disposition'), undef;
      #is $res->header ('Content-Security-Policy'), 'sandbox';
      #is $res->header ('last-modified'), 'Sun, 29 Mar 2770 20:15:33 GMT';
      is $res->body_bytes, $body;
    } $current->c;
  });
} n => 7, name => 'image file upload';

RUN;

=head1 LICENSE

Copyright 2017-2019 Wakaba <wakaba@suikawiki.org>.

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
