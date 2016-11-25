<html t:params="$group $account $group_member">

<header class=group>
  <header-area>
    <hgroup>
      <h1><a href=/>Gruwa</a></h1>
      <h2><a pl:href="'/g/'.$group->{group_id}.'/'" rel=top><t:text value="$group->{title}"></a></h2>
    </hgroup>
  </header-area>
  <header-area>
    <account-name><t:text value="$account->{name}"></account-name>
    <a href=/dashboard>ダッシュボード</>
    <t:if x="$group_member->{default_index_id}">
      <a pl:href="'/g/'.$group->{group_id}.'/i/'.$group_member->{default_index_id}.'/'">日記</a>
    </t:if>
  </header-area>
</header>

<!--

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You does not have received a copy of the GNU Affero General Public
License along with this program, see <http://www.gnu.org/licenses/>.

-->
