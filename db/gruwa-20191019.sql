create table if not exists `account_report_request` (
  `account_id` bigint unsigned not null,
  `report_type` tinyint unsigned not null,
  `prev_report_timestamp` double not null,
  `touch_timestamp` double not null,
  `processing` double not null,
  primary key (`account_id`, `report_type`),
  key (`account_id`, `touch_timestamp`),
  key (`prev_report_timestamp`)
) default charset=binary engine=innodb;
