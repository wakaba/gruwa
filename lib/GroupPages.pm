package GroupPages;
use strict;
use warnings;
use Time::HiRes qw(time);
use Promise;
use Promised::Flow;
use JSON::PS;
use Dongry::SQL qw(like);
use Dongry::Type;
use Dongry::Type::JSONPS;
use Dongry::SQL qw(where like);
use Digest::SHA qw(sha1_hex);
use Web::DateTime::Parser;
use Web::MIME::Type;
use Web::URL;
use Web::URL::Encoding;
use Web::DOM::Document;

use Pager;
use Results;

sub get_index ($$$) {
  my $db = shift;
  return Promise->resolve (undef) unless defined $_[1];
  return $db->select ('index', {
    group_id => Dongry::Type->serialize ('text', $_[0]),
    index_id => Dongry::Type->serialize ('text', $_[1]),

    # XXX
    owner_status => 1,
    user_status => 1,
  }, fields => ['index_id', 'index_type', 'title', 'created', 'updated', 'options'])->then (sub {
    my $index = $_[0]->first;
    return undef unless defined $index;
    $index->{title} = Dongry::Type->parse ('text', $index->{title});
    $index->{options} = Dongry::Type->parse ('json', $index->{options});
    return $index;
  });
} # get_index

## body_type
##   1 html
##   2 plain text
##   3 data
##   4 file

my @TokenAlpha = ('0'..'9','A'..'Z','a'..'z');

sub create_object ($%) {
  my ($db, %args) = @_;
  my $time = $args{now} || time;
  my $obj = {};
  return $db->execute ('select uuid_short() as uuid1,
                               uuid_short() as uuid2')->then (sub {
    my $ids = $_[0]->first;
    my $object_id = ''.$ids->{uuid1};
    my $data = {timestamp => $args{timestamp} || $time,
                object_revision_id => ''.$ids->{uuid2},
                user_status => 1, # open
                owner_status => 1}; # open
    $data->{author_account_id} = ''.$args{author_account_id}
        unless $args{import};
    $obj->{object_id} = $object_id;
    $obj->{data} = $data;
    my $rev_data = {changes => {action => 'new'}};
    ## This does not touch `group`.

    if (defined $args{body_type}) {
      $data->{body_type} = $args{body_type};
      $data->{body_data} = $args{body_data} if defined $args{body_data};
      if ($data->{body_type} == 4) { # file
        my $token = '';
        $token .= $TokenAlpha[rand @TokenAlpha] for 1..10;
        $data->{upload_token} = $token;
      }
    } else {
      $data->{body_type} = 2; # plain text
      $data->{body} = '';
    }

    if (defined $args{parent_object_id}) {
      $data->{parent_object_id} = ''.$args{parent_object_id};
      $data->{thread_id} = ''.$args{thread_id};
    } else {
      $data->{thread_id} = $object_id;
    }

    my $sdata = Dongry::Type->serialize ('json', $data);
    return $db->insert ('object', [{
      group_id => Dongry::Type->serialize ('text', $args{group_id}),
      object_id => $object_id,
      title => '',
      data => $sdata,
      search_data => '',
      created => $time,
      updated => $time,
      timestamp => 0+($data->{timestamp}),
      owner_status => $data->{owner_status},
      user_status => $data->{user_status},
      thread_id => 0+$data->{thread_id},
      parent_object_id => 0+($data->{parent_object_id} || 0),
    }])->then (sub {
      return $db->insert ('object_revision', [{
        group_id => Dongry::Type->serialize ('text', $args{group_id}),
        object_id => $object_id,
        data => $sdata,

        object_revision_id => $data->{object_revision_id},
        revision_data => Dongry::Type->serialize ('json', $rev_data),
        author_account_id => Dongry::Type->serialize ('text', $args{author_account_id}),
        created => $time,

        owner_status => $data->{owner_status},
        user_status => $data->{user_status},
      }]);
    })->then (sub {
      return {object_id => $object_id,
              object_revision_id => $data->{object_revision_id},
              upload_token => $data->{upload_token},
              object => $obj};
    });
  });
} # create_object

sub _write_object_trackbacks ($$$$$$$) {
  my ($db, $group_id, $parent_object_ids,
      $author_account_id, $object_id, $ts, $now) = @_;
  return unless @$parent_object_ids;
  ## If there is no trackbacked object, no trackback object is created
  ## for it.
  return $db->select ('object', {
    group_id => Dongry::Type->serialize ('text', $group_id),
    object_id => {-in => [map {
      Dongry::Type->serialize ('text', $_);
    } @$parent_object_ids]},
  }, fields => ['object_id', 'thread_id'])->then (sub {
    my $parents = $_[0]->all->to_a;
    return promised_map {
      return create_object ($db,
        group_id => $group_id,
        author_account_id => $author_account_id,
        body_type => 3, # data
        body_data => {
          trackback => {
            object_id => ''.$object_id,
          },
        },
        parent_object_id => $_[0]->{object_id},
        thread_id => $_[0]->{thread_id},
        timestamp => $ts,
        now => $now,
      );
    } $parents;
  });
} # _write_object_trackbacks

