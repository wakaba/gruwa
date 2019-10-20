create table if not exists `index` (
  group_id bigint unsigned not null,
  index_id bigint unsigned not null,
  title varbinary(1023) not null,
  created double not null,
  updated double not null,
  primary key (index_id),
  key (group_id, updated),
  key (created),
  key (updated)
) default charset=binary engine=innodb;

create table if not exists `object` (
  group_id bigint unsigned not null,
  object_id bigint unsigned not null,
  title varbinary(1023) not null,
  data mediumblob not null,
  created double not null,
  updated double not null,
  primary key (object_id),
  key (group_id, updated),
  key (created),
  key (updated)
) default charset=binary engine=innodb;

create table if not exists `index_object` (
  group_id bigint unsigned not null,
  index_id bigint unsigned not null,
  object_id bigint unsigned not null,
  created double not null,
  primary key (index_id, object_id),
  key (group_id, created),
  key (index_id),
  key (object_id),
  key (created)
) default charset=binary engine=innodb;alter table `index`
  add column owner_status tinyint unsigned not null,
  add column user_status tinyint unsigned not null;

alter table `object`
  add column owner_status tinyint unsigned not null,
  add column user_status tinyint unsigned not null;
alter table `index`
  add column `options` mediumblob not null;
alter table `object`
  add column `timestamp` double not null,
  add key (`group_id`, `timestamp`);
alter table `index_object`
  add column `timestamp` double not null,
  add key (`index_id`, `timestamp`),
  drop key `index_id`,
  add key (`group_id`, `timestamp`);
create table `object_revision` (
  group_id bigint unsigned not null,
  object_id bigint unsigned not null,
  `data` mediumblob not null,

  object_revision_id bigint unsigned not null,
  `revision_data` mediumblob not null,
  author_account_id bigint unsigned not null,
  created double not null,

  -- statuses of the revision
  user_status tinyint unsigned not null,
  owner_status tinyint unsigned not null,

  primary key (`object_revision_id`),
  key (`group_id`, `object_id`, `created`),
  key (`created`),
  key (`group_id`, `created`),
  key (`author_account_id`, `created`)
) default charset=binary engine=innodb;
alter table `object`
  add column `search_data` mediumblob not null;
alter table `index`
  add column `index_type` tinyint unsigned not null;
alter table `index_object`
  add column `wiki_name_key` binary(40) NOT NULL,
  add key (`group_id`, `wiki_name_key`, `timestamp`);
alter table `object`
  add column `thread_id` bigint unsigned not null,
  add key (`group_id`, `thread_id`, `created`);
alter table `object`
  add column `parent_object_id` bigint unsigned not null,
  add key (`group_id`, `parent_object_id`, `created`);
create table if not exists `jump` (
  `key` binary(40) not null,
  `account_id` bigint unsigned not null,
  `url` varbinary(1023) not null,
  `label` varbinary(1023) not null,
  `score` int unsigned not null,
  primary key (`key`),
  key (`account_id`, `score`)
) default charset=binary engine=innodb;alter table `jump` add column `timestamp` double not null;create table if not exists `wiki_trackback_object` (
  `group_id` bigint(20) unsigned NOT NULL,
  `index_id` bigint(20) unsigned NOT NULL,
  `wiki_name_key` binary(40) NOT NULL,
  `object_id` bigint(20) unsigned NOT NULL,
  `created` double NOT NULL,
  `timestamp` double NOT NULL,
  primary key (`index_id`, `wiki_name_key`, `object_id`),
  key (`group_id`, `created`),
  key (`group_id`, `timestamp`),
  key (`group_id`, `wiki_name_key`),
  key (`object_id`),
  key (`created`)
) default charset=binary engine=innodb;create table if not exists `imported` (
  `group_id` bigint unsigned not null,
  `source_page_sha` binary(40) not null,
  `source_page` varbinary(2047) not null,
  `source_site_sha` binary(40) not null,
  `source_site` varbinary(2047) not null,
  `created` double not null,
  `updated` double not null,
  `type` tinyint unsigned not null,
    -- 1 index
    -- 2 object
    -- 3 object fragment
  `dest_id` bigint unsigned not null,
  `sync_info` mediumblob not null,
  primary key (`group_id`, `source_page_sha`),
  key (`group_id`, `source_page`),
  key (`group_id`, `source_site_sha`, `created`),
  key (`group_id`, `dest_id`),
  key (`created`),
  key (`updated`)
) default charset=binary engine=innodb;
create table if not exists `url_ref` (
  `group_id` bigint unsigned not null,
  `source_id` bigint unsigned not null,
  `dest_url` varbinary(2047) NOT NULL,
  `dest_url_sha` binary(40) NOT NULL,
  `created` double not null,
  `timestamp` double not null,
  primary key (`group_id`, `source_id`, `dest_url_sha`),
  key (`group_id`, `dest_url_sha`),
  key (`created`), 
  key (`timestamp`)
) default charset=binary engine=innodb;
create table if not exists `object_call` (
  `group_id` bigint unsigned not null,
  `thread_id` bigint unsigned not null,
  `object_id` bigint unsigned not null,
  `from_account_id` bigint unsigned not null,
  `to_account_id` bigint unsigned not null,
  `timestamp` double not null,
  `read` tinyint unsigned not null,
  primary key (`group_id`, `to_account_id`, `object_id`),
  key (`group_id`, `thread_id`),
  key (`group_id`, `object_id`),
  key (`timestamp`)
) default charset=binary engine=innodb;

alter table `object_call`
  add column `reason` tinyint unsigned not null;
create table if not exists `account_report_request` (
  `group_id` bigint unsigned not null,
  `account_id` bigint unsigned not null,
  `report_type` tinyint unsigned not null,
  `prev_report_timestamp` double not null,
  `touch_timestamp` double not null,
  `processing` double not null,
  primary key (`group_id`, `account_id`, `report_type`),
  key (`account_id`, `touch_timestamp`),
  key (`prev_report_timestamp`)
) default charset=binary engine=innodb;
