create table if not exists `index` (
  group_id bigint unsigned not null,
  index_id bigint unsigned not null,
  title varbinary(1023) not null,
  created double not null,
  updated double not null,
  primary key (index_id),
  key (group_id, updated),
  key (created),
  key (updated)
) default charset=binary engine=innodb;

create table if not exists `object` (
  group_id bigint unsigned not null,
  object_id bigint unsigned not null,
  title varbinary(1023) not null,
  data mediumblob not null,
  created double not null,
  updated double not null,
  primary key (object_id),
  key (group_id, updated),
  key (created),
  key (updated)
) default charset=binary engine=innodb;

create table if not exists `index_object` (
  group_id bigint unsigned not null,
  index_id bigint unsigned not null,
  object_id bigint unsigned not null,
  created double not null,
  primary key (index_id, object_id),
  key (group_id, created),
  key (index_id),
  key (object_id),
  key (created)
) default charset=binary engine=innodb;