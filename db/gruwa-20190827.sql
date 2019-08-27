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
