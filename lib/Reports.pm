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
      user_status => 1, # open
      owner_status => 1, # open
      ref => $ref,
    })->then (sub {
      $ref = $_[0]->{next_ref};
      my $account_ids = [map { $_->{account_id} } values %{$_[0]->{memberships}}];
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
    account_id => Dongry::Type->serialize ('text', $_),
    prev_report_timestamp => 0,
    touch_timestamp => 0+$updated,
    processing => 0,
  } } @$account_ids];

  push @$data, {
    report_type => 0, # group
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

  return $app->db->execute (q{select `account_id`, `processing`,
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
        return $class->get_email_args (
          $app, $report_type, $w->{account_id},
          start_time => $start_time,
          end_time => $end_time,
        )->then (sub {
          my $args = shift;
          return unless defined $args;
          return promised_for {
            my $to_addr = shift;
            return $app->temma_email ($template, $args, undef, undef, $to_addr);
          } $to_addrs;
        })->then (sub { return 1 });
      })->then (sub {
        return unless $_[0];
        return $app->db->update ('account_report_request', {
          prev_report_timestamp => $now,
          processing => 0,
        }, where => {
          account_id => $w->{account_id},
          processing => $now,
          report_type => $w->{report_type},
        });
      });
    } $v;
  });
} # process_report_requests

sub get_email_args ($$$$%) {
  my ($class, $app, $report_type, $account_id, %args) = @_;
  if ($report_type == 1) { # daily report
    return $app->accounts (['group', 'byaccount'], {
      context_key => $app->config->{accounts}->{context} . ':group',
      account_id => $account_id,
      user_status => 1, # open
      owner_status => 1, # open
      limit => 100,
      with_group_data => ['title'],
      with_group_updated => 1,
    })->then (sub {
      my $groups = [sort {
        $a->{group_updated} <=> $b->{group_updated};
      } grep {
        $_->{group_updated} > $args{start_time};
        # $args{end_time}
      } values %{$_[0]->{memberships}}];
      return undef unless @$groups;
      splice @$groups, 10;
      $args{group_memberships} = $groups;
      return promised_for {
        my $gm = shift;
        return $app->db->select ('index', {
          group_id => Dongry::Type->serialize ('text', $gm->{group_id}),
          owner_status => 1, # open
          user_status => 1, # open
          index_type => {-in => [1, 2, 3]}, # blog wiki todo
          updated => {'>', $args{start_time}}, # $args{end_time}
        }, fields => ['index_id', 'title'], order => ['updated', 'asc'], limit => 20)->then (sub {
          $gm->{indexes} = my $indexes = $_[0]->all;
          for (@$indexes) {
            $_->{title} = Dongry::Type->parse ('text', $_->{title});
          }
        });
      } $groups;
    })->then (sub {
      #$groups = [grep { !!@{$_->{indexes}} } @$groups];
      #return undef unless @$groups;
      return \%args;
    });
  } elsif ($report_type == 2) { # call report
    return $app->db->select ('object_call', {
      to_account_id => $account_id,
      read => 0,
      timestamp => {'>', $args{start_time}, '<=', $args{end_time}},
    }, fields => [
      'group_id', 'object_id', 'thread_id',
    ], order => ['timestamp', 'asc'], limit => 30)->then (sub {
      my $calls = $_[0]->all;
      return undef unless @$calls;

      my $by_group = {};
      for (@$calls) {
        push @{$by_group->{$_->{group_id}}->{calls} ||= []}, $_;
      }
      return $app->accounts (['group', 'byaccount'], {
        context_key => $app->config->{accounts}->{context} . ':group',
        account_id => $account_id,
        group_id => [keys %$by_group],
        user_status => 1, # open
        owner_status => 1, # open
        limit => 100,
        with_group_data => ['title'],
      })->then (sub {
        for (values %{$_[0]->{memberships}}) {
          next unless defined $by_group->{$_->{group_id}};
          $by_group->{$_->{group_id}}->{group_title} = $_->{group_data}->{title};
        }

        return promised_for {
          my $group_id = shift;
          my $gc = $by_group->{$group_id};
          return unless defined $gc->{group_title};
          my $oids = {map {
            (
              $_->{object_id} => 1,
              $_->{thread_id} => 1,
            );
          } @{$gc->{calls}}};
          return $app->db->select ('object', {
            group_id => Dongry::Type->serialize ('text', $group_id),
            object_id => {-in => [keys %$oids]},
            user_status => 1, # open
            owner_status => 1, # open
          }, field => ['object_id', 'title'])->then (sub {
            my $to_title = {};
            for (@{$_[0]->all}) {
              $to_title->{$_->{object_id}} = Dongry::Type->parse ('text', $_->{title});
            }
            for (@{$gc->{calls}}) {
              if (length ($to_title->{$_->{object_id}} // '')) {
                $_->{computed_title} = $to_title->{$_->{object_id}};
              } elsif (length ($to_title->{$_->{thread_id}} // '')) {
                $_->{computed_title} = 'Re: '.$to_title->{$_->{thread_id}};
              }
            }
            $gc->{calls} = [grep { defined $_->{computed_title} } @{$gc->{calls}}];
            $gc->{group_id} = $group_id;
            $args{group_calls}->{$group_id} = $gc if @{$gc->{calls}};
          });
        } [keys %$by_group];
      })->then (sub {
        return undef unless keys %{$args{group_calls}};
        $args{group_calls} = [values %{$args{group_calls}}];
        return \%args;
      });
    });
  }
  return Promise->resolve (undef);
} # get_email_args

sub run ($$$) {
  my ($class, $app, $force) = @_;
  return Promise->resolve->then (sub {
    return unless $force or rand > 0.9; # 10%
    return $class->check_groups ($app);
  })->then (sub {
    return unless $force or rand > 0.9; # 10%
    return $class->process_report_requests ($app, 1); # daily report
  })->then (sub {
    return unless $force or rand > 0.6; # 40%
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
