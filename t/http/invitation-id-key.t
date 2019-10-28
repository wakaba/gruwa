use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {}],
    [a3 => account => {terms_version => 1}],
  )->then (sub {
    return $current->create_group (g1 => {owner => 'a1', members => ['a2']});
  })->then (sub {
    return $current->create_group (g2 => {owner => 'a1'});
  })->then (sub {
    return $current->create_invitation (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->are_errors (
      ['GET', ['invitation',
        $current->o ('g1')->{group_id},
        $current->o ('i1')->{invitation_key},
      ''], {}, account => 'a2'],
      [
        {path => ['invitation', '124', 'abc', ''], status => 302,
         response_headers => {location => $current->resolve ("/g/124/my/config?welcome=1")->stringify}},
        {path => ['invitation', '124', $current->o ('i1')->{invitation_key}, ''], status => 302,
         response_headers => {location => $current->resolve ("/g/124/my/config?welcome=1")->stringify}},
        {path => ['invitation', '000'.$current->o ('g1')->{group_id}, $current->o ('i1')->{invitation_key}, ''], status => 404},
        {path => ['invitation', $current->o ('g1')->{group_id}, 'baegeee', ''], status => 302,
         response_headers => {location => $current->resolve ("/g/".$current->o ('g1')->{group_id}."/my/config?welcome=1")->stringify}},
        {path => ['invitation', $current->o ('g2')->{group_id}, $current->o ('i1')->{invitation_key}, ''], status => 302,
         response_headers => {location => $current->resolve ("/g/".$current->o ('g2')->{group_id}."/my/config?welcome=1")->stringify}},
      ],
    );
  })->then (sub {
    return $current->get_html (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => 'a3');
  })->then (sub {
    return $current->get_html (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => 'a2');
  })->then (sub {
    return $current->get_html (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => '');
  })->then (sub {
    return $current->get_html (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => undef);
  })->then (sub {
    return $current->get_json (['members', 'invitations', 'list.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $json = $result->{json};
      is 0+keys %{$json->{invitations}}, 1;
      my $inv2 = $json->{invitations}->{each %{$json->{invitations}}};
      is $inv2->{invitation_key}, $current->o ('i1')->{invitation_key};
      is $inv2->{expires}, $current->o ('i1')->{expires};
      is $inv2->{group_id}, $current->o ('g1')->{group_id};
      is $inv2->{author_account_id}, $current->o ('a1')->{account_id};
      is $inv2->{invitation_data}->{member_type}, 1; # normal
      ok $inv2->{created};
      is $inv2->{target_account_id}, '0';
      is $inv2->{user_account_id}, '0';
      is $inv2->{used_data}, undef;
      is $inv2->{used}, 0;
    } $current->c;
  });
} n => 12, name => 'GET a new invitation';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_account (a2 => {});
  })->then (sub {
    return $current->create_group (g1 => {owner => 'a1', members => []});
  })->then (sub {
    return $current->create_invitation (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_redirect (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => 'a2');
  })->then (sub {
    return $current->get_redirect (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
         $current->resolve ("/g/".$current->o ('g1')->{group_id}."/my/config?welcome=1")->stringify;
    } $current->c;
    return $current->get_redirect (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => '');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
         $current->resolve ("/g/".$current->o ('g1')->{group_id}."/my/config?welcome=1")->stringify;
    } $current->c;
    return $current->get_redirect (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => undef);
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{res}->header ('Location'),
         $current->resolve ("/g/".$current->o ('g1')->{group_id}."/my/config?welcome=1")->stringify;
    } $current->c;
  });
} n => 3, name => 'GET a used invitation';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {
      name => $current->generate_text (a2name => {}),
    }],
    [a3 => account => {terms_version => 1}],
  )->then (sub {
    return $current->create_group (g1 => {owner => 'a1'});
  })->then (sub {
    return $current->create_group (g2 => {owner => 'a1'});
  })->then (sub {
    return $current->create_invitation (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->are_errors (
      ['POST', ['invitation',
        $current->o ('g1')->{group_id},
        $current->o ('i1')->{invitation_key},
      ''], {}, account => 'a2'],
      [
        {path => ['invitation', '124', 'abc', ''], status => 302,
         response_headers => {location => $current->resolve ("/g/124/my/config?welcome=1")->stringify}},
        {path => ['invitation', '124', $current->o ('i1')->{invitation_key}, ''], status => 302,
         response_headers => {location => $current->resolve ("/g/124/my/config?welcome=1")->stringify}},
        {path => ['invitation', '000'.$current->o ('g1')->{group_id}, $current->o ('i1')->{invitation_key}, ''], status => 404},
        {path => ['invitation', $current->o ('g1')->{group_id}, 'baegeee', ''], status => 302,
         response_headers => {location => $current->resolve ("/g/".$current->o ('g1')->{group_id}."/my/config?welcome=1")->stringify}},
        {path => ['invitation', $current->o ('g2')->{group_id}, $current->o ('i1')->{invitation_key}, ''], status => 302,
         response_headers => {location => $current->resolve ("/g/".$current->o ('g2')->{group_id}."/my/config?welcome=1")->stringify}},
        {account => undef, status => 403, name => 'no account'},
        {account => 'a3', status => 403, name => 'bad terms_version'},
        {origin => undef, status => 400},
      ],
    );
  })->then (sub {
    return $current->post_redirect (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{status}, 302;
      is $result->{res}->header ('Location'),
         $current->resolve ("/g/" . $current->o ('g1')->{group_id} . '/my/config?welcome=1')->stringify;
    } $current->c;
    return $current->get_json (['members', 'list.json'], {}, account => 'a2', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $data = $result->{json}->{members}->{$current->o ('a2')->{account_id}};
      is $data->{user_status}, 1; # open
      is $data->{owner_status}, 1; # open
      is $data->{member_type}, 1; # normal
      is $data->{name}, $current->o ('a2name');
    } $current->c;
    return $current->get_json (['members', 'invitations', 'list.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $json = $result->{json};
      is 0+keys %{$json->{invitations}}, 1;
      my $inv2 = $json->{invitations}->{each %{$json->{invitations}}};
      is $inv2->{invitation_key}, $current->o ('i1')->{invitation_key};
      is $inv2->{expires}, $current->o ('i1')->{expires};
      is $inv2->{group_id}, $current->o ('g1')->{group_id};
      is $inv2->{author_account_id}, $current->o ('a1')->{account_id};
      is $inv2->{invitation_data}->{member_type}, 1; # normal
      ok $inv2->{created};
      is $inv2->{target_account_id}, '0';
      is $inv2->{user_account_id}, $current->o ('a2')->{account_id};
      is $inv2->{used_data}->{old_group_membership}, undef;
      is $inv2->{used_data}->{group_id}, $current->o ('g1')->{group_id};
      ok $inv2->{used} > $inv2->{created};
    } $current->c;
  });
} n => 19, name => 'POST a new invitation';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_account (a2 => {});
  })->then (sub {
    return $current->create_account (a3 => {});
  })->then (sub {
    return $current->create_group (g1 => {owner => 'a1'});
  })->then (sub {
    return $current->create_group (g2 => {owner => 'a1'});
  })->then (sub {
    return $current->create_invitation (i1 => {group => 'g1', account => 'a1'});
  })->then (sub {
    return $current->post_redirect (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => 'a2');
  })->then (sub {
    return $current->post_redirect (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{status}, 302, $result;
      is $result->{res}->header ('Location'),
         $current->resolve ("/g/" . $current->o ('g1')->{group_id} . '/my/config?welcome=1')->stringify;
    } $current->c, name => 'Used invitation';
  })->then (sub {
    return $current->get_json (['members', 'list.json'], {}, account => 'a2', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $data = $result->{json}->{members}->{$current->o ('a2')->{account_id}};
      is $data->{user_status}, 1; # open
      is $data->{owner_status}, 1; # open
      is $data->{member_type}, 1; # normal
      is $result->{json}->{members}->{$current->o ('a3')->{account_id}}, undef;
    } $current->c;
    return $current->get_json (['members', 'invitations', 'list.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $json = $result->{json};
      is 0+keys %{$json->{invitations}}, 1;
      my $inv2 = $json->{invitations}->{each %{$json->{invitations}}};
      is $inv2->{invitation_key}, $current->o ('i1')->{invitation_key};
      is $inv2->{expires}, $current->o ('i1')->{expires};
      is $inv2->{group_id}, $current->o ('g1')->{group_id};
      is $inv2->{author_account_id}, $current->o ('a1')->{account_id};
      is $inv2->{invitation_data}->{member_type}, 1; # normal
      ok $inv2->{created};
      is $inv2->{target_account_id}, '0';
      is $inv2->{user_account_id}, $current->o ('a2')->{account_id};
      is $inv2->{used_data}->{old_group_membership}, undef;
      is $inv2->{used_data}->{group_id}, $current->o ('g1')->{group_id};
      ok $inv2->{used} > $inv2->{created};
    } $current->c;
  });
} n => 18, name => 'POST a used invitation';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_account (a2 => {});
  })->then (sub {
    return $current->create_group (g1 => {owner => 'a1'});
  })->then (sub {
    return $current->create_invitation (i1 => {group => 'g1', account => 'a1', member_type => 2}); # owner
  })->then (sub {
    return $current->post_redirect (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{status}, 302;
      is $result->{res}->header ('Location'),
         $current->resolve ("/g/" . $current->o ('g1')->{group_id} . '/my/config?welcome=1')->stringify;
    } $current->c;
    return $current->get_json (['members', 'list.json'], {}, account => 'a2', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $data = $result->{json}->{members}->{$current->o ('a2')->{account_id}};
      is $data->{user_status}, 1; # open
      is $data->{owner_status}, 1; # open
      is $data->{member_type}, 2; # owner
    } $current->c;
    return $current->get_json (['members', 'invitations', 'list.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $json = $result->{json};
      is 0+keys %{$json->{invitations}}, 1;
      my $inv2 = $json->{invitations}->{each %{$json->{invitations}}};
      is $inv2->{invitation_key}, $current->o ('i1')->{invitation_key};
      is $inv2->{expires}, $current->o ('i1')->{expires};
      is $inv2->{group_id}, $current->o ('g1')->{group_id};
      is $inv2->{author_account_id}, $current->o ('a1')->{account_id};
      is $inv2->{invitation_data}->{member_type}, 2; # owner
      ok $inv2->{created};
      is $inv2->{target_account_id}, '0';
      is $inv2->{user_account_id}, $current->o ('a2')->{account_id};
      is $inv2->{used_data}->{old_group_membership}, undef;
      is $inv2->{used_data}->{group_id}, $current->o ('g1')->{group_id};
      ok $inv2->{used} > $inv2->{created};
    } $current->c;
  });
} n => 17, name => 'POST a new invitation as owner';

