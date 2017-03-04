create table if not exists `wiki_trackback_object` (
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
) default charset=binary engine=innodb;