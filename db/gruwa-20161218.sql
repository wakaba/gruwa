create table if not exists `tag_object` (
  group_id bigint unsigned not null,
  tag_key binary(40) not null,
  object_id bigint unsigned not null,
  created double not null,
  timestamp double not null,
  primary key (tag_key, object_id),
  key (group_id, tag_key, timestamp),
  key (group_id, object_id),
  key (created),
  key (group_id, timestamp)
) default charset=binary engine=innodb;