Test {
  my $current = shift;
  return $current->create (
    [a1 => account => {}],
    [a2 => account => {
      name => $current->generate_text (t1 => {}),
    }],
  )->then (sub {
    return $current->create_group (g1 => {owner => 'a1', members => ['a2']});
  })->then (sub {
    return $current->create_invitation (i1 => {group => 'g1', account => 'a1', member_type => 2}); # owner
  })->then (sub {
    return $current->post_json (['my', 'edit.json'], {
      name => $current->generate_text (t2 => {}),
    }, account => 'a2', group => 'g1');
  })->then (sub {
    return $current->post_redirect (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{status}, 302;
      is $result->{res}->header ('Location'),
         $current->resolve ("/g/" . $current->o ('g1')->{group_id} . '/my/config?welcome=1')->stringify;
    } $current->c;
    return $current->get_json (['members', 'list.json'], {}, account => 'a2', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $data = $result->{json}->{members}->{$current->o ('a2')->{account_id}};
      is $data->{user_status}, 1; # open
      is $data->{owner_status}, 1; # open
      is $data->{member_type}, 2; # owner
      is $data->{name}, $current->o ('t2'), 'not changed';
    } $current->c;
    return $current->get_json (['members', 'invitations', 'list.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $json = $result->{json};
      is 0+keys %{$json->{invitations}}, 1;
      my $inv2 = $json->{invitations}->{each %{$json->{invitations}}};
      is $inv2->{invitation_key}, $current->o ('i1')->{invitation_key};
      is $inv2->{expires}, $current->o ('i1')->{expires};
      is $inv2->{group_id}, $current->o ('g1')->{group_id};
      is $inv2->{author_account_id}, $current->o ('a1')->{account_id};
      is $inv2->{invitation_data}->{member_type}, 2; # owner
      ok $inv2->{created};
      is $inv2->{target_account_id}, '0';
      is $inv2->{user_account_id}, $current->o ('a2')->{account_id};
      is $inv2->{used_data}->{old_group_membership}->{user_status}, 1; # open
      is $inv2->{used_data}->{old_group_membership}->{owner_status}, 1; # open
      is $inv2->{used_data}->{old_group_membership}->{member_type}, 1; # normal
      is $inv2->{used_data}->{group_id}, $current->o ('g1')->{group_id};
      ok $inv2->{used} > $inv2->{created};
    } $current->c;
  });
} n => 20, name => 'POST normal member upgraded to owner';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {owner => 'a1'});
  })->then (sub {
    return $current->create_invitation (i1 => {group => 'g1', account => 'a1', member_type => 2}); # owner
  })->then (sub {
    return $current->post_redirect (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{status}, 302;
      is $result->{res}->header ('Location'),
         $current->resolve ("/g/" . $current->o ('g1')->{group_id} . '/my/config?welcome=1')->stringify;
    } $current->c;
    return $current->get_json (['members', 'list.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $data = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $data->{user_status}, 1; # open
      is $data->{owner_status}, 1; # open
      is $data->{member_type}, 2; # owner
    } $current->c;
    return $current->get_json (['members', 'invitations', 'list.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $json = $result->{json};
      is 0+keys %{$json->{invitations}}, 1;
      my $inv2 = $json->{invitations}->{each %{$json->{invitations}}};
      is $inv2->{invitation_key}, $current->o ('i1')->{invitation_key};
      is $inv2->{expires}, $current->o ('i1')->{expires};
      is $inv2->{group_id}, $current->o ('g1')->{group_id};
      is $inv2->{author_account_id}, $current->o ('a1')->{account_id};
      is $inv2->{invitation_data}->{member_type}, 2; # owner
      ok $inv2->{created};
      is $inv2->{target_account_id}, '0';
      is $inv2->{user_account_id}, $current->o ('a1')->{account_id};
      is $inv2->{used_data}->{old_group_membership}->{user_status}, 1; # open
      is $inv2->{used_data}->{old_group_membership}->{owner_status}, 1; # open
      is $inv2->{used_data}->{old_group_membership}->{member_type}, 2; # owner
      is $inv2->{used_data}->{group_id}, $current->o ('g1')->{group_id};
      ok $inv2->{used} > $inv2->{created};
    } $current->c;
  });
} n => 19, name => 'POST owner using owner invitation';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_group (g1 => {owner => 'a1'});
  })->then (sub {
    return $current->create_invitation (i1 => {group => 'g1', account => 'a1', member_type => 1}); # normal
  })->then (sub {
    return $current->post_redirect (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => 'a1');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{status}, 302;
      is $result->{res}->header ('Location'),
         $current->resolve ("/g/" . $current->o ('g1')->{group_id} . '/my/config?welcome=1')->stringify;
    } $current->c;
    return $current->get_json (['members', 'list.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $data = $result->{json}->{members}->{$current->o ('a1')->{account_id}};
      is $data->{user_status}, 1; # open
      is $data->{owner_status}, 1; # open
      is $data->{member_type}, 2; # owner
    } $current->c;
    return $current->get_json (['members', 'invitations', 'list.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $json = $result->{json};
      is 0+keys %{$json->{invitations}}, 1;
      my $inv2 = $json->{invitations}->{each %{$json->{invitations}}};
      is $inv2->{invitation_key}, $current->o ('i1')->{invitation_key};
      is $inv2->{expires}, $current->o ('i1')->{expires};
      is $inv2->{group_id}, $current->o ('g1')->{group_id};
      is $inv2->{author_account_id}, $current->o ('a1')->{account_id};
      is $inv2->{invitation_data}->{member_type}, 1; # normal
      ok $inv2->{created};
      is $inv2->{target_account_id}, '0';
      is $inv2->{user_account_id}, $current->o ('a1')->{account_id};
      is $inv2->{used_data}->{old_group_membership}->{user_status}, 1; # open
      is $inv2->{used_data}->{old_group_membership}->{owner_status}, 1; # open
      is $inv2->{used_data}->{old_group_membership}->{member_type}, 2; # owner
      is $inv2->{used_data}->{group_id}, $current->o ('g1')->{group_id};
      ok $inv2->{used} > $inv2->{created};
    } $current->c;
  });
} n => 19, name => 'POST owner using normal member invitation';

