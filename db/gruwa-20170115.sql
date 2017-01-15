create table if not exists `object_reaction` (
  `group_id` bigint unsigned not null,
  `object_id` bigint unsigned not null,
  `reaction_type` tinyint unsigned not null,
  `data_object_id` bigint unsigned not null default 0,
  `data` mediumblob not null,
  `created` double not null,
  `timestamp` double not null,
  key (`group_id`, `object_id`, `data_object_id`),
  key (`group_id`, `data_object_id`),
  key (`created`)
) default charset=binary engine=innodb;
