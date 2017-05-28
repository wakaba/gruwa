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
