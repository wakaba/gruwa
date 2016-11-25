<html t:params="$group $account $group_member $app" pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-theme="$group->{options}->{theme}">
<head>
  <t:include path=_group_head.html.tm m:group=$group m:account=$account m:app=$app>
    トップ
  </t:include>

<body>
  <t:include path=_group_header.html.tm m:group=$group m:account=$account m:group_member=$group_member m:app=$app />

  <section class=page>
    <header>
      <h1><a href=./><t:text value="$group->{title}"></a></h1>
      <nav>
        <a href=./ class=active>トップ</a>
        / <a href=members>メンバー</a>
        / <a href=config>設定</a>
      </nav>
    </header>

    <list-container src=i/list.json key=index_list sortkey=updated>
      <template>
        <p>
          <a href data-href-template="i/{index_id}/#{updated}">
            <time data-field=updated />
            <strong data-field=title></strong>
          </a>
          <list-container data-src-template="o/get.json?index_id={index_id}" key=objects max=5>
            <template>
              <a href data-href-template="o/{object_id}">
                <strong data-field=title data-empty=■ />
                (<time data-field=updated class=ambtime />)
              </a>
            </template>
            <list-main/>
          </list-container>
      </template>
      <list-main/>
    </list-container>
  </section>

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
