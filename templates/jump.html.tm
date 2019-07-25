<html t:params="$account $app">
  <head>
    <t:include path=_other_head.html.tm m:app=$app>
      ジャンプリスト
    </t:include>
  <body>

<header class=common>
  <header-area>
    <hgroup>
      <h1><a href=/ rel=top>Gruwa</h1>
    </>
  </header-area>
  <header-area>
    <a href=/dashboard>ダッシュボード</a>
    <a href=/jump>ジャンプリスト</a>
  </header-area>
</header>

  <section>
    <header class=section>
      <h1>ジャンプリスト</>
      <gr-popup-menu>
        <button type=button>⋁</>
        <menu hidden>
          <li><a href=/help#jump>ヘルプ</a>
        </menu>
      </gr-popup-menu>
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

    <p>新しいジャンプメニューを追加するには、追加したい項目のメニュー (⋁)
    から「ジャンプリストに追加」を選んでください。
  </section>

<!--

Copyright 2017-2019 Wakaba <wakaba@suikawiki.org>.

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
