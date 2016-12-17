<html t:params="$group $account $app $group_member"
    pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-theme="$group->{options}->{theme}">
<head>
  <t:include path=_group_head.html.tm m:group=$group m:account=$account m:app=$app>
    検索
  </t:include>

<body>
  <t:include path=_group_header.html.tm m:group=$group m:account=$account m:group_member=$group_member m:app=$app />

  <section class=page>
    <header>
      <h1><a href=./><t:text value="$group->{title}"></a></h1>
      <nav>
        <a href=./>トップ</a>
        / <a href=members class=active>メンバー</a>
        / <a href=config>設定</a>
      </nav>
    </header>

    <section>
      <h1>検索</>

      <list-container src=o/search.json key=objects pl:param-q="$app->text_param ('q')">
        <form method=get action=search class=search-form data-pjax=search?q={q}>
          <input type=search name=q pl:value="$app->text_param ('q')" autofocus>
          <button type=submit>検索</button>
        </form>

        <template>
          <a href XXX>
            <time data-field=timestamp />
            <strong data-field=title data-empty=■></strong>
            <time data-field=updated />
          </a>
        </template>
        <list-main/>
        <list-is-empty hidden>
          <p>一致する記事は見つかりませんでした。
        </list-is-empty>
        <action-status hidden stage-load=読み込み中... />
        <p class=operations>
          <button type=button class=next-page-button hidden>もっと昔</button>
      </list-container>

    </section>
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
