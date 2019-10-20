package Reports;
use strict;
use warnings;
use Time::HiRes qw(time);
use Promise;
use Promised::Flow;
use Dongry::Type;

use Results;

sub check_groups ($$) {
  my ($class, $app) = @_;
  return $app->db->select ('account_report_request', {
    group_id => 0,
    account_id => 0,
    ## reusing this table with different semantics, for convenience
  }, fields => ['touch_timestamp'])->then (sub {
    my $from_time = ($_[0]->first || {touch_timestamp => time-24*60*60})->{touch_timestamp};
    return $app->accounts (['group', 'list'], {
      context_key => $app->config->{accounts}->{context} . ':group',
      owner_status => 1, # open
      admin_status => 1, # open
      ref => '+' . $from_time . ',0',
      limit => 30,
    })->then (sub {
      my $json = $_[0];
      return promised_for {
        return $class->touch_group_members ($app, $_[0]->{group_id}, $_[0]->{updated});
      } [sort {
        $a->{updated} <=> $b->{updated}
      } values %{$json->{groups}}];
    });
  });
} # check_groups

sub touch_group_members ($$$$) {
  my ($class, $app, $group_id, $group_updated) = @_;
  my $ref;
  return promised_until {
    return $app->accounts (['group', 'members'], {
      context_key => $app->config->{accounts}->{context} . ':group',
      group_id => $group_id,
      ref => $ref,
    })->then (sub {
      $ref = $_[0]->{next_ref};
      my $account_ids = [map { $_->{account_id} } grep {
        $_->{user_status} == 1 and # open
        $_->{owner_status} == 1; # open
      } values %{$_[0]->{memberships}}];
      return $class->touch_group_accounts ($app, $group_id, $account_ids, $group_updated, with_group_touch => 1)->then (sub {
        return ! $_[0]->{has_next};
      });
    });
  };
} # touch_group_members

sub touch_group_accounts ($$$$$;%) {
  my ($class, $app, $group_id, $account_ids, $updated, %args) = @_;
  return Promise->resolve unless @$account_ids;

  my $now = time;
  my $report_after = $updated;
  if ($args{is_call}) {
    $report_after += 5*60;
  } else {
    $report_after += 24*60*60;
  }

  my $data = [map { +{
    group_id => Dongry::Type->serialize ('text', $group_id),
    account_id => Dongry::Type->serialize ('text', $_),
    prev_report_timestamp => 0,
    next_report_after => 0+$report_after,
    touch_timestamp => 0+$updated,
    processing => 0,
  } } @$account_ids];

  push @$data, {
    group_id => 0,
    account_id => 0,
    prev_report_timestamp => 0,
    next_report_after => 0+$updated,
    touch_timestamp => 0+$updated,
    processing => 0,
  } if $args{with_group_touch};
  
  return $app->db->insert ('account_report_request', $data, duplicate => {
    touch_timestamp => $app->db->bare_sql_fragment ('greatest(`touch_timestamp`,values(`touch_timestamp`))'),
    ## $report_after, basically.
    ## current `prev_report_timestamp` + 24h, if less.
    ## current `next_report_after`, if > `prev_` and less.
    ## $now + 1min, if greater.
    next_report_after => $app->db->bare_sql_fragment (qq{
      greatest(
        least(values(`next_report_after`), `prev_report_timestamp`+24*60*60, if(`next_report_after`>`prev_report_timestamp`, `next_report_after`, values(`next_report_after`))),
        $now+60
      )
    }),
  });
} # touch_group_accounts

## For debugging
sub get_report_requests ($$$) {
  my ($class, $app, $group_ids) = @_;
  return Promise->resolve ([]) unless @$group_ids;
  return $app->db->select ('account_report_request', {
    group_id => {-in => $group_ids},
  })->then (sub {
    my $v = $_[0]->all;
    return [map {
      $_->{group_id} .= '';
      $_->{account_id} .= '';
      $_;
    } @$v];
  });
} # get_report_requests

sub process_report_requests ($$) {
  my ($class, $app) = @_;
  my $now = time - 60;
  return $app->db->execute (q{select `group_id`, `account_id`, `processing`
    from `account_report_request` where
    `group_id` != 0 and `account_id` != 0 and
    `next_report_after` <= :now and
    `prev_report_timestamp` < `touch_timestamp` and
    `processing` < :timeouted
    limit 10
  }, {
    now => $now,
    timeouted => $now - 10*60,
  })->then (sub {
    my $v = $_[0]->all;
    return promised_for {
      my $w = $_[0];
      return $app->db->update ('account_report_request', {
        processing => $now,
      }, where => {
        group_id => $w->{group_id},
        account_id => $w->{account_id},
        processing => $w->{processing},
      })->then (sub {
        return unless $_[0]->row_count == 1;

        # XXX
        
        return $app->db->update ('account_report_request', {
          prev_report_timestamp => $now,
        }, where => {
          group_id => $w->{group_id},
          account_id => $w->{account_id},
          processing => $now,
        });
      });
    } $v;
  });
} # process_report_requests

sub main ($$$) {
  my ($class, $app, $path) = @_;
  # /reports/...
  
  if (@$path == 2 and $path->[1] eq 'heartbeat') {
    # /reports/heartbeat
    $app->requires_request_method ({POST => 1});
    return $class->check_groups ($app)->then (sub {
      return json $app, {};
    });
  }

  if ($app->config->{is_test_script}) {
    if (@$path == 2 and $path->[1] eq 'requests.json') {
      # /reports/requests.json
      return $class->get_report_requests ($app, $app->bare_param_list ('group_id')->to_a)->then (sub {
        my $items = $_[0];
        return json $app, {items => $items};
      });
    }
  }

  return $app->throw_error (404);
} # main

1;
