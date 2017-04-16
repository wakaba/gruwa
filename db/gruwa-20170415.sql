create table if not exists `imported` (
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
