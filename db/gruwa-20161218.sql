create table if not exists `tag_object` (
  group_id bigint unsigned not null,
  tag_key binary(40) not null,
  object_id bigint unsigned not null,
  timestamp double not null,
  primary key (tag_key, object_id),
  key (group_id, tag_key, object_id),
  key (group_id, object_id),
  key (timestamp)
) default charset=binary engine=innodb;
