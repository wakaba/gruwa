alter table `object`
  add column `parent_object_id` bigint unsigned not null,
  add key (`group_id`, `parent_object_id`, `created`);