Test {
  my $current = shift;
  return $current->create_account (a1 => {})->then (sub {
    return $current->create_account (a2 => {});
  })->then (sub {
    return $current->create_group (g1 => {owner => 'a1', members => ['a2']});
  })->then (sub {
    return $current->create_invitation (i1 => {group => 'g1', account => 'a1', member_type => 1}); # normal
  })->then (sub {
    return $current->post_redirect (['invitation',
      $current->o ('g1')->{group_id},
      $current->o ('i1')->{invitation_key},
    ''], {}, account => 'a2');
  })->then (sub {
    my $result = $_[0];
    test {
      is $result->{status}, 302;
      is $result->{res}->header ('Location'),
         $current->resolve ("/g/" . $current->o ('g1')->{group_id} . '/my/config?welcome=1')->stringify;
    } $current->c;
    return $current->get_json (['members', 'list.json'], {}, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $data = $result->{json}->{members}->{$current->o ('a2')->{account_id}};
      is $data->{user_status}, 1; # open
      is $data->{owner_status}, 1; # open
      is $data->{member_type}, 1; # normal
    } $current->c;
    return $current->get_json (['members', 'invitations', 'list.json'], {
    }, account => 'a1', group => 'g1');
  })->then (sub {
    my $result = $_[0];
    test {
      my $json = $result->{json};
      is 0+keys %{$json->{invitations}}, 1;
      my $inv2 = $json->{invitations}->{each %{$json->{invitations}}};
      is $inv2->{invitation_key}, $current->o ('i1')->{invitation_key};
      is $inv2->{expires}, $current->o ('i1')->{expires};
      is $inv2->{group_id}, $current->o ('g1')->{group_id};
      is $inv2->{author_account_id}, $current->o ('a1')->{account_id};
      is $inv2->{invitation_data}->{member_type}, 1; # normal
      ok $inv2->{created};
      is $inv2->{target_account_id}, '0';
      is $inv2->{user_account_id}, $current->o ('a2')->{account_id};
      is $inv2->{used_data}->{old_group_membership}->{user_status}, 1; # open
      is $inv2->{used_data}->{old_group_membership}->{owner_status}, 1; # open
      is $inv2->{used_data}->{old_group_membership}->{member_type}, 1; # normal
      is $inv2->{used_data}->{group_id}, $current->o ('g1')->{group_id};
      ok $inv2->{used} > $inv2->{created};
    } $current->c;
  });
} n => 19, name => 'POST normal member using normal member invitation';

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

You does not have received a copy of the GNU Affero General Public
License along with this program, see <https://www.gnu.org/licenses/>.

=cut
