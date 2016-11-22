create table if not exists `group_member` (
  `group_id` bigint unsigned not null,
  `account_id` bigint unsigned not null,
  `member_type` tinyint unsigned not null,
  `user_status` tinyint unsigned not null,
  `owner_status` tinyint unsigned not null,
  `desc` varbinary(1023) not null,
  `created` double not null,
  `updated` double not null,
  primary key (group_id, account_id),
  key (account_id),
  key (created),
  key (updated)
) default charset=binary engine=innodb;