sub get_import_source ($) {
  my $page = shift;

  my $url = $page->stringify_without_fragment;
  my $suffix = $page->fragment;
  $suffix = defined $suffix ? '#' . $suffix : '';

  my $urls = [];
  if ($page->host->to_ascii =~ /\.g\.hatena\.ne\.jp$/) {
    $url =~ s/^http:/https:/;

    if ($url =~ m{^(https://[^/]+/files/[^/]+/[^/]+)\.([A-Za-z0-9_-]+)$}) {
      $url = $1;
      my $is_image = {
        png => 1, gif => 1, jpg => 1, # jpeg jpe
        bmp => 1, ico => 1, cur => 1,
      }->{lc $2};
      $suffix = $is_image ? 'image' : 'file';
    } elsif ($url =~ m{^https://[^/]+/files/[^/]+/[^/]+$}) {
      $suffix = 'file';
    } elsif ($url =~ m{^(https://[^/]+/[^/]+/[0-9]+)/([^/]+)$}) {
      $url = $1;
      $suffix = '#' . $2;
    }
    push @$urls, $url;
    my $url2 = $url;
    $url2 =~ s{^(https://[^/]+/)hatena-ex-}{$1};
    my $url3 = $url2;
    $url3 =~ s{^(https://[^/]+/)}{$1hatena-ex-};
    push @$urls, $url2 if $url ne $url2;
    push @$urls, $url3 if $url ne $url3;
  } else {
    push @$urls, $url;
  }

  return ($urls, $suffix);
} # get_import_source

sub source_urls ($) {
  my $app = $_[0];

  my $source_url = $app->text_param ('source_page');
  if (defined $source_url) {
    $source_url = Web::URL->parse_string ($source_url);
    return $app->throw_error (400, reason_phrase => 'Bad |source_page|')
        if not defined $source_url or
           not $source_url->is_http_s;
  }

  my $source_site_url = $app->text_param ('source_site');
  if (defined $source_site_url) {
    $source_site_url = Web::URL->parse_string ($source_site_url);
    return $app->throw_error (400, reason_phrase => 'Bad |source_site|')
        if not defined $source_site_url or
           not $source_site_url->is_http_s;
  }
  return $app->throw_error (400, reason_phrase => 'Bad |source_site|')
      if (defined $source_url and not defined $source_site_url) or
         (not defined $source_url and defined $source_site_url) or
         (defined $source_url and defined $source_site_url and
          not $source_url->get_origin->same_origin_as ($source_site_url->get_origin));

  return ($source_site_url, $source_url);
} # source_urls

sub edit_object ($$$$$) {
  my ($opts, $db, $object, $edits, $app) = @_;
  my $group_id = Dongry::Type->serialize ('text', $opts->{group}->{group_id});

  my $changes = {};
  my $reactions = {};
  my $trackbacks = {};
  my $trackback_count = 0;

  if (defined $edits->{user_status}) {
    if ($edits->{user_status} == 2) { # deleted
      $object->{data} = {
        user_status => $edits->{user_status},
        owner_status => $object->{data}->{owner_status},
        title => ''.$object->{object_id},
        timestamp => $object->{data}->{timestamp},
      };
      $changes->{action} = 'delete';
    }
    $object->{data}->{user_status} = $edits->{user_status};
    $changes->{fields}->{user_status} = 1;
  }
  for my $key (qw(
    title body body_source file_name author_name author_hatena_id
    author_bb_username assignee_bb_username todo_bb_priority
    todo_bb_kind todo_bb_state parent_section_id
    timestamp body_type body_source_type
    todo_state file_size file_closed
    mime_type
    body_data
  )) {
    if (defined $edits->{$key}) {
      if ($key eq 'todo_state') {
        $reactions->{old}->{$key} = $object->{data}->{$key} || 0;
        $reactions->{new}->{$key} = $edits->{$key};
      }
      $object->{data}->{$key} = $edits->{$key};
      $changes->{fields}->{$key} = 1;
    }
  }
  if ($object->{data}->{file_closed}) {
    delete $object->{data}->{upload_token};
  }
  if (defined $edits->{body_data_delta}) {
    for my $key (keys %{$edits->{body_data_delta}}) {
      my $value = $edits->{body_data_delta}->{$key};
      if (defined $value) {
        if (not defined $object->{data}->{body_data}->{$key} or
            not $object->{data}->{body_data}->{$key} eq $value) {
          $object->{data}->{body_data}->{$key} = $value;
          $changes->{fields}->{body_data} = 1;
        }
      } else { # no new value
        if (defined $object->{data}->{body_data}->{$key}) {
          delete $object->{data}->{body_data}->{$key};
          $changes->{fields}->{body_data} = 1;
        }
      }
    }
  }

        my $search_data;
        if ($changes->{fields}->{title} or
            $changes->{fields}->{body} or
            $changes->{fields}->{body_type}) {
          my $body = '';
          my @keyword;
          my @url;
          if ($object->{data}->{body_type} == 1) { # html
            my $doc = new Web::DOM::Document;
            $doc->manakai_is_html (1);
            $doc->manakai_set_url ($app->http->url->stringify);
            $doc->inner_html ($object->{data}->{body});
            $body = $doc->document_element->text_content;
            for ($doc->links->to_list) {
              my $name = $_->get_attribute ('data-wiki-name');
              if (defined $name) { # keyword link
                $body .= "\n" . $name;
                push @keyword, $name;
              } else {
                my $url = Web::URL->parse_string ($_->href);
                push @url, $url if defined $url;
              }
            }
            for ($doc->query_selector_all ('img[src], iframe[src]')->to_list) {
              my $url = Web::URL->parse_string ($_->src);
              push @url, $url if defined $url;
            }
            for ($doc->query_selector_all ('hatena-asin[asin]')->to_list) {
              my $url = Web::URL->parse_string ('asin:' . $_->get_attribute ('asin'));
              push @url, $url;
            }
            my $x = 0;
            my $y = 0;
            for ($doc->query_selector_all ('input[type=checkbox /* XXX i */]:not([hidden])')->to_list) {
              $x++;
              $y++ if $_->has_attribute ('checked');
            }
            $object->{data}->{all_checkbox_count} = $x;
            $object->{data}->{checked_checkbox_count} = $y;
          } elsif ($object->{data}->{body_type} == 2) { # plain text
            $body = $object->{data}->{body};
          }
          $search_data = join "\n",
              $body,
              $object->{data}->{title};

          ## Keyword link trackbacks
          {
            my $index_id = $opts->{group}->{data}->{default_wiki_index_id};
            if (defined $index_id) {
              for (@keyword) {
                unless ($object->{data}->{trackbacked}->{wiki_names}->{$index_id}->{$_}) {
                  $trackbacks->{wiki_names}->{$index_id}->{$_} = 1;
                  $object->{data}->{trackbacked}->{wiki_names}->{$index_id}->{$_} = 1;
                  last if 50 < $trackback_count++;
                }
              }
            }
          }

          ## URL link trackbacks
          my $self_url = Web::URL->parse_string ($app->http->url->stringify);
          while (@url) {
            my $url = shift @url;
            if ($url->get_origin->same_origin_as ($self_url->get_origin)) {
              my $path = [map { percent_decode_c $_ } split m{/}, $url->path, -1];
              if (@$path >= 5) {
                if ($path->[1] eq 'g' and
                    $path->[2] eq $opts->{group}->{group_id}) {
                  if ($path->[3] eq 'o' and
                      $path->[4] =~ /\A[0-9]+\z/ and
                      not $path->[4] eq $object->{object_id}) {
                    unless ($object->{data}->{trackbacked}->{objects}->{$path->[4]}) {
                      $trackbacks->{objects}->{$path->[4]} = 1;
                      $object->{data}->{trackbacked}->{objects}->{$path->[4]} = 1;
                      last if 50 < $trackback_count++;
                    }
                  } elsif ($path->[3] eq 'wiki' and
                           length $path->[4]) {
                    my $index_id = $opts->{group}->{data}->{default_wiki_index_id};
                    if (defined $index_id and
                        not $object->{data}->{trackbacked}->{wiki_names}->{$index_id}->{$path->[4]}) {
                      $trackbacks->{wiki_names}->{$index_id}->{$path->[4]} = 1;
                      $object->{data}->{trackbacked}->{wiki_names}->{$index_id}->{$path->[4]} = 1;
                      last if 50 < $trackback_count++;
                    }
                  } elsif (@$path >= 7 and
                           $path->[3] eq 'i' and
                           $path->[4] =~ /\A[0-9]+\z/ and
                           $path->[5] eq 'wiki' and
                           length $path->[6]) {
                    my $index_id = $path->[4];
                    unless ($object->{data}->{trackbacked}->{wiki_names}->{$index_id}->{$path->[6]}) {
                      $trackbacks->{wiki_names}->{$index_id}->{$path->[6]} = 1;
                      $object->{data}->{trackbacked}->{wiki_names}->{$index_id}->{$path->[6]} = 1;
                      last if 50 < $trackback_count++;
                    }
                  } elsif (@$path == 6 and
                           $path->[3] eq 'imported' and
                           $path->[5] eq 'go') {
                    # /g/{group_id}/imported/{url}/go
                    $url = Web::URL->parse_string ($path->[4]);
                    unshift @url, $url;
                  }
                }
              }
            } else { # not same origin
              my $urls = $url->stringify; # with fragment
              unless ($object->{data}->{trackbacked}->{urls}->{$urls}) {
                $trackbacks->{urls}->{$urls} = 1;
                $object->{data}->{trackbacked}->{urls}->{$urls} = 1;
                last if 50 < $trackback_count++;
              }
            }
          } # $url
        } # title/body modified

  if (defined $edits->{assigned_account_ids}) {
    my $new = $edits->{assigned_account_ids};
    my $old = {%{$object->{data}->{assigned_account_ids} || {}}};
    my $changed;
    for (keys %$new) {
      unless (delete $old->{$_}) {
        $reactions->{new}->{assigned_account_ids}->{$_} = 1;
        $changed = 1;
      }
    }
    for (keys %$old) {
      $reactions->{old}->{assigned_account_ids}->{$_} = 1;
      $changed = 1;
    }
    if ($changed) {
      $object->{data}->{assigned_account_ids} = $new;
      $changes->{fields}->{assigned_account_ids} = 1;
    }
  } # assigned_account_ids

  my $time = time;
  my $called_account_ids = {};
  return Promise->all ([
    Promise->resolve->then (sub {
      my $ids = $app->bare_param_list ('called_account_id');
      return unless @$ids;

      return $opts->{acall}->(['group', 'members'], {
        context_key => $app->config->{accounts}->{context} . ':group',
        group_id => $group_id,
        account_id => $ids->to_a,
      })->(sub {
        my $list = $_[0]->{memberships};
        for (@$ids) {
          return $app->throw_error (400, reason_phrase => "Bad account ID |$_|")
              unless $list->{$_};
          ## Don't have to check *_status and member_type.
          $called_account_ids->{$_} |= 0b10; # explicit
        }
      });
    }),
  ])->then (sub {
    my $value = $edits->{parent_object_id};
    return unless defined $value;
    my $old = $object->{data}->{parent_object_id} || 0;
    return if $old == $value;
    if ($value) {
      return $db->select ('object', {
        group_id => $group_id,
        object_id => $value,
      }, fields => ['thread_id'])->then (sub {
        my $v = $_[0]->first;
        die [404, 'Bad |parent_object_id|'] unless defined $v;
        $object->{data}->{parent_object_id} = ''.$value;
        $changes->{fields}->{parent_object_id} = 1;
        if ($v->{thread_id} != $object->{data}->{thread_id}) {
          $object->{data}->{thread_id} = ''.$v->{thread_id};
          $changes->{fields}->{thread_id} = 1;
        }
        die [409, 'Bad |parent_object_id|']
            if (my $x = $object->{data}->{thread_id}) == $object->{object_id} ||
               (my $y = $object->{data}->{parent_object_id}) == $object->{object_id};
      });
    } else {
      delete $object->{data}->{parent_object_id};
      $changes->{fields}->{parent_object_id} = 1;
      $changes->{fields}->{thread_id} = 1;
      $object->{data}->{thread_id} = ''.$object->{object_id};
    }
  })->then (sub {
    ## Object account calls
    return unless keys %$called_account_ids;
    my $called = {};
    for (keys %$called_account_ids) {
      my $reason = $called_account_ids->{$_};
      $object->{data}->{called}->{account_ids}->{$_}->{reason} |= $reason;
      $object->{data}->{called}->{account_ids}->{$_}->{last_sent} = $time;
      $called->{$_} |= $reason;
    }
    $changes->{fields}->{called} = {account_ids => [sort { $a cmp $b } keys %$called]};
    return $db->insert ('object_call', [map { {
      group_id => $group_id,
      object_id => ''.$object->{object_id},
      thread_id => Dongry::Type->serialize ('text', $object->{data}->{thread_id}),
      from_account_id => Dongry::Type->serialize ('text', $opts->{account}->{account_id}),
      to_account_id => Dongry::Type->serialize ('text', $_),
      timestamp => $time,
      read => 0,
      reason => $called->{$_},
    } } keys %$called], duplicate => {
      timestamp => $db->bare_sql_fragment ('values(`timestamp`)'),
      thread_id => $db->bare_sql_fragment ('values(`thread_id`)'),
      from_account_id => $db->bare_sql_fragment ('values(`from_account_id`)'),
      read => 0,
      reason => $db->bare_sql_fragment ('`reason` | values(`reason`)'),
    })->then (sub {
      return $db->delete ('object_call', {
        timestamp => {'<', $time - 7*24*60*60},
        read => 1,
      });
    });
  })->then (sub {
    my $index_ids = $edits->{index_ids};
    return unless defined $index_ids;
    
    ## Note that, even when |$changes->{fields}->{timestamp}| or
    ## |$changes->{fields}->{title}| is true, `index_object`'s
    ## `updated` is not updated...

    my $new = {map { $_ => 1 } @$index_ids};
    my $old = {%{$object->{data}->{index_ids} or {}}};
    my $changed;
    my @new_id;
    for (keys %$new) {
      unless (delete $old->{$_}) {
        $reactions->{new}->{index_ids}->{$_} = 1;
        $changed = 1;
        push @new_id, $_;
      }
    }
    for (keys %$old) {
      $reactions->{old}->{index_ids}->{$_} = 1;
      $changed = 1;
    }

    return unless $changed or $changes->{fields}->{timestamp};

    $object->{data}->{index_ids} = $new;
    $changes->{fields}->{index_ids} = 1;

    my $index_id_to_type = {};
    return Promise->resolve->then (sub {
      return unless @new_id;
      return $db->select ('index', {
        group_id => $group_id,
        index_id => {-in => \@new_id},
        owner_status => 1, # open
        user_status => 1, # open
      }, fields => ['index_id', 'index_type'])->then (sub {
        $index_id_to_type = {map {
          $_->{index_id} => $_->{index_type};
        } @{$_[0]->all}};
        for (@new_id) {
          die [400, 'Bad |index_id| ('.$_.')']
              unless exists $index_id_to_type->{$_};
          if ($index_id_to_type->{$_} == 3) { # todo
            unless (defined $object->{data}->{todo_state}) {
              $object->{data}->{todo_state} = 1; # open
              $changes->{fields}->{todo_state} = 1;
            }
          }
        }
      });

    ## Before this line, don't write anything to the database.
    ## After this line, don't throw without completing the edit.

    })->then (sub {
      if (@$index_ids) {
        my $wiki_name_key = sha1_hex +Dongry::Type->serialize ('text', $object->{data}->{title});
        return Promise->all ([
          $db->insert ('index_object', [map {
                  +{
                    group_id => $group_id,
                    index_id => $_,
                    object_id => ''.$object->{object_id},
                    created => $time,
                    timestamp => $object->{data}->{timestamp},
                    wiki_name_key => $wiki_name_key,
                  };
                } @$index_ids], duplicate => {
                  timestamp => $db->bare_sql_fragment ('values(`timestamp`)'),
                  wiki_name_key => $db->bare_sql_fragment ('values(`wiki_name_key`)'),
                }),
                $db->delete ('index_object', {
                  group_id => $group_id,
                  index_id => {-not_in => $index_ids},
                  object_id => ''.$object->{object_id},
                }),
              ]);
            } else { # no $index_ids
              return $db->delete ('index_object', {
                group_id => $group_id,
                object_id => ''.$object->{object_id},
              });
            }
          });
        })->then (sub {
          delete $changes->{fields} unless keys %{$changes->{fields} or {}};
          return unless keys %$changes;

          my $sdata;
          my $rev_data = {changes => $changes};

          ## Revision metadata (for importing)
          for my $key (qw(timestamp)) {
            my $v = $app->bare_param ('revision_' . $key);
            $rev_data->{$key} = 0+$v if defined $v;
          }
          for my $key (qw(author_name author_hatena_id imported_url)) {
            my $v = $app->text_param ('revision_' . $key);
            $rev_data->{$key} = $v if defined $v;
          }
          
          return $db->execute ('select uuid_short() as uuid')->then (sub {
            $object->{data}->{object_revision_id} = ''.$_[0]->first->{uuid};
          })->then (sub {
            return unless keys %$reactions;
            $reactions->{object_revision_id} = $object->{data}->{object_revision_id};
            return create_object ($db, 
              group_id => $group_id,
              author_account_id => $opts->{account}->{account_id},
              body_type => 3, # data
              body_data => $reactions,
              parent_object_id => $object->{object_id},
              thread_id => $object->{data}->{thread_id},
            );
          })->then (sub {
            my $from_imported = {};
            for (keys %{$trackbacks->{urls}}) {
              my $url = Web::URL->parse_string ($_);
              next unless defined $url and $url->is_http_s;
              my ($urls, undef) = get_import_source $url;
              for my $u (@$urls) {
                push @{$from_imported->{$u} ||= []}, $_;
              }
            }
            return unless keys %$from_imported;

            return $db->select ('imported', {
              group_id => $group_id,
              source_page_sha => {-in => [map {
                sha1_hex (Dongry::Type->serialize ('text', $_));
              } keys %$from_imported]},
              type => 2, # object
            }, fields => ['dest_id', 'source_page'])->then (sub {
              my $imports = $_[0]->all;
              for (@$imports) {
                if (not $object->{data}->{trackbacked}->{objects}->{$_->{dest_id}} and
                    not $_->{dest_id} == $object->{object_id}) {
                  $trackbacks->{objects}->{$_->{dest_id}} = 1;
                  $object->{data}->{trackbacked}->{objects}->{$_->{dest_id}} = 1;
                }
                for (@{$from_imported->{Dongry::Type->parse ('text', $_->{source_page})} or []}) {
                  delete $trackbacks->{urls}->{$_};
                  $object->{data}->{trackbacked}->{urls}->{$_} = 1;
                }
              }
            });
          })->then (sub {
            return unless keys %{$trackbacks->{urls} or {}};

            # XXX check existing url bookmarks

            ## For future imports or url bookmakrs
            return $db->insert ('url_ref', [map {
              +{
                group_id => $group_id,
                source_id => ''.$object->{object_id},
                dest_url => Dongry::Type->serialize ('text', $_),
                dest_url_sha => sha1_hex (Dongry::Type->serialize ('text', $_)),
                created => $time,
                timestamp => $object->{data}->{timestamp},
              };
            } keys %{$trackbacks->{urls} or {}}], duplicate => 'ignore');
          })->then (sub {
            return _write_object_trackbacks (
              $db,
              $group_id,
              [keys %{$trackbacks->{objects} or {}}],
              $opts->{account}->{account_id},
              $object->{object_id},
              ## If this is the first time the entry is edited with a
              ## timestamp, use the timestamp (consider if an old
              ## entry is imported).  Otherwise, use the current time
              ## (for references added in later changes).
              ($changes->{fields}->{timestamp} ? $object->{data}->{timestamp} : $time),
              $time,
            );
          })->then (sub {
            return unless keys %{$trackbacks->{wiki_names} or {}};
            my @x;
            return $db->select ('index', {
              group_id => $group_id,
              index_id => {-in => [map {
                Dongry::Type->serialize ('text', $_);
              } keys %{$trackbacks->{wiki_names}}]},
            }, fields => ['index_id'])->then (sub {
              my $indexes = $_[0]->all->to_a;
              return promised_map {
                my $index_id = Dongry::Type->serialize ('text', $_[0]->{index_id});
                return promised_map {
                  my $wiki_name = $_[0];
                  return create_object ($db,
                    group_id => $group_id,
                    author_account_id => $opts->{account}->{account_id},
                    body_type => 3, # data
                    body_data => {
                      trackback => {
                        object_id => ''.$object->{object_id},
                      },
                    },
                  )->then (sub {
                    push @x, {
                      group_id => $group_id,
                      index_id => $index_id,
                      wiki_name_key => sha1_hex (Dongry::Type->serialize ('text', $wiki_name)),
                      object_id => $_[0]->{object_id},
                      created => $time,
                      timestamp => $time,
                    };
                  });
                } [keys %{$trackbacks->{wiki_names}->{$index_id}}];
              } $indexes;
            })->then (sub {
              return unless @x;
              return $db->insert ('wiki_trackback_object', \@x);
            });
    })->then (sub {
      $sdata = Dongry::Type->serialize ('json', $object->{data});
            return $db->insert ('object_revision', [{
              group_id => $group_id,
              object_id => ''.$object->{object_id},
              data => $sdata,

              object_revision_id => $object->{data}->{object_revision_id},
              revision_data => Dongry::Type->serialize ('json', $rev_data),
              author_account_id => Dongry::Type->serialize ('text', $opts->{account}->{account_id}),
              created => $time,

              owner_status => $object->{data}->{owner_status},
              user_status => 1, # open, not $object->{data}->{user_status},
            }]);
          })->then (sub {
            my $update = {
              title => Dongry::Type->serialize ('text', $object->{data}->{title} // ''),
              data => $sdata,
              (defined $search_data
                ? (search_data => Dongry::Type->serialize ('text', $search_data))
                : ()),
              timestamp => $object->{data}->{timestamp},
              updated => $time,
            };

            ## XXX for backcompat
            $object->{data}->{owner_status} //= ($changes->{fields}->{owner_status} = 1);
            $object->{data}->{user_status} //= ($changes->{fields}->{user_status} = 1);
            $object->{data}->{thread_id} //= ($changes->{fields}->{thread_id} = ''.$object->{object_id});

            for my $key (qw(owner_status user_status thread_id
                            parent_object_id)) {
              $update->{$key} = $object->{data}->{$key} || 0
                  if $changes->{fields}->{$key};
            }
            return $db->update ('object', $update, where => {
              group_id => $group_id,
              object_id => ''.$object->{object_id},
            });
          })->then (sub {
            return $opts->{acall}->(['group', 'touch'], {
              context_key => $app->config->{accounts}->{context} . ':group',
              group_id => $group_id,
            })->();
          })->then (sub {
            return unless keys %{$object->{data}->{index_ids} or {}};
            return $db->update ('index', {
              updated => $time,
            }, where => {
              group_id => $group_id,
              index_id => {-in => [map {
                Dongry::Type->serialize ('text', $_);
              } keys %{$object->{data}->{index_ids} or {}}]},
            });
          });
  })->then (sub {
          ## Source metadata (for importing)
          my $ts = $app->bare_param ('source_timestamp');
          my $rev_ts = $app->bare_param ('source_rev_timestamp');
          my $sha = $app->bare_param ('source_sha');
          my $s_sha = $app->bare_param ('source_source_sha');
          my $type = $app->bare_param ('source_type');
          ## fixing mapping gr:25241595326780653 # XXX remove after R2/1/1
          my $ss;
          my $sp;
          if (defined $sha) {
            my ($source_site_url, $source_page_url) = source_urls $app;
            if (defined $source_page_url and
                $source_page_url->fragment =~ m{^hatenastar:}) {
              $ss = Dongry::Type->serialize ('text', $source_site_url->stringify);
              $sp = Dongry::Type->serialize ('text', $source_page_url->stringify);
            }
          }
          # XXX
          return unless $ts or $rev_ts or defined $sha or defined $s_sha or defined $type;
          my $info = {};
          $info->{timestamp} = 0+$ts if $ts;
          $info->{rev_timestamp} = 0+$rev_ts if $rev_ts;
          $info->{sha} = $sha if defined $sha;
          $info->{source_sha} = $s_sha if defined $s_sha;
          $info->{source_type} = $type if defined $type;
          # XXX
          if (defined $ss and defined $sp) {
            return $db->insert ('imported', [{
              group_id => $group_id,
              source_site => $ss,
              source_site_sha => (sha1_hex $ss),
              source_page => $sp,
              source_page_sha => (sha1_hex $sp),
              created => $time,
              updated => $time,
              type => 2, # object
              dest_id => ''.$object->{object_id},
              sync_info => Dongry::Type->serialize ('json', $info),
            }], duplicate => {
              source_site => $db->bare_sql_fragment ('values(`source_site`)'),
              source_site_sha => $db->bare_sql_fragment ('values(`source_site_sha`)'),
              source_page => $db->bare_sql_fragment ('values(`source_page`)'),
              source_page_sha => $db->bare_sql_fragment ('values(`source_page_sha`)'),
              updated => $db->bare_sql_fragment ('values(`updated`)'),
              type => $db->bare_sql_fragment ('values(`type`)'),
              dest_id => $db->bare_sql_fragment ('values(`dest_id`)'),
              sync_info => $db->bare_sql_fragment ('values(`sync_info`)'),
            });
          } else {
            return $db->update ('imported', {
              sync_info => Dongry::Type->serialize ('json', $info),
              updated => $time,
            }, where => {
              group_id => $group_id,
              type => 2, # object
              dest_id => ''.$object->{object_id},
            });
          }
  })->then (sub {
    return {
      object_revision_id => ''.$object->{data}->{object_revision_id},
      called => $object->{data}->{called} || {},
    } if keys %{$changes->{fields}};
    return {};
  });
} # edit_object

sub create ($$$$) {
  my ($class, $app, $db, $acall) = @_;

  # /g/create.json
  $app->requires_request_method ({POST => 1});
  $app->requires_same_origin;

  return $acall->(['info'], {
    sk_context => $app->config->{accounts}->{context},
    sk => $app->http->request_cookies->{sk},
  })->(sub {
    my $account_data = $_[0];
    return $app->throw_error (403, reason_phrase => 'No user account')
        unless defined $account_data->{account_id};

    my $title = $app->text_param ('title') // '';
    return $app->throw_error (400, reason_phrase => 'Bad |title|')
        unless length $title;

    my $group_id;
    return $acall->(['group', 'create'], {
      context_key => $app->config->{accounts}->{context} . ':group',
      owner_status => 1, # open
      admin_status => 1, # open
    })->(sub {
      $group_id = $_[0]->{group_id};
    })->then (sub {
      return create_object ($db,
        group_id => $group_id,
        author_account_id => $account_data->{account_id},
        body_type => 3, # data
        body_data => {
          title => $title,
        },
      )->then (sub {
        my $result = $_[0];
        return $acall->(['group', 'data'], {
          context_key => $app->config->{accounts}->{context} . ':group',
          group_id => $group_id,
          name => ['title', 'theme', 'object_id'],
          value => [$title, 'green', $result->{object_id}],
        })->();
      });
    })->then (sub {
      return $acall->(['group', 'member', 'status'], {
        context_key => $app->config->{accounts}->{context} . ':group',
        group_id => $group_id,
        account_id => $account_data->{account_id},
        member_type => 2, # owner
        user_status => 1, # open
        owner_status => 1, # open
      })->();
    })->then (sub {
      return $acall->(['group', 'member', 'data'], {
        context_key => $app->config->{accounts}->{context} . ':group',
        group_id => $group_id,
        account_id => $account_data->{account_id},
        name => 'name',
        value => $account_data->{name},
      })->();
    })->then (sub {
      # XXX ipaddr logging
      return json $app, {
        group_id => $group_id,
      };
    });
  });
} # create

sub main ($$$$$) {
  my ($class, $app, $path, $db, $acall) = @_;

  ## Pjax (partition=group)
  if (
    (@$path == 3 and {
      '' => 1,         # /g/{group_id}/
      'search' => 1,   # /g/{group_id}/search
      'config' => 1,   # /g/{group_id}/config
      'members' => 1,  # /g/{group_id}/members
    }->{$path->[2]}) or
    (@$path == 4 and $path->[2] eq 'my' and {
      'config' => 1,   # /g/{group_id}/my/config
    }->{$path->[3]}) or
    (@$path == 5 and $path->[2] eq 'i' and $path->[3] =~ /\A[1-9][0-9]*\z/ and {
      '' => 1,         # /g/{group_id}/i/{index_id}/
      'config' => 1,   # /g/{group_id}/i/{index_id}/config
    }->{$path->[4]}) or
    (@$path == 5 and $path->[2] eq 'o' and $path->[3] =~ /\A[1-9][0-9]*\z/ and {
      '' => 1,         # /g/{group_id}/o/{object_id}/
      'revisions' => 1,# /g/{group_id}/o/{object_id}/revisions
    }->{$path->[4]}) or
    # /g/{group_id}/wiki/{wiki_name}
    (@$path == 4 and $path->[2] eq 'wiki' and length $path->[3]) or
    # /g/{group_id}/i/{index_id}/wiki/{wiki_name}
    (@$path == 6 and $path->[2] eq 'i' and $path->[3] =~ /\A[1-9][0-9]*\z/ and $path->[4] eq 'wiki' and length $path->[5]) or
    (@$path == 5 and $path->[2] eq 'account' and $path->[3] =~ /\A[1-9][0-9]*\z/ and {
      '' => 1,         # /g/{group_id}/account/{index_id}/
    }->{$path->[4]})
  ) {
    return $acall->(['info'], {
      sk_context => $app->config->{accounts}->{context},
      sk => $app->http->request_cookies->{sk},

      context_key => $app->config->{accounts}->{context} . ':group',
      group_id => $path->[1],

      admin_status => 1,
      owner_status => 1,
      with_group_data => ['title', 'theme'],
    })->(sub {
      my $account_data = $_[0];
      unless (defined $account_data->{account_id}) {
        my $this_url = Web::URL->parse_string ($app->http->url->stringify);
        my $url = Web::URL->parse_string (q</account/login>, $this_url);
        $url->set_query_params ({next => $this_url->stringify});
        return $app->send_redirect ($url->stringify);
      }

      my $group = $account_data->{group};
      return $app->throw_error (404, reason_phrase => 'Group not found')
          unless defined $group;

      my $membership = $account_data->{group_membership};
      return $app->throw_error (403, reason_phrase => 'Not a group member')
          if not defined $membership or
             not ($membership->{member_type} == 1 or # member
                  $membership->{member_type} == 2) or # owner
             $membership->{user_status} != 1 or # open
             $membership->{owner_status} != 1; # open

      return temma $app, 'group.index.html.tm', {
        group => $group,
      };
    });
  }
  
  # /g/{group_id}/...
  return $acall->(['info'], {
    sk_context => $app->config->{accounts}->{context},
    sk => $app->http->request_cookies->{sk},

    context_key => $app->config->{accounts}->{context} . ':group',
    group_id => $path->[1],
    # XXX
    admin_status => 1,
    owner_status => 1,
    with_group_data => ['title', 'theme', 'default_wiki_index_id',
                        'object_id', 'icon_object_id'],
    with_group_member_data => ['name', 'default_index_id',
                               'icon_object_id'],
  })->(sub {
    my $account_data = $_[0];
    unless (defined $account_data->{account_id}) {
      if ($app->http->request_method eq 'GET' and
          not $path->[-1] =~ /\.json\z/) {
        my $this_url = Web::URL->parse_string ($app->http->url->stringify);
        my $url = Web::URL->parse_string (q</account/login>, $this_url);
        $url->set_query_params ({next => $this_url->stringify});
        return $app->send_redirect ($url->stringify);
      } else {
        return $app->throw_error (403, reason_phrase => 'No user account');
      }
    }

    my $group = $account_data->{group};
    return $app->throw_error (404, reason_phrase => 'Group not found')
        unless defined $group;

    my $membership = $account_data->{group_membership};
    return $app->throw_error (403, reason_phrase => 'Not a group member')
        if not defined $membership or
           not ($membership->{member_type} == 1 or # member
                $membership->{member_type} == 2) or # owner
           $membership->{user_status} != 1 or # open
           $membership->{owner_status} != 1; # open

    return $class->group ($app, $path, {
      account => $account_data,
      db => $db, group => $group, group_member => $membership,
      acall => $acall,
    });
  });
} # main

sub group ($$$$) {
  my ($class, $app, $path, $opts) = @_;
  
  my $db = $opts->{db};

  if (@$path >= 4 and $path->[2] eq 'i') {
    # /g/{group_id}/i/...
    return $class->group_index ($app, $path, $opts);
  }

  if (@$path >= 4 and $path->[2] eq 'o') {
    # /g/{group_id}/o/...
    return $class->group_object ($app, $path, $opts);
  }

  if ($path->[2] eq 'my') {
    return $class->group_my ($app, $path, $opts);
  } elsif ($path->[2] eq 'members') {
    return $class->group_members ($app, $path, $opts);
  }

  if (@$path == 3 and $path->[2] eq 'edit.json') {
    # /g/{group_id}/edit.json
    # racy!
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;
    my @name;
    my @value;
    my $title = $app->text_param ('title') // '';
    my $dd = {};
    if (length $title) {
      push @name, 'title';
      push @value, $title;
      $dd->{title} = $title;
    }
    my $theme = $app->text_param ('theme') // '';
    if (length $theme) {
      push @name, 'theme';
      push @value, $theme;
      $dd->{theme} = $theme;
    }
    return Promise->resolve->then (sub {
      my $wiki_id = $app->bare_param ('default_wiki_index_id');
      return unless defined $wiki_id;
      return $db->select ('index', {
        group_id => Dongry::Type->serialize ('text', $opts->{group}->{group_id}),
        index_id => $wiki_id,
        user_status => 1, # open
        owner_status => 1, # open
      }, fields => ['index_id'])->then (sub {
        return $app->throw_error (400, reason_phrase => 'Bad |default_wiki_index_id|')
            unless $_[0]->first;
        push @name, 'default_wiki_index_id';
        push @value, $wiki_id;
        $dd->{default_wiki_index_id} = $wiki_id;
      });
    })->then (sub {
      my $icon_id = $app->bare_param ('icon_object_id');
      return unless defined $icon_id;
      return $db->select ('object', {
        group_id => Dongry::Type->serialize ('text', $opts->{group}->{group_id}),
        object_id => $icon_id,
      }, fields => ['object_id'])->then (sub {
        return $app->throw_error (400, reason_phrase => 'Bad |object_id|')
            unless $_[0]->first;
        push @name, 'icon_object_id';
        push @value, $icon_id;
        $dd->{icon_object_id} = $icon_id;
      });
    })->then (sub {
      return unless @name;
      if (defined $opts->{group}->{data}->{object_id}) {
        return $db->select ('object', {
          group_id => Dongry::Type->serialize ('text', $opts->{group}->{group_id}),
          object_id => Dongry::Type->serialize ('text', $opts->{group}->{data}->{object_id}),
        }, fields => ['object_id', 'data'])->then (sub {
          my $object = $_[0]->first;
          die "Object |$opts->{group}->{data}->{object_id}| not found"
              unless defined $object;
          $object->{data} = Dongry::Type->parse ('json', $object->{data});
          return $object;
        });
      } else {
        ## Backcompat: Groups created before 2019-08 update might not
        ## have group object.
        return create_object ($db,
          group_id => Dongry::Type->serialize ('text', $opts->{group}->{group_id}),
          author_account_id => $opts->{account}->{account_id},
          body_type => 3, # data
          body_data => {},
        )->then (sub {
          my $result = $_[0];
          $opts->{group}->{data}->{object_id} = $result->{object_id};
          push @name, 'object_id';
          push @value, $result->{object_id};
          return $result->{object};
        });
      }
    })->then (sub {
      return unless @name;
      my $object = $_[0];
      return Promise->all ([
        $opts->{acall}->(['group', 'data'], {
          context_key => $app->config->{accounts}->{context} . ':group',
          group_id => Dongry::Type->serialize ('text', $opts->{group}->{group_id}),
          name => \@name,
          value => \@value,
        })->(),
        edit_object ($opts, $db, $object, {
          body_data_delta => $dd,
        }, $app),
      ]);
    })->then (sub {
      return unless @name;
      return $opts->{acall}->(['group', 'touch'], {
        context_key => $app->config->{accounts}->{context} . ':group',
        group_id => Dongry::Type->serialize ('text', $path->[1]),
      }); # XXX ->()
    })->then (sub {
      return json $app, {};
    });
  }

  if (@$path == 5 and $path->[2] eq 'imported' and
      ($path->[4] eq 'go' or $path->[4] eq 'go.json')) {
    # /g/{group_id}/imported/{page}/go
    # /g/{group_id}/imported/{page}/go.json
    my $page = Web::URL->parse_string ($path->[3]);
    return $app->throw_error (404, reason_phrase => 'Bad page URL')
        if not defined $page or not $page->is_http_s;

    my ($urls, $suffix) = get_import_source $page;

    return $db->select ('imported', {
      group_id => Dongry::Type->serialize ('text', $path->[1]),
      source_page_sha => {-in => [map {
        sha1_hex (Dongry::Type->serialize ('text', $_));
      } @$urls]},
    }, fields => ['type', 'dest_id'], limit => 1)->then (sub {
      my $selected = $_[0]->first;
      if (not defined $selected) {
        #
      } elsif ($selected->{type} == 1) {
        return '../../i/' . $selected->{dest_id} . '/' . $suffix;
      } elsif ($selected->{type} == 2) {
        return '../../o/' . $selected->{dest_id} . '/' . $suffix;
      }

      my $origin1 = $page->get_origin->to_ascii;
      my $origin2 = $origin1;
      $origin1 =~ s/^http:/https:/g;
      $origin2 =~ s/^https:/http:/g;
      return $db->execute (q{
        select `group_id` from `imported`
        where `group_id` = :group_id and
              (`source_site` like :ss1 or
               `source_site` like :ss2)
        limit 1
      }, {
        group_id => Dongry::Type->serialize ('text', $path->[1]),
        ss1 => like (Dongry::Type->serialize ('text', $origin1)) . '%',
        ss2 => like (Dongry::Type->serialize ('text', $origin2)) . '%',
      })->then (sub {
        if ($_[0]->first) {
          return $page->stringify;
        } else {
          return $app->throw_error (404, reason_phrase => 'Bad page origin')
        }
      });
    })->then (sub {
      my $url = $_[0];
      if ($path->[4] eq 'go') {
        return $app->send_redirect ($url);
      } else {
        return json $app, {url => $app->http->url->resolve_string ($url)->stringify};
      }
    });
  }

  if (@$path == 5 and $path->[2] eq 'imported' and $path->[4] eq 'list.json') {
    # /g/{group_id}/imported/{site}/list.json
    my $site = Web::URL->parse_string ($path->[3]);
    return $app->throw_error (404, reason_phrase => 'Bad site URL')
        unless defined $site;
    my $page = Pager::this_page ($app, limit => 100, max_limit => 100);
    my $where = {
      group_id => Dongry::Type->serialize ('text', $path->[1]),
      source_site_sha => sha1_hex (Dongry::Type->serialize ('text', $site->stringify)),
    };
    $where->{created} = $page->{value} if defined $page->{value};
    return $db->select ('imported', $where,
      fields => ['source_page', 'created', 'updated', 'type', 'dest_id', 'sync_info'],
      offset => $page->{offset}, limit => $page->{limit},
      order => ['created', $page->{order_direction}],
    )->then (sub {
      my $items = $_[0]->all->to_a;
      for (@$items) {
        $_->{sync_info} = Dongry::Type->parse ('json', $_->{sync_info});
        $_->{dest_id} .= '';
      }
      my $next_page = Pager::next_page $page, $items, 'created';
      return json $app, {items => $items, %$next_page};
    });
  }

  if (@$path == 3 and $path->[2] eq 'import') {
    # /g/{}/import
    return temma $app, 'group.import.html.tm', {
      account => $opts->{account},
      group => $opts->{group},
      group_member => $opts->{group_member},
    };
  }

  if (@$path == 3 and $path->[2] eq 'icon') {
    # /g/{}/icon
    my $id = $opts->{group}->{data}->{icon_object_id};
    $app->http->add_response_header
        ('Cache-Control' => 'private,max-age=108000');
    my $url = defined $id ? "o/$id/image" : "/favicon.ico";
    return $app->send_redirect ($url);
  }

  if (@$path == 5 and $path->[2] eq 'account' and
      $path->[3] =~ /\A[1-9][0-9]*\z/ and $path->[4] eq 'icon') {
    # /g/{}/account/{account_id}/icon
    return $opts->{acall}->(['group', 'members'], {
      context_key => $app->config->{accounts}->{context} . ':group',
      group_id => $opts->{group}->{group_id},
      with_data => ['icon_object_id'],
      account_id => $path->[3],
    })->(sub {
      my $json = $_[0];
      my $gm = $json->{memberships}->{$path->[3]};
      my $id = $gm->{data}->{icon_object_id}; # or undef
      $app->http->add_response_header
          ('Cache-Control' => 'private,max-age=108000');
      my $url = defined $id ? "../../o/$id/image" : "/images/person.svg";
      return $app->send_redirect ($url);
    });
  }
  
  return $app->throw_error (404);
} # group

sub group_my ($$$$) {
  my ($class, $app, $path, $opts) = @_;

  if (@$path == 4 and $path->[3] eq 'info.json') {
    # /g/{group_id}/my/info.json
    my $acc = $opts->{account};
    my $g = $opts->{group};
    my $gm = $opts->{group_member};
    return json $app, {
      account => {
        account_id => ''.$acc->{account_id},
        name => $gm->{data}->{name} // $acc->{name},
        icon_object_id => $gm->{data}->{icon_object_id}, # or undef
      },
      group => {
        group_id => ''.$g->{group_id},
        title => $g->{data}->{title},
        created => $g->{created},
        updated => $g->{updated},
        theme => $g->{data}->{theme},
        default_wiki_index_id => $g->{data}->{default_wiki_index_id}, # or undef
        object_id => $g->{data}->{object_id}, # or undef
        icon_object_id => $g->{data}->{icon_object_id}, # or undef
      },
      group_member => {
        theme => $gm->{data}->{theme},
        member_type => $gm->{member_type},
        default_index_id => $gm->{data}->{default_index_id}, # or undef
      },
    };
  } elsif (@$path == 4 and $path->[3] eq 'edit.json') {
    # /g/{group_id}/my/edit.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;

    my $names = [];
    my $values = [];
    my $waits = [];

    my $name = $app->text_param ('name') // '';
    if (length $name) {
      push @$names, 'name';
      push @$values, $name;
    }

    my $icon_id = $app->bare_param ('icon_object_id') // '';
    if (length $icon_id) {
      push @$waits, $opts->{db}->select ('object', {
        group_id => Dongry::Type->serialize ('text', $opts->{group}->{group_id}),
        object_id => $icon_id,
      }, fields => ['object_id'])->then (sub {
        return $app->throw_error (400, reason_phrase => 'Bad |object_id|')
            unless $_[0]->first;
        push @$names, 'icon_object_id';
        push @$values, $icon_id;
      });
    }

    ## Changes are not logged.
    return Promise->all ($waits)->then (sub {
      return unless @$names;
      return $opts->{acall}->(['group', 'member', 'data'], {
        context_key => $app->config->{accounts}->{context} . ':group',
        group_id => $opts->{group}->{group_id},
        account_id => $opts->{account}->{account_id},
        name => $names,
        value => $values,
      })->();
    })->then (sub {
      return json $app, {};
    });
  }

  return $app->throw_error (404);
} # group_my

sub group_members ($$$$) {
  my ($class, $app, $path, $opts) = @_;

  if (@$path == 5 and
      $path->[3] eq 'invitations' and
      $path->[4] eq 'list.json') {
    # /g/{}/members/invitations/list.json
    $app->throw_error (403, reason_phrase => 'Not an owner')
        unless $opts->{group_member}->{member_type} == 2; # owner
    return $opts->{acall}->(['invite', 'list'], {
      context_key => $app->config->{accounts}->{context} . ':group',
      invitation_context_key => 'group-' . $opts->{group}->{group_id},
      ref => $app->bare_param ('ref'),
      limit => $app->bare_param ('limit'),
    })->(sub {
      for (values %{$_[0]->{invitations}}) {
        $_->{group_id} = ''.$opts->{group}->{group_id};
        $_->{invitation_url} = $app->http->url->resolve_string ("/invitation/$_->{group_id}/$_->{invitation_key}/")->stringify,
      }
      return json $app, $_[0];
    }, sub {
      return $app->send_error (400, reason_phrase => $_[0]->{reason});
    });
  } # /g/{}/members/invitations/list.json

  if (@$path == 5 and
      $path->[3] eq 'invitations' and
      $path->[4] eq 'create.json') {
    # /g/{}/members/invitations/create.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;
    $app->throw_error (403, reason_phrase => 'Not an owner')
        unless $opts->{group_member}->{member_type} == 2; # owner

    return $opts->{acall}->(['invite', 'create'], {
      sk_context => $app->config->{accounts}->{context},
      sk => $app->http->request_cookies->{sk},

      context_key => $app->config->{accounts}->{context} . ':group',
      invitation_context_key => 'group-' . $opts->{group}->{group_id},
      account_id => $opts->{account}->{account_id},
      data => (perl2json_chars {
        member_type => $app->bare_param ('member_type') // 1, # member
      }),
      expires => time + 3*24*60*60,
    })->(sub {
      my $json = $_[0];
      return json $app, {
        expires => $json->{expires},
        invitation_url => $app->http->url->resolve_string ("/invitation/$opts->{group}->{group_id}/$json->{invitation_key}/")->stringify,
        group_id => ''.$opts->{group}->{group_id},
        invitation_key => $json->{invitation_key},
      };
    });
  } # /g/{}/members/invitations/create.json

  if (@$path == 6 and
      $path->[3] eq 'invitations' and
      length $path->[4] and
      $path->[5] eq 'invalidate.json') {
    # /g/{group_id}/members/invitations/{invitation_key}/invalidate.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;
    $app->throw_error (403, reason_phrase => 'Not an owner')
        unless $opts->{group_member}->{member_type} == 2; # owner
    return $opts->{acall}->(['invite', 'use'], {
      context_key => $app->config->{accounts}->{context} . ':group',
      invitation_context_key => 'group-' . $opts->{group}->{group_id},
      invitation_key => $path->[4],
      ignore_target => 1,
      data => (perl2json_chars {
        operator_account_id => $opts->{account}->{account_id},
        group_id => $opts->{group}->{group_id},
      }),
    })->(sub {
      return json $app, {};
    }, sub {
      if ($_[0]->{reason} eq 'Bad invitation') {
        return $app->throw_error (404, reason_phrase => $_[0]->{reason});
      } else {
        return $app->throw_error (400, reason_phrase => $_[0]->{reason});
      }
    });
  } # /g/{group_id}/members/invitations/{invitation_key}/invalidate.json

  return $app->throw_error (404);
} # group_members

sub group_members_status ($$$$) {
  my ($class, $app, $group_id, $acall) = @_;
  # /g/{group_id}/members/status.json
  $app->requires_request_method ({POST => 1});
  $app->requires_same_origin;
  return $acall->(['info'], {
    sk_context => $app->config->{accounts}->{context},
    sk => $app->http->request_cookies->{sk},

    context_key => $app->config->{accounts}->{context} . ':group',
    group_id => $group_id,
    # XXX
    group_admin_status => 1,
    group_owner_status => 1,
  })->(sub {
    my $account_data = $_[0];

      return $app->throw_error (403, reason_phrase => 'No user account')
          unless defined $account_data->{account_id};

      my $group = $account_data->{group};
      return $app->throw_error (404, reason_phrase => 'Group not found')
          unless defined $group;

      my $membership = $account_data->{group_membership};

      my $is_owner = (
        defined $membership and
        $membership->{member_type} == 2 and # owner
        $membership->{user_status} == 1 and # open
        $membership->{owner_status} == 1 # open
      );

      my $account_id = $app->bare_param ('account_id') // '';
      return $app->throw_error (400, reason_phrase => 'Bad |account_id|')
          unless $account_id =~ /\A[1-9][0-9]*\z/;

      my %update;
      if ($account_id eq $account_data->{account_id}) {
        unless ($is_owner) {
          $update{user_status} = $app->bare_param ('user_status');
          delete $update{user_status} unless defined $update{user_status};
        }
      } else {
        return $app->throw_error (403, reason_phrase => 'Not an owner')
            unless $is_owner;
        for my $key (qw(owner_status member_type)) {
          $update{$key} = $app->bare_param ($key);
          delete $update{$key} unless defined $update{$key};
        }
      }

      return $acall->(['group', 'member', 'status'], {
        context_key => $app->config->{accounts}->{context} . ':group',
        group_id => $group_id,
        account_id => $account_id,
        %update,
      })->(sub {
        return unless $is_owner;
        my $desc = $app->text_param ('desc');
        return unless defined $desc;
        return $acall->(['group', 'member', 'data'], {
          context_key => $app->config->{accounts}->{context} . ':group',
          group_id => $group_id,
          account_id => $account_id,
          name => 'desc',
          value => $desc,
        })->();
      });
  })->then (sub {
    return json $app, {};
  });
} # group_members_status

sub group_members_list ($$$$) {
  my ($class, $app, $group_id, $acall) = @_;
  # /g/{group_id}/members/list.json
  return $acall->(['info'], {
    sk_context => $app->config->{accounts}->{context},
    sk => $app->http->request_cookies->{sk},

    context_key => $app->config->{accounts}->{context} . ':group',
    group_id => $group_id,

    # XXX
    group_admin_status => 1,
    group_owner_status => 1,
    with_group_member_data => ['name'],
  })->(sub {
    my $account_data = $_[0];

      return $app->throw_error (403, reason_phrase => 'No user account')
          unless defined $account_data->{account_id};

      my $group = $account_data->{group};
      return $app->throw_error (404, reason_phrase => 'Group not found')
          unless defined $group;

      my $membership = $account_data->{group_membership};

      my $is_member = (
        defined $membership and
        ($membership->{member_type} == 2 or # owner
         $membership->{member_type} == 1) and # member
        $membership->{owner_status} == 1 and # open
        $membership->{user_status} == 1 # open
      );

      return json $app, {members => {
        $account_data->{account_id} => {
          account_id => $account_data->{account_id},
          member_type => 0,
          owner_status => $membership->{owner_status} || 0,
          user_status => $membership->{user_status} || 0,
          default_index_id => undef,
          desc => '',
          name => $membership->{data}->{name} // $account_data->{account_id},
        },
      }} unless $is_member;

      return $acall->(['group', 'members'], {
        context_key => $app->config->{accounts}->{context} . ':group',
        group_id => $group_id,
        with_data => ['name', 'default_index_id', 'desc'],
        ref => $app->text_param ('ref'),
      })->(sub {
        my $members = {map {
          $_->{account_id} => {
            account_id => ''.$_->{account_id},
            member_type => $_->{member_type},
            owner_status => $_->{owner_status},
            user_status => $_->{user_status},
            default_index_id => ($_->{data}->{default_index_id} ? $_->{data}->{default_index_id} : undef),
            desc => $_->{data}->{desc} // '',
            name => $_->{data}->{name} // ''.$_->{account_id},
          };
        } values %{$_[0]->{memberships}}};
        return json $app, {members => $members,
                           next_ref => $_[0]->{next_ref},
                           has_next => $_[0]->{has_next}};
      });
  });
} # group_members_list

sub group_index ($$$$) {
  my ($class, $app, $path, $opts) = @_;
  my $db = $opts->{db};

  if (@$path == 4 and $path->[3] eq 'list.json') {
    # /g/{group_id}/i/list.json
    my $i_types = $app->bare_param_list ('index_type');
    return $db->select ('index', {
      group_id => Dongry::Type->serialize ('text', $path->[1]),
      owner_status => 1,
      user_status => 1,
      (@$i_types ? (index_type => {-in => $i_types}) : ()),
    }, fields => ['index_id', 'index_type', 'title', 'updated', 'options'])->then (sub {
      my $subtypes = {map { $_ => 1 } @{$app->bare_param_list ('subtype')}};
      return json $app, {index_list => {map {
        $_->{index_id} => {
          group_id => $path->[1],
          index_id => ''.$_->{index_id},
          title => Dongry::Type->parse ('text', $_->{title}),
          updated => $_->{updated},
          index_type => $_->{index_type},
          theme => $_->{options}->{theme},
          color => $_->{options}->{color},
          deadline => $_->{options}->{deadline},
        };
      } grep {
        keys %$subtypes ? $subtypes->{$_->{options}->{subtype}} : 1;
      } map {
        $_->{options} = Dongry::Type->parse ('json', $_->{options});
        $_;
      } @{$_[0]->all}}};
    });
  }

  if (@$path >= 4 and $path->[3] =~ /\A[0-9]+\z/) {
    # /g/{group_id}/i/{index_id}
    # racy!
    return get_index ($db, $path->[1], $path->[3])->then (sub {
      my $index = $_[0];
      return $app->throw_error (404, reason_phrase => 'Index not found')
          unless defined $index;
      if (@$path == 5 and $path->[4] eq 'info.json') {
        # /g/{group_id}/i/{index_id}/info.json
        return json $app, {
          group_id => $path->[1],
          index_id => ''.$index->{index_id},
          title => $index->{title},
          created => $index->{created},
          updated => $index->{updated},
          index_type => $index->{index_type},
            ## 1 blog
            ## 2 wiki
            ## 3 todo list
            ## 4 label
            ## 5 milestone
            ## 6 fileset
          theme => $index->{options}->{theme},
          color => $index->{options}->{color}, # or undef
          deadline => $index->{options}->{deadline}, # or undef
          subtype => $index->{options}->{subtype}, # or undef
          object_id => $index->{options}->{object_id}, # or undef
        };
      } elsif (@$path == 5 and $path->[4] eq 'edit.json') {
        # /g/{group_id}/i/{index_id}/edit.json
        $app->requires_request_method ({POST => 1});
        $app->requires_same_origin;
        my $time = time;
        my %update;
        my $dd = {};
        my $title = $app->text_param ('title') // '';
        if (length $title) {
          $update{title} = Dongry::Type->serialize ('text', $title);
          $dd->{title} = $title;
        }
        my $options = $index->{options};
        my $options_modified;
        for my $key (qw(theme color)) {
          my $value = $app->text_param ($key) // '';
          if (length $value) {
            $options->{$key} = $value;
            $options_modified = 1;
            $dd->{$key} = $value;
          }
        }
        {
          my $value = $app->bare_param ('deadline');
          if (defined $value) {
            my $parser = Web::DateTime::Parser->new;
            $parser->onerror (sub { });
            my $dt = $parser->parse_date_string ($value);
            if (defined $dt) {
              $dd->{deadline} =
              $options->{deadline} = $dt->to_unix_number;
            } else {
              delete $options->{deadline};
              $dd->{deadline} = undef;
            }
            $options_modified = 1;
          }
        }
        my $index_type = $app->bare_param ('index_type');
        if (defined $index_type) {
          $dd->{index_type} =
          $update{index_type} = 0+$index_type;
        }
        return Promise->resolve->then (sub {
          return unless $options_modified or keys %update;
          if (defined $options->{object_id}) {
            return $db->select ('object', {
              group_id => Dongry::Type->serialize ('text', $opts->{group}->{group_id}),
              object_id => Dongry::Type->serialize ('text', $options->{object_id}),
            }, fields => ['object_id', 'data'])->then (sub {
              my $object = $_[0]->first;
              die "Object |$options->{object_id}| not found"
                  unless defined $object;
              $object->{data} = Dongry::Type->parse ('json', $object->{data});
              return $object;
            });
          } else {
            ## Backcompat: Indexes created before 2019-08 update might
            ## not have index object.
            return create_object ($db,
              group_id => Dongry::Type->serialize ('text', $opts->{group}->{group_id}),
              author_account_id => $opts->{account}->{account_id},
              body_type => 3, # data
              body_data => {},
              now => $time,
            )->then (sub {
              my $result = $_[0];
              $options->{object_id} = $result->{object_id};
              $options_modified = 1;
              return $result->{object};
            });
          }
        })->then (sub {
          my $object = $_[0];
          if ($options_modified) {
            $update{options} = Dongry::Type->serialize ('json', $options);
          }
          return unless keys %update;
          $update{updated} = $time;
          return Promise->all ([
            $db->update ('index', \%update, where => {
              group_id => Dongry::Type->serialize ('text', $opts->{group}->{group_id}),
              index_id => Dongry::Type->serialize ('text', $index->{index_id}),
            }),
            edit_object ($opts, $db, $object, {
              body_data_delta => $dd,
            }, $app),
          ]);
        })->then (sub {
          return json $app, {};
        });
      } elsif (@$path == 5 and $path->[4] eq 'my.json') {
        # /g/{group_id}/i/{index_id}/my.json
        $app->requires_request_method ({POST => 1});
        $app->requires_same_origin;
        my @p;
        my $is_default = $app->bare_param ('is_default');
        if (defined $is_default) {
          push @p, $opts->{acall}->(['group', 'member', 'data'], {
            context_key => $app->config->{accounts}->{context} . ':group',
            group_id => $path->[1],
            account_id => $opts->{account}->{account_id},
            name => 'default_index_id',
            value => ($is_default ? $path->[3] : 0),
            # XXX touch
          })->();
        }
        return Promise->all (\@p)->then (sub {
          return json $app, {};
        });
      } else {
        return $app->throw_error (404);
      }
    });
  }

  if (@$path == 4 and $path->[3] eq 'create.json') {
    # /g/{group_id}/i/create.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;

    my $dd = {};
    my $title = $app->text_param ('title') // '';
    return $app->throw_error (400, reason_phrase => 'Bad |title|')
        unless length $title;
    $dd->{title} = $title;

    my ($source_site_url, $source_page_url) = source_urls $app;

    my $time = time;
    return $db->execute ('select uuid_short() as uuid')->then (sub {
      my $index_id = $_[0]->first->{uuid};
      my $group_id = Dongry::Type->serialize ('text', $opts->{group}->{group_id});
      my $index_type = 0+($app->bare_param ('index_type') || 0);
      my $options = {};
      if ($index_type == 1 or $index_type == 2 or $index_type == 3) {
        $dd->{theme} =
        $options->{theme} = $app->text_param ('theme') // 'green';
      } elsif ($index_type == 4) {
        $dd->{color} =
        $options->{color} = sprintf '#%02X%02X%02X',
            int rand 256,
            int rand 256,
            int rand 256;
      }
      my $subtype = $app->bare_param ('subtype');
      $options->{subtype} = $subtype if defined $subtype;
      return create_object ($db,
        group_id => $group_id,
        author_account_id => $opts->{account}->{account_id},
        body_type => 3, # data
        body_data => $dd,
      )->then (sub {
        my $result = $_[0];
        $options->{object_id} = $result->{object}->{object_id};
        return $db->insert ('index', [{
          group_id => $group_id,
          index_id => $index_id,
          title => Dongry::Type->serialize ('text', $title),
          created => $time,
          updated => $time,
          owner_status => 1, # open
          user_status => 1, # open
          index_type => $index_type,
          options => Dongry::Type->serialize ('json', $options),
        }]);
      })->then (sub {
        return unless defined $source_site_url;
        my $page = Dongry::Type->serialize ('text', $source_page_url->stringify);
        my $site = Dongry::Type->serialize ('text', $source_site_url->stringify);
        return $db->insert ('imported', [{
          group_id => $group_id,
          source_page_sha => sha1_hex ($page),
          source_page => $page,
          source_site_sha => sha1_hex ($site),
          source_site => $site,
          created => $time,
          updated => $time,
          type => 1, # index
          dest_id => $index_id,
          sync_info => Dongry::Type->serialize ('json', {}),
        }], duplicate => {
          source_site => $db->bare_sql_fragment ('values(`source_site`)'),
          source_site_sha => $db->bare_sql_fragment ('values(`source_site_sha`)'),
          updated => $db->bare_sql_fragment ('values(`updated`)'),
          type => $db->bare_sql_fragment ('values(`type`)'),
          dest_id => $db->bare_sql_fragment ('values(`dest_id`)'),
          sync_info => $db->bare_sql_fragment ('values(`sync_info`)'),
        });
      })->then (sub {
        return json $app, {
          group_id => $path->[1],
          index_id => ''.$index_id,
        };
        # XXX touch group
      });
    });
  }

  return $app->throw_error (404);
} # group_index

sub group_object ($$$$) {
  my ($class, $app, $path, $opts) = @_;
  my $db = $opts->{db};

  if (@$path >= 4 and $path->[3] =~ /\A[0-9]+\z/) {
    # /g/{group_id}/o/{object_id}
    return $db->select ('object', {
      group_id => Dongry::Type->serialize ('text', $path->[1]),
      object_id => Dongry::Type->serialize ('text', $path->[3]),
    }, fields => ['object_id', 'data', 'owner_status', 'user_status'])->then (sub {
      my $object = $_[0]->first;
      return $app->throw_error (404, reason_phrase => 'Object not found')
          unless defined $object;
      $object->{data} = Dongry::Type->parse ('json', $object->{data});

      if (@$path == 5 and $path->[4] eq 'embed') {
        # /g/{group_id}/o/{object_id}/embed
        if ($object->{user_status} != 1 or # open
            $object->{owner_status} != 1) { # open
          return $app->throw_error (410, reason_phrase => 'Object not found');
        }

        return temma $app, 'group.object.embed.html.tm', {
          account => $opts->{account},
          group => $opts->{group},
          group_member => $opts->{group_member},
          object => $object,
        };
      } elsif (@$path == 5 and $path->[4] eq 'edit.json') {
        # /g/{group_id}/o/{object_id}/edit.json
        $app->requires_request_method ({POST => 1});
        $app->requires_same_origin;
        my $edits = {};
        for my $key (qw(title body body_source file_name
                        author_name author_hatena_id author_bb_username
                        assignee_bb_username
                        todo_bb_priority todo_bb_kind todo_bb_state
                        parent_section_id)) {
          my $value = $app->text_param ($key);
          $edits->{$key} = $value if defined $value and
              (not defined $object->{data}->{$key} or
               not $value eq $object->{data}->{$key});
        }
        for my $key (qw(timestamp body_type body_source_type
                        user_status
                        todo_state file_size file_closed)) {
          my $value = $app->bare_param ($key);
          if (defined $value) {
            my $old = $object->{data}->{$key} || 0;
            $edits->{$key} = 0+$value if $old != $value;
          }
        }
        for my $key (qw(mime_type)) {
          my $value = $app->text_param ($key);
          if (defined $value) {
            my $type = Web::MIME::Type->parse_web_mime_type ($value);
            if (defined $type) {
              $edits->{$key} = $type->as_valid_mime_type;
            }
          }
        }
        {
          my $value = $app->bare_param ('body_data');
          if (defined $value) {
            $value = json_bytes2perl $value;
            if (defined $value and ref $value eq 'HASH') {
              $edits->{body_data} = $value;
            }
          }
        }
        if ($app->bare_param ('edit_assigned_account_id')) {
          my $ids = $app->bare_param_list ('assigned_account_id');
          $edits->{assigned_account_ids} = {map { $_ => 1 } @$ids};
        }
        $edits->{parent_object_id} = $app->bare_param ('parent_object_id'); # or undef
        if ($app->bare_param ('edit_index_id')) {
          $edits->{index_ids} = $app->bare_param_list ('index_id');
        }
        return edit_object ($opts, $db, $object, $edits, $app)->then (sub {
          return json $app, $_[0];
        })->catch (sub {
          my $e = $_[0];
          if (defined $e and ref $e eq 'ARRAY') {
            return $app->throw_error ($e->[0], reason_phrase => $e->[1]);
          }
          die $e;
        });
      } elsif (@$path == 5 and
               ($path->[4] eq 'file' or $path->[4] eq 'image')) {
        # /g/{group_id}/o/{object_id}/file
        # /g/{group_id}/o/{object_id}/image
        if ($object->{data}->{body_type} != 4) { # file
          return $app->throw_error (404, reason_phrase => 'Not a file');
        }

        my $aws4 = $app->config->{storage}->{aws4};
        my $bucket = $app->config->{storage}->{bucket};
        my $url = Web::URL->parse_string ($app->config->{storage}->{url});
        my $client = Web::Transport::ConnectionClient->new_from_url ($url);
        # XXX body streaming
        return $client->request (
          method => 'GET',
          path => [$bucket, $path->[3]],
          aws4 => $aws4,
        )->then (sub {
          if ($_[0]->status == 200) {
            my $mime = $object->{data}->{mime_type} // 'application/octet-stream';
            if ($path->[4] eq 'image' and not $mime =~ m{^image/}) {
              return $app->throw_error (404, reason_phrase => 'Not an image');
            }
            $app->http->set_response_header ('content-type', $mime);
            unless ($path->[4] eq 'image') {
              $app->http->set_response_disposition
                  (disposition => 'attachment',
                   filename => $object->{data}->{file_name} // '');
            }
            $app->http->set_response_header
                ('content-security-policy', 'sandbox');
            $app->http->set_response_header
                ('x-content-type-options', 'nosniff');
            $app->http->set_response_last_modified
                ($object->{data}->{timestamp} || 0);
            $app->http->send_response_body_as_ref (\($_[0]->body_bytes));
            $app->http->close_response_body;
          } elsif ($_[0]->status == 404) {
            return $app->throw_error (404, reason_phrase => 'No file content');
          } else {
            die $_[0];
          }
        });
      } elsif (@$path == 5 and $path->[4] eq 'upload.json') {
        # /g/{group_id}/o/{object_id}/upload.json
        $app->requires_request_method ({POST => 1});
        $app->requires_same_origin;

        my $token = $app->bare_param ('token') // '';
        unless (defined $object->{data}->{upload_token} and
                $object->{data}->{upload_token} eq $token) {
          return $app->throw_error (403, reason_phrase => 'Bad |token|');
        }

        my $aws4 = $app->config->{storage}->{aws4};
        my $bucket = $app->config->{storage}->{bucket};
        my $url = Web::URL->parse_string ($app->config->{storage}->{url});
        my $client = Web::Transport::ConnectionClient->new_from_url ($url);

        my $file = $path->[3];
        return $client->request (
          method => 'HEAD',
          path => [$bucket],
          aws4 => $aws4,
        )->then (sub {
          my $res = $_[0];
          if ($res->status == 404) {
            ## <Error><Code>NoSuchBucket</Code><Message>The specified bucket does not exist</Message><Key></Key><BucketName></BucketName><Resource>{path}</Resource><RequestId>...</RequestId><HostId>...</HostId></Error>
            return $client->request (
              method => 'PUT',
              path => [$bucket],
              aws4 => $aws4,
            )->then (sub {
              die $_[0] unless $_[0]->status == 200;
            });
          }
          die $_[0] unless $_[0]->status == 200;
        })->then (sub {
          return $client->request (
            method => 'PUT',
            path => [$bucket, $file],
            aws4 => $aws4,

            # XXX streaming request body reading
            body => ${$app->http->request_body_as_ref},
          );
        })->then (sub {
          die $_[0] unless $_[0]->status == 200;
          return json $app, {};
        });
      } elsif (@$path == 5 and $path->[4] eq 'revisions.json') {
        # /g/{group_id}/o/{object_id}/revisions.json
        my $page = Pager::this_page ($app, limit => 10, max_limit => 100);
        my $where = {
          group_id => Dongry::Type->serialize ('text', $opts->{group}->{group_id}),
          object_id => Dongry::Type->serialize ('text', $object->{object_id}),
        };
        $where->{created} = $page->{value} if defined $page->{value};
        my $with = $app->bare_param ('with_revision_data');
        return $db->select ('object_revision', $where, fields => [
          'object_revision_id',
          ($with ? ('revision_data') : ()),
          'author_account_id', 'created',
          'owner_status', 'user_status',
          # group_id object_id data
        ],
          offset => $page->{offset}, limit => $page->{limit},
          order => ['created', $page->{order_direction}],
        )->then (sub {
          my $items = [map {
            {
              object_revision_id => '' . $_->{object_revision_id},
              author_account_id => '' . $_->{author_account_id},
              created => $_->{created},
              ($with ? (revision_data => Dongry::Type->parse ('json', $_->{revision_data})) : ()),
              user_status => $_->{user_status},
              owner_status => $_->{owner_status},
            };
          } @{$_[0]->all->to_a}];
          my $next_page = Pager::next_page $page, $items, 'created';
          return json $app, {items => $items, %$next_page};
        });

      ## XXX if revision's *_status is changed, save log

      } else {
        return $app->throw_error (404);
      }
    });
  }

  if (@$path >= 4 and $path->[3] eq 'get.json') {
    # /g/{group_id}/o/get.json
    my $next_ref = {};
    my $rev_id;
    return Promise->resolve->then (sub {
      my $index_id;
      my $table;
      my %cond;
      my $ref = $app->bare_param ('ref');
      my $timestamp;
      my $offset;
      my $limit = $app->bare_param ('limit') || 20;
      if (defined $ref) {
        ($timestamp, $offset) = split /,/, $ref, 2;
        $next_ref->{$timestamp} = $offset || 0;
        return $app->throw_error (400, reason_phrase => 'Bad offset')
            if $offset > 1000;
        $cond{timestamp} = {'<=', $timestamp} if defined $timestamp;
      }
      return $app->throw_error (400, reason_phrase => 'Bad limit')
          if $limit > 100;
      my $thread_id = $app->bare_param ('thread_id');
      if (defined $thread_id) {
        return {thread_id => $thread_id,
                object_id => {'!=' => $thread_id},
                (defined $cond{timestamp} ? (timestamp => $cond{timestamp}) : ()),
                order => ['timestamp', 'desc', 'created', 'desc'],
                offset => $offset,
                limit => $limit};
      } else {
        my $parent_object_id = $app->bare_param ('parent_object_id');
        if (defined $parent_object_id) {
          return {parent_object_id => $parent_object_id,
                  object_id => {'!=' => $parent_object_id},
                  (defined $cond{timestamp} ? (timestamp => $cond{timestamp}) : ()),
                  order => ['timestamp', 'desc', 'created', 'desc'],
                  offset => $offset,
                  limit => $limit};
        } else {
          $index_id = $app->bare_param ('index_id');
          if (defined $index_id) {
            my $pwn = $app->text_param ('parent_wiki_name');
            if (defined $pwn) {
              $table = 'wiki_trackback_object';
              $cond{index_id} = $index_id;
              $cond{wiki_name_key} = sha1_hex +Dongry::Type->serialize ('text', $pwn);
            } else {
              $table = 'index_object';
              $cond{index_id} = $index_id;
              my $wiki_name = $app->text_param ('wiki_name');
              $cond{wiki_name_key} = sha1_hex +Dongry::Type->serialize ('text', $wiki_name)
                  if defined $wiki_name;
            }
          }
        }
      }
      if (defined $table) {
        return $db->select ($table, {
          group_id => Dongry::Type->serialize ('text', $path->[1]),
          %cond,
        },
          fields => ['object_id', 'timestamp'],
          order => ['timestamp', 'desc', 'created', 'desc'],
          offset => $offset, limit => $limit,
        )->then (sub {
          return {object_id => {-in => [map {
            $next_ref->{$_->{timestamp}}++;
            $next_ref->{_} = $_->{timestamp};
            $_->{object_id};
          } @{$_[0]->all}]}};
        });
      } else {
        my $list = $app->bare_param_list ('object_id');
        $rev_id = $app->bare_param ('object_revision_id') if @$list == 1;
        return {object_id => {-in => $list},
                all => 1};
      }
    })->then (sub {
      my $search = $_[0];
      my $order = delete $search->{order}; # or undef
      my $offset = delete $search->{offset}; # or undef
      my $limit = delete $search->{limit}; # or undef
      my $all = delete $search->{all};
      return [] unless keys %$search;
      return [] if defined $search->{object_id} and
                   defined $search->{object_id}->{-in} and
                   not @{$search->{object_id}->{-in}};
      unless ($all) {
        $search->{owner_status} = 1; # open
        $search->{user_status} = 1; # open
      }
      return $db->select ('object', {
        group_id => Dongry::Type->serialize ('text', $path->[1]),
        %$search,
      }, fields => ['object_id', 'title', 'timestamp', 'created', 'updated',
                    ($all ? ('user_status', 'owner_status') : ()),
                    ($app->bare_param ('with_data') ? 'data' : ()),
                    ($app->bare_param ('with_snippet') ? $db->bare_sql_fragment (q{ substring(`search_data`, 1, 600) as `snippet` }) : ())],
        order => $order, # or undef
        offset => $offset, # or undef
        limit => $limit, # or undef
      )->then (sub {
        my $objects = $_[0]->all;
        if (defined $rev_id and @$objects == 1) {
          return $db->select ('object_revision', {
            group_id => Dongry::Type->serialize ('text', $path->[1]),
            object_id => $objects->[0]->{object_id},
            object_revision_id => $rev_id,
          }, fields => ['data', 'revision_data', 'author_account_id',
                        'created', 'user_status', 'owner_status'])->then (sub {
            my $r = $_[0]->first;
            return $app->throw_error (404, reason_phrase => 'Revision not found')
                unless defined $r;
            $objects->[0]->{updated} = $r->{created};
            $objects->[0]->{revision_author_account_id} = ''.$r->{author_account_id};
            if ($r->{user_status} == 1 and $r->{owner_status} == 1) { # open
              $objects->[0]->{data} = $r->{data};
              $objects->[0]->{revision_data}
                  = Dongry::Type->parse ('json', $r->{revision_data});
            } else {
              delete $objects->[0]->{data};
              delete $objects->[0]->{title};
            }
            return $objects;
          });
        } else {
          if (defined $order) {
            for (@$objects) {
              $next_ref->{$_->{timestamp}}++;
              $next_ref->{_} = $_->{timestamp};
            }
          }
          return $objects;
        }
      });
    })->then (sub {
      my $objects = $_[0];
      return $db->select ('imported', {
        group_id => Dongry::Type->serialize ('text', $path->[1]),
      }, fields => ['source_site'], distinct => 1)->then (sub {
        my $sites = [map {
          Dongry::Type->serialize ('text', $_->{source_site})
        } @{$_[0]->all}];
        return json $app, {
          imported_sites => $sites,
          objects => {map {
            my $data;
            my $title;
            if (defined $_->{data}) {
              $data = Dongry::Type->parse ('json', $_->{data});
              $title = $data->{title} // '';
            } else {
              $title = Dongry::Type->parse ('text', $_->{title});
            }
            ($_->{object_id} => {
              group_id => $path->[1],
              object_id => ''.$_->{object_id},
              title => $title,
              created => $_->{created},
              updated => $_->{updated},
              timestamp => $_->{timestamp},
              (defined $_->{user_status} ? (user_status => $_->{user_status},
                                            owner_status => $_->{owner_status}) : ()),
              (defined $_->{data} ? (data => $data) : ()),
              (defined $_->{snippet} ? (snippet => Dongry::Type->parse ('text', $_->{snippet})) : ()),
              (defined $_->{revision_data} ?
                   (revision_data => $_->{revision_data},
                    revision_author_account_id => $_->{revision_author_account_id}) : ()),
            });
          } @$objects},
          next_ref => (defined $next_ref->{_} ? $next_ref->{_} . ',' . $next_ref->{$next_ref->{_}} : undef),
        };
      });
    });
  } elsif (@$path >= 4 and $path->[3] eq 'search.json') {
    # /g/{group_id}/o/search.json
    my $q = $app->text_param ('q');
    my @have;
    my @not_have;
    if (defined $q) {
      for (grep { length } split /\s+/, $q) {
        if (s/^-(?=.)//s) {
          push @not_have, $_;
        } else {
          push @have, $_;
        }
      }
    }

    my $ref = $app->bare_param ('ref');
    my $timestamp;
    my $offset;
    my $limit = $app->bare_param ('limit') || 50;
    if (defined $ref) {
      ($timestamp, $offset) = split /,/, $ref, 2;
      return $app->throw_error (400, reason_phrase => 'Bad offset')
          if $offset > 1000;
    }
    return $app->throw_error (400, reason_phrase => 'Bad limit')
        if $limit > 100;

    my ($sqlx0, $sql0) = where [q{
      select `object_id`, `updated`, `title`, `timestamp`,
        substring(`search_data`, greatest(locate(:s1, `search_data`) - 300, 0) + 1, 600)
        as `snippet`
    }, 
      s1 => Dongry::Type->serialize ('text', $have[0] // ''),
    ];
    my ($sqlx, $sql) = where [q{
      from `object`
      where @@SEARCHDATA@@ and
            group_id = :group_id and
            user_status = 1 and owner_status = 1 and
            :updated:optsub
      order by `updated` desc limit :offset,:limit
    }, 
      group_id => Dongry::Type->serialize ('text', $path->[1]),
      updated => (defined $timestamp ? {updated => {'<=', $timestamp}} : {}),
      offset => $offset || 0,
      limit => $limit,
    ];

    my @expr;
    my @value;
    for (@have) {
      my ($x, $y) = where {search_data => {-infix => $_}};
      push @expr, $x;
      push @value, map { Dongry::Type->serialize ('text', $_) } @$y;
    }
    for (@not_have) {
      my ($x, $y) = where {search_data => {-infix => $_}};
      push @expr, 'not (' . $x . ')';
      push @value, map { Dongry::Type->serialize ('text', $_) } @$y;
    }

    $sqlx =~ s{\@\@SEARCHDATA\@\@}{
      if (@expr) {
        '(' . (join ' and ', @expr) . ')';
      } else {
        '(1 = 1)';
      }
    }e;
    $sqlx = $sqlx0 . $sqlx;
    unshift @$sql, @$sql0, @value;

    return $db->execute ($sqlx, $sql)->then (sub {
      my $items = $_[0]->all;
      return json $app, {
        next_ref => (@$items ? $items->[-1]->{updated} . ',1' : $ref // (time . ',' . 0)),
        objects => [map {
          {
            object_id => ''.$_->{object_id},
            title => Dongry::Type->parse ('text', $_->{title}),
            snippet => Dongry::Type->parse ('text', $_->{snippet}),
            updated => $_->{updated},
            timestamp => $_->{timestamp},
          };
        } @$items],
      };
    });
  } # /g/{}/o/search.json

  if (@$path == 4 and $path->[3] eq 'create.json') {
    # /g/{group_id}/o/create.json
    $app->requires_request_method ({POST => 1});
    $app->requires_same_origin;

    my ($source_site_url, $source_page_url) = source_urls $app;

    return create_object ($db,
      group_id => $path->[1],
      author_account_id => $opts->{account}->{account_id},
      ($app->bare_param ('is_file') ? (
        body_type => 4, # file
      ) : ()),
      import => defined $source_page_url,
    )->then (sub {
      my $result = $_[0];
      return Promise->resolve->then (sub {
        return unless defined $source_page_url;
        my $site = Dongry::Type->serialize ('text', $source_site_url->stringify);
        my $page = Dongry::Type->serialize ('text', $source_page_url->stringify);
        my $page_sha = sha1_hex ($page);
        my $time = time;
        return $db->insert ('imported', [{
          group_id => Dongry::Type->serialize ('text', $path->[1]),
          source_page_sha => $page_sha,
          source_page => $page,
          source_site_sha => sha1_hex ($site),
          source_site => $site,
          created => $time,
          updated => $time,
          type => 2, # object
          dest_id => $result->{object_id},
          sync_info => Dongry::Type->serialize ('json', {}),
        }], duplicate => {
          source_site => $db->bare_sql_fragment ('values(`source_site`)'),
          source_site_sha => $db->bare_sql_fragment ('values(`source_site_sha`)'),
          updated => $db->bare_sql_fragment ('values(`updated`)'),
          type => $db->bare_sql_fragment ('values(`type`)'),
          dest_id => $db->bare_sql_fragment ('values(`dest_id`)'),
          sync_info => $db->bare_sql_fragment ('values(`sync_info`)'),
        })->then (sub {
          if ($page =~ m{^https://([^/]+\.g\.hatena\.ne\.jp/[^/]+/[^/]+)\z}) {
            my $page2 = "http://$1";
            return $db->execute ('select `source_id`, `timestamp`, `dest_url_sha` from `url_ref` where `group_id` = :group_id and (`dest_url` like :prefix1 or `dest_url` like :prefix2) limit 100', {
              group_id => Dongry::Type->serialize ('text', $path->[1]),
              prefix1 => Dongry::Type->serialize ('text', like ($page) . '%'),
              prefix2 => Dongry::Type->serialize ('text', like ($page2) . '%'),
            });
          } else {
            return $db->select ('url_ref', {
              group_id => Dongry::Type->serialize ('text', $path->[1]),
              dest_url_sha => $page_sha,
            }, fields => ['source_id', 'timestamp', 'dest_url_sha'], limit => 100);
          }
        })->then (sub {
          my $links = $_[0]->all;
          return unless @$links;
          return (promised_for {
            return _write_object_trackbacks (
              $db,
              $path->[1],
              [$result->{object_id}],
              $opts->{account}->{account_id},
              $_[0]->{source_id},
              $_[0]->{timestamp},
              $time,
            );
          } $links)->then (sub {
            return $db->delete ('url_ref', {
              group_id => Dongry::Type->serialize ('text', $path->[1]),
              dest_url_sha => {-in => [map { $_->{dest_url_sha} } @$links]},
              source_id => {-in => [map { $_->{source_id} } @$links]},
            });
          });
        });
      })->then (sub {
        return json $app, {
          group_id => $path->[1],
          object_id => $result->{object_id},
          object_revision_id => $result->{object_revision_id},
          upload_token => $result->{upload_token},
        };
      });
    });
  }

  return $app->throw_error (404);
} # group_object

sub invitation ($$$$) {
  my ($self, $app, $path, $acall) = @_;

  if (@$path == 4 and
      $path->[1] =~ /\A[1-9][0-9]*\z/ and
      length $path->[2] and
      $path->[3] eq '') {
    # /invitation/{group_id}/{invitation_key}/
    if ($app->http->request_method eq 'POST') {
      $app->requires_same_origin;
      return $acall->(['info'], {
        sk_context => $app->config->{accounts}->{context},
        sk => $app->http->request_cookies->{sk},

        context_key => $app->config->{accounts}->{context} . ':group',
        group_id => $path->[1],

        with_group_member_data => ['name'],
      })->(sub {
        my $account_data = $_[0];
        return $app->throw_error (403, reason_phrase => 'No user account')
            unless defined $account_data->{account_id};
        return $acall->(['invite', 'use'], {
          context_key => $app->config->{accounts}->{context} . ':group',
          invitation_context_key => 'group-' . $account_data->{group}->{group_id},
          invitation_key => $path->[2],

          account_id => $account_data->{account_id},
          data => (perl2json_chars {
            group_id => $account_data->{group}->{group_id},
            old_group_membership => $account_data->{group_membership},
          }),
        })->(sub {
          my $json = $_[0];
          my $data = $json->{invitation_data};
          my $new_type = $data->{member_type} || 0;
          my $old_type = $account_data->{group_membership}->{member_type} || 0;
          $new_type = $old_type if $old_type > $new_type;
          # 1:normal, 2:owner
          return $acall->(['group', 'member', 'status'], {
            context_key => $app->config->{accounts}->{context} . ':group',
            group_id => $account_data->{group}->{group_id},
            account_id => $account_data->{account_id},
            member_type => $new_type,
            user_status => 1, # open
            owner_status => $account_data->{group_membership}->{owner_status} || 1, # open
          })->(sub {
            return $acall->(['group', 'member', 'data'], {
              context_key => $app->config->{accounts}->{context} . ':group',
              group_id => $account_data->{group}->{group_id},
              account_id => $account_data->{account_id},
              name => 'name',
              value => $account_data->{name},
            })->() unless defined $account_data->{group_membership}->{data}->{name};
          })->then (sub {
            return $app->send_redirect ("/g/$account_data->{group}->{group_id}/");
          });
        }, sub {
          my $reason = $_[0]->{reason};
          if ($reason eq 'Bad invitation') {
            return $app->send_redirect ("/g/$path->[1]/");
          } else {
            return $app->throw_error (400, reason_phrase => $reason);
          }
        });
      });
    } else { # GET
      return $acall->(['invite', 'open'], {
        context_key => $app->config->{accounts}->{context} . ':group',
        invitation_context_key => 'group-' . $path->[1],
        invitation_key => $path->[2],
        account_id => 0, # anyone
      })->(sub {
        my $json = $_[0];
        if ($json->{used}) {
          return $app->send_redirect ("/g/$path->[1]/");
        }

        return $acall->(['group', 'profiles'], {
          context_key => $app->config->{accounts}->{context} . ':group',
          group_id => $path->[1],
          with_data => ['title'],
        })->(sub {
          my $json = $_[0];
          return temma $app, 'invitation.id.key.html.tm', {
            group_title => $json->{groups}->{$path->[1]}->{data}->{title},
          };
        });
      }, sub {
        my $json = $_[0];
        if ($json->{reason} eq 'Bad invitation') {
          return $app->send_redirect ("/g/$path->[1]/");
        } else {
          return $app->throw_error (400, reason_phrase => $json->{reason});
        }
      });
    }
  } # /invitation/{group_id}/{invitation_key}/

  return $app->throw_error (404);
} # invitation

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

You does not have received a copy of the GNU Affero General Public
License along with this program, see <https://www.gnu.org/licenses/>.

=cut
