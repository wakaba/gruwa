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
    report_type => 0, # group
    group_id => 0,
    account_id => 0,
  }, fields => ['touch_timestamp'])->then (sub {
    my $now = time;
    my $from_time = ($_[0]->first || {touch_timestamp => $now-24*60*60})->{touch_timestamp} + 0.001;
    return $app->accounts (['group', 'list'], {
      context_key => $app->config->{accounts}->{context} . ':group',
      owner_status => 1, # open
      admin_status => 1, # open
      ref => '+' . $from_time . ',0',
      limit => 30,
    })->then (sub {
      my $json = $_[0];
      return promised_for {
        my $u = $_[0]->{updated};
        $u = $now-10 if $u > $now-10;
        return $class->touch_group_members ($app, $_[0]->{group_id}, $u);
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
      return $class->touch_group_accounts ($app, $group_id, $account_ids, $group_updated, 1)->then (sub { # daily report
        return ! $_[0]->{has_next};
      });
    });
  };
} # touch_group_members

sub touch_group_accounts ($$$$$$) {
  my ($class, $app, $group_id, $account_ids, $updated, $report_type) = @_;
  return Promise->resolve unless @$account_ids;

  my $data = [map { +{
    report_type => $report_type,
    group_id => Dongry::Type->serialize ('text', $group_id),
    account_id => Dongry::Type->serialize ('text', $_),
    prev_report_timestamp => 0,
    touch_timestamp => 0+$updated,
    processing => 0,
  } } @$account_ids];

  push @$data, {
    report_type => 0, # group
    group_id => 0,
    account_id => 0,
    prev_report_timestamp => 0,
    touch_timestamp => 0+$updated,
    processing => 0,
  } if $report_type == 1; # daily report

  return $app->db->insert ('account_report_request', $data, duplicate => {
    touch_timestamp => $app->db->bare_sql_fragment ('greatest(`touch_timestamp`,values(`touch_timestamp`))'),
  });
} # touch_group_accounts

sub process_report_requests ($$$) {
  my ($class, $app, $report_type) = @_;
  my $now = time - 5;
  my $interval;
  my $template;
  if ($report_type == 1) { # daily report
    $interval = $app->config->{emails}->{daily_report_interval};
    $template = 'daily-report.html.tm';
  } elsif ($report_type == 2) { # object calls
    $interval = $app->config->{emails}->{call_report_interval};
    $template = 'call-report.html.tm';
  } else {
    die "Bad report type |$report_type|";
  }
  die "Bad interval for report type |$report_type|: |$interval|"
      unless $interval > 5;

  return $app->db->execute (q{select `group_id`, `account_id`, `processing`,
    `report_type`, `prev_report_timestamp`
    from `account_report_request` where
    `report_type` = :report_type and
    `prev_report_timestamp` < :ready_to_send and
    `prev_report_timestamp` < `touch_timestamp` and
    `processing` < :timeouted
    limit 10
  }, {
    report_type => $report_type,
    ready_to_send => $now - $interval,
    timeouted => $now - 3*60,
  })->then (sub {
    my $v = $_[0]->all;

    return promised_for {
      my $w = $_[0];
      return Promise->all ([
        $app->db->update ('account_report_request', {
          processing => $now,
        }, where => {
          group_id => $w->{group_id},
          account_id => $w->{account_id},
          processing => $w->{processing},
          report_type => $w->{report_type},
        }),
        $app->accounts (['profiles'], {
          account_id => $w->{account_id},
          user_status => 1, # open
          admin_status => 1, # open
          with_linked => 'email',
          # XXX user configuration
        })->then (sub {
          my $account = $_[0]->{accounts}->{$w->{account_id}} || {};
          my $email_addrs = [];
          for (values %{$account->{links} or {}}) {
            next unless $_->{service_name} eq 'email';
            push @$email_addrs, $_->{email};
          }
          return $email_addrs;
        }),
      ])->then (sub {
        return 0 unless $_[0]->[0]->row_count == 1; # failed to lock
        my $to_addrs = $_[0]->[1];
        return 1 unless @$to_addrs;

        my $start_time = $w->{prev_report_timestamp}; # <
        my $end_time = $now; # <=

        return ((promised_for {
          my $to_addr = shift;
          return $app->temma_email ($template, {
            start_time => $start_time,
            end_time => $end_time,
            #debug => 1,
          }, undef, undef, $to_addr);
        } $to_addrs)->then (sub { return 1 }));
      })->then (sub {
        return unless $_[0];
        return $app->db->update ('account_report_request', {
          prev_report_timestamp => $now,
          processing => 0,
        }, where => {
          group_id => $w->{group_id},
          account_id => $w->{account_id},
          processing => $now,
          report_type => $w->{report_type},
        });
      });
    } $v;
  });
} # process_report_requests

sub run ($$$) {
  my ($class, $app, $force) = @_;
  return Promise->resolve->then (sub {
    return unless $force or rand > 0.7;
    return $class->check_groups ($app);
  })->then (sub {
    return unless $force or rand > 0.7;
    return $class->process_report_requests ($app, 1); # daily report
  })->then (sub {
    return unless $force or rand > 0.1;
    return $class->process_report_requests ($app, 2); # call report
  });
} # run

sub main ($$$) {
  my ($class, $app, $path) = @_;
  # /reports/...
  
  if (@$path == 2 and $path->[1] eq 'heartbeat') {
    # /reports/heartbeat
    $app->requires_request_method ({POST => 1});
    return $class->run ($app, 'force')->then (sub {
      return json $app, {};
    });
  }

  return $app->throw_error (404);
} # main

1;
