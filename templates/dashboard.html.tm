<html t:params="$account $app"
    data-theme=green>
<head>
  <title>Gruwa</title>
  <meta name=referrer content=no-referrer>
  <meta name=robots content="NOINDEX,NOFOLLOW,NOARCHIVE">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name=theme-color content="green">
  <link rel=stylesheet pl:href="'/css/common.css?r='.$app->rev">
  <script pl:src="'/js/components.js?r='.$app->rev" class=body-js async data-export="$fill $promised $getTemplateSet" data-time-selector="time:not(.asis)" />
  <script pl:src="'/js/framework.js?r='.$app->rev" class=body-js />
  <script pl:src="'/js/pages.js?r='.$app->rev" async />

<body>
  <header class=page>
    <a href=/ rel=top>Gruwa</a>
    <h1><a href=/dashboard>ダッシュボード</a></h1>
    <gr-menu type=dashboard />
  </header>
  <page-main/>

  <gr-navigate-status>
    <action-status stage-loading=読込中... />
  </gr-navigate-status>

  <gr-navigate partition=dashboard />

<!-- also in _common.html.tm -->
<template-set name=gr-menu>
  <template>
    <popup-menu>
      <button type=button title=メニュー>
        <button-label>
          メニュー
        </button-label>
      </button>
      <menu-main/>
    </popup-menu>
  </template>
</template-set>

<template-set name=gr-menu-dashboard>
  <template>
    <p><a data-href-template=/dashboard>トップ</a>
    <p><a data-href-template=/jump>ジャンプリスト</a>
    <p><a href=/help#dashboard target=help>ヘルプ</a>
  </template>
</template-set>

<template-set name=page-dashboard>
  <template title=ダッシュボード>

  <section>
    <h1>参加グループ</>

    <gr-list-container type=table src=my/groups.json key=groups sortkey=updated class=main-table>
      <template>
        <th>
          <a href data-href-template="/g/{group_id}/">
            <img data-src-template=/g/{group_id}/icon alt class=icon>
            <span data-field=title data-empty=(未参加グループ) />
          </a>
        <td class=member_type>
          <gr-enum-value data-field=member_type text-1=一般 text-2=所有者 text-0=未参加 />
        <td class=user_status>
          <gr-enum-value data-field=user_status text-1=参加中 text-2=招待中 />
        <td class=owner_status>
          <gr-enum-value data-field=owner_status text-1=承認済 text-2=未承認 />
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
      <gr-action-status hidden stage-load=読み込み中... />
    </gr-list-container>

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
          <gr-action-status hidden
              stage-fetch=グループを作成中...
              stage-creategroupwiki_1=グループのWikiを作成中...
              stage-creategroupwiki_2=グループの設定中...
              stage-next=グループに移動します... />
      </form>
    </details>

  </section>

  </template>
</template-set>

<template-set name=page-jump>
  <template title=ジャンプリスト>
    <section>
      <header class=section>
        <h1>ジャンプリスト</>
        <a href=/help#jump target=help>ヘルプ</a>
      </header>

    <gr-list-container type=table src=/jump/list.json key=items class=main-table>
      <template>
        <th>
          <a href data-href-template={URL} data-field=label />
        <td class=operations>
          <button type=button class=edit-button data-command=editJumpLabel data-prompt=ラベルを指定してください>編集</button>
          <button type=button class=edit-button data-command=deleteJump>削除</button>
          <gr-action-status hidden stage-fetch=... />
      </template>

      <table>
        <thead>
          <tr>
            <th>ページ
            <th>編集
        <tbody>
      </table>
      <gr-action-status hidden stage-load=読み込み中... />
    </gr-list-container>

      <p>新しいジャンプメニューを追加するには、追加したい項目のメニューから
      「ジャンプリストに追加」を選んでください。
    </section>
  </template>
</template-set>

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
