alter table `group`
  add column owner_status tinyint unsigned not null,
  add column admin_status tinyint unsigned not null;

alter table `index`
  add column owner_status tinyint unsigned not null,
  add column user_status tinyint unsigned not null;

alter table `object`
  add column owner_status tinyint unsigned not null,
  add column user_status tinyint unsigned not null;

alter table `group_member`
  add column default_index_id bigint unsigned not null;
