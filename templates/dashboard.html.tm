<html t:params="$account $app">
<title>ダッシュボード - Gruwa</title>
<t:if x="not $app->config->{is_production}">
  <meta name=referrer content=no-referrer>
<t:else>
  <meta name=referrer content=origin>
</t:if>
<meta name="viewport" content="width=device-width,initial-scale=1">
<link rel=stylesheet href=/css/common.css>
<script src=/js/framework.js class=body-js />
<script src=/js/pages.js async />

<header class=common>
  <header-area>
    <hgroup>
      <h1><a href=/ rel=top>Gruwa</h1>
    </>
  </header-area>
  <header-area>
    <popup-menu>
      <button><account-name><t:text value="$account->{name}"></account-name></button>
      <menu hidden>
        <li><a href=/dashboard>ダッシュボード</></li>
        <hr>
        <list-container src=/jump/list.json key=items type=list>
          <template>
            <a href data-href-template={URL} data-ping-template=/jump/ping.json?url={HREF} data-field=label></a>
          </template>
          <list-main/>
        </list-container>
        <li><a href=/jump>ジャンプリストの編集</></li>
      </menu>
    </popup-menu>
    <a href=/help>ヘルプ</a>
  </header-area>
</header>

  <section>
    <h1>参加グループ</>

    <list-container type=table src=my/groups.json key=groups sortkey=updated class=main-table>
      <template>
        <th>
          <a href data-href-template="/g/{group_id}/">
            <span data-field=title data-empty=(未参加グループ) />
          </a>
        <td class=member_type>
          <enum-value data-field=member_type text-1=一般 text-2=所有者 text-0=未参加 />
        <td class=user_status>
          <enum-value data-field=user_status text-1=参加中 text-2=招待中 />
        <td class=owner_status>
          <enum-value data-field=owner_status text-1=承認済 text-2=未承認 />
        <td>
          <a href data-href-template="g/{group_id}/i/{default_index_id}/" data-if-field=default_index_id>日記</a>
      </template>

      <table>
        <thead>
          <tr>
            <th>グループ
            <th>種別
            <th>参加状態
            <th>参加承認
            <th>
        <tbody>
      </table>
      <action-status hidden stage-load=読み込み中... />
    </list-container>

    <details>
      <summary>グループの作成</summary>

      <form method=post action=javascript: data-action=g/create.json
          data-next="createGroupWiki go:/g/{group_id}/config"
          data-prompt="グループを作成します。この操作は取り消せません。よろしいですか。">
        <table class=config>
          <tbody>
            <tr>
              <th><label for=create-title>グループ名</>
              <td><input name=title id=create-title required>
        </table>

        <p class=operations>
          <button type=submit class=save-button>作成する</>
          <action-status hidden
              stage-fetch=グループを作成中...
              stage-creategroupwiki_1=グループのWikiを作成中...
              stage-creategroupwiki_2=グループの設定中...
              stage-next=グループに移動します... />
      </form>
    </details>

    <ul>
      <li><a href=jump>ジャンプリスト</a>
    </ul>
  </section>

<!--

Copyright 2016-2017 Wakaba <wakaba@suikawiki.org>.

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
