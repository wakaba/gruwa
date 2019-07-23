<html t:params="$group $account $app $group_member"
    pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-theme="$group->{data}->{theme}">
<head>
  <t:include path=_group_head.html.tm m:group=$group m:account=$account m:app=$app>
    検索
  </t:include>

<body>

  <section class=page>
    <header>
      <h1><a href=./><t:text value="$group->{data}->{title}"></a></h1>
      <m:group-menu m:group=$group />
    </header>

    <section>
      <header class=section>
        <h1>検索</>
        <gr-popup-menu>
          <button type=button>⋁</>
          <menu hidden>
            <li><copy-button>
              <a href>URLをコピー</a>
            </copy-button>
            <li><copy-button type=jump>
              <a href>ジャンプリストに追加</a>
            </copy-button>
            <li><a href=/help#search>ヘルプ</a>
          </menu>
        </gr-popup-menu>
      </header>

      <gr-list-container src=o/search.json key=objects pl:param-q="$app->text_param ('q')" class=object-search>
        <form method=get action=search class=search-form data-pjax=search?q={q}>
          <input type=search name=q pl:value="$app->text_param ('q')">
          <button type=submit>検索</button>
        </form>

        <p hidden class=search-wiki_name-link><strong>Wiki</strong>:
        <a href data-href-template=wiki/{name} data-field=name></a></p>

        <p><strong>記事</strong>:</p>

        <template>
          <a href data-href-template=o/{object_id}/>
            <time data-field=timestamp class=date />
            <strong data-field=title data-empty=■></strong>
            <time data-field=updated />
            <search-snippet data-field=snippet />
          </a>
        </template>
        <list-main/>
        <list-is-empty hidden>
          <p>一致する記事は見つかりませんでした。
        </list-is-empty>
        <gr-action-status hidden stage-load=読み込み中... />
        <p class=operations>
          <button type=button class=next-page-button hidden>もっと昔</button>
      </gr-list-container>

    </section>
  </section>
  <t:include path=_common.html.tm m:app=$app m:account=$account m:group=$group m:group_member=$group_member />

<!--

Copyright 2016-2019 Wakaba <wakaba@suikawiki.org>.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You does not have received a copy of the GNU Affero General Public
License along with this program, see <https://www.gnu.org/licenses/>.

-->
