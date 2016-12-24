alter table `index_object`
  add column `tag_key` binary(40) NOT NULL,
  add key (`group_id`, `tag_key`, `timestamp`);

alter table `index`
  add column `index_type` tinyint unsigned not null;
