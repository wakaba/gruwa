alter table `index_object`
  add column `wiki_name_key` binary(40) NOT NULL,
  add key (`group_id`, `wiki_name_key`, `timestamp`);
