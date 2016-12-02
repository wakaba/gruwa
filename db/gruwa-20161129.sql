create table `object_revision` (
  group_id bigint unsigned not null,
  object_id bigint unsigned not null,
  `data` mediumblob not null,

  object_revision_id bigint unsigned not null,
  `revision_data` mediumblob not null,
  author_account_id bigint unsigned not null,
  created double not null,

  -- statuses of the revision
  user_status tinyint unsigned not null,
  owner_status tinyint unsigned not null,

  primary key (`object_revision_id`),
  key (`group_id`, `object_id`, `created`),
  key (`created`),
  key (`group_id`, `created`),
  key (`author_account_id`, `created`)
) default charset=binary engine=innodb;
