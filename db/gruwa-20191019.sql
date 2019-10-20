create table if not exists `account_report_request` (
  `group_id` bigint unsigned not null,
  `account_id` bigint unsigned not null,
  `prev_report_timestamp` double not null,
  `next_report_after` double not null,
  `touch_timestamp` double not null,
  `processing` double not null,
  primary key (`group_id`, `account_id`),
  key (`account_id`, `next_report_after`),
  key (`next_report_after`),
  key (`prev_report_timestamp`)
) default charset=binary engine=innodb;
