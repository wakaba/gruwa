create table if not exists `jump` (
  `key` binary(40) not null,
  `account_id` bigint unsigned not null,
  `url` varbinary(1023) not null,
  `label` varbinary(1023) not null,
  `score` int unsigned not null,
  primary key (`key`),
  key (`account_id`, `score`)
) default charset=binary engine=innodb;