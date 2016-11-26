alter table `object`
  add column `timestamp` double not null,
  add key (`group_id`, `timestamp`);
alter table `index_object`
  add column `timestamp` double not null,
  add key (`index_id`, `timestamp`),
  drop key `index_id`,
  add key (`group_id`, `timestamp`);
