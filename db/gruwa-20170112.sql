alter table `object`
  add column `thread_id` bigint unsigned not null,
  add key (`group_id`, `thread_id`, `created`);
