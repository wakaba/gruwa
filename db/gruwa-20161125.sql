alter table `index`
  add column owner_status tinyint unsigned not null,
  add column user_status tinyint unsigned not null;

alter table `object`
  add column owner_status tinyint unsigned not null,
  add column user_status tinyint unsigned not null;
