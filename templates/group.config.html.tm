<html t:params="$group $app" pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-theme="$group->{data}->{theme}"
    data-navigate=config>
<head>
  <t:include path=_group_head.html.tm m:group=$group m:app=$app>
    設定
  </t:include>

<body>
  <section class=page>
    <header>
      <h1><a href=./><t:text value="$group->{data}->{title}"></a></h1>
      <gr-menu type=group />
    </header>
    <page-main/>
  </section>

<template-set name=page-config gr-group>
  <template>
    <section>
      <header class=section>
        <h1>グループ設定</>
        <a href=/help#config target=help>ヘルプ</a>
      </header>

      <form is=save-data data-saver=groupSaver method=post action=edit.json id=edit-form>
        <!-- XXX data-next=update group info -->
        <table class=config>
          <tbody>
            <tr>
              <th><label for=edit-title>名前</>
              <td><input name=title data-field=group.title id=edit-title required>
            <tr>
              <th><label for=edit-theme>配色</>
              <td>
                <gr-select-theme name=theme data-field=group.theme>
                  <select id=edit-theme form required />
                  <gr-theme-info>
                    <strong data-field=label />
                    <code data-field=name />
                    <span data-field=author />
                    <small>
                      <span data-field=license />
                      <span data-field=copyright />
                      (<a data-href-template={url} target=_blank rel="noreferrer noopener">出典</a>)
                    </small>
                  </gr-theme-info>
                </gr-select-theme>
        </table>
        <p class=operations>
          <button type=submit class=save-button data-enable-by-fill>保存する</>
          <action-status hidden stage-saver=保存中... ok=保存しました。 />
      </form>
    </section>

    <section id=create>
      <header class=section>
        <h1>作成</h1>
        <a href=/help#group-config-create target=help>ヘルプ</a>
      </header>

      <tab-set>
        <tab-menu/>

        <section id=create-blog>
          <h1>日記</h1>

          <section-intro>
            <p>新しい日記 <small>(日記記事ではなく<strong>日記帳</>)</small>
            を作成します。 (この操作は取り消せません。)
          </section-intro>

          <form is=save-data data-saver=groupSaver method=post action=i/create.json
              data-next=go:/g/{group_id}/i/{index_id}/config>
            <table class=config>
              <tbody>
                <tr>
                  <th><label for=create-blog-title>名前</>
                  <td><input name=title id=create-blog-title required placeholder=題名>
            </table>

            <p class=operations>
              <gr-input-hidden-random-theme name=theme />
              <input type=hidden name=index_type value=1>
              <button type=submit class=save-button>作成する</>
              <action-status hidden stage-saver=作成中... />
          </form>
        </section>

        <section id=create-wiki>
          <h1>Wiki</h1>

          <section-intro>
            <p>新しい Wiki <small>(記事ではなく<strong>Wiki</>)</small>
            を作成します。 (この操作は取り消せません。)
          </section-intro>

          <form is=save-data data-saver=groupSaver method=post action=i/create.json
              data-next=go:/g/{group_id}/i/{index_id}/config>
            <table class=config>
              <tbody>
                <tr>
                  <th><label for=create-wiki-title>名前</>
                  <td><input name=title id=create-wiki-title required value=Wiki>
            </table>

            <p class=operations>
              <gr-input-hidden-random-theme name=theme />
              <input type=hidden name=index_type value=2>
              <button type=submit class=save-button>作成する</>
              <action-status hidden stage-saver=作成中... />
          </form>
        </section>

        <section id=create-todo-list>
          <h1>TODO リスト</h1>

          <section-intro>
            <p>新しい TODO リスト <small>(TODO
            ではなく<strong>リスト</>)</small>
            を作成します。 (この操作は取り消せません。)
          </section-intro>

          <form is=save-data data-saver=groupSaver method=post action=action=i/create.json
              data-next=go:/g/{group_id}/i/{index_id}/config>
            <table class=config>
              <tbody>
                <tr>
                  <th><label for=create-todo-list-title>名前</>
                  <td><input name=title id=create-todo-list-title required value=TODOリスト>
            </table>

            <p class=operations>
              <gr-input-hidden-random-theme name=theme />
              <input type=hidden name=index_type value=3>
              <button type=submit class=save-button>作成する</>
              <action-status hidden stage-saver=作成中... />
          </form>

          <section-intro>
            <p>ラベル、マイルストーンはグループ全体で共通です。
          </section-intro>

          <details>
            <summary>ラベルの作成</summary>

            <form is=save-data data-saver=groupSaver method=post action=i/create.json
                data-next=go:/g/{group_id}/i/{index_id}/config>
              <table class=config>
                <tbody>
                  <tr>
                    <th><label for=create-label-title>名前</>
                    <td><input name=title id=create-label-title required placeholder=ラベル>
              </table>

              <p class=operations>
                <input type=hidden name=index_type value=4>
                <button type=submit class=save-button>作成する</>
                <action-status hidden stage-saver=作成中... />
            </form>
          </details>

          <details>
            <summary>マイルストーンの作成</summary>

            <form is=save-data data-saver=groupSaver method=post action=i/create.json
                data-next=go:/g/{group_id}/i/{index_id}/config>
              <table class=config>
                <tbody>
                  <tr>
                    <th><label for=create-milestone-title>名前</>
                    <td><input name=title id=create-milestone-title required placeholder=マイルストーン名>
              </table>

              <p class=operations>
                <input type=hidden name=index_type value=5>
                <button type=submit class=save-button>作成する</>
                <action-status hidden stage-saver=作成中... />
            </form>
          </details>
        </section>

        <section id=create-fileset>
          <h1>アップローダー</h1>

          <section-intro>
            <p>新しいアップローダーを作成します。 (この操作は取り消せません。)
          </section-intro>

          <form is=save-data data-saver=groupSaver method=post action=i/create.json
              data-next=go:/g/{group_id}/i/{index_id}/config>
            <table class=config>
              <tbody>
                <tr>
                  <th><label for=create-fileset-title>名前</>
                  <td><input name=title id=create-fileset-title required placeholder=フォルダー名>
                <tr>
                  <th>種別
                  <td>
                    <label><input type=radio name=subtype value=file checked required> ファイルアップローダー</label>
                    <label><input type=radio name=subtype value=image required> アルバム</label>
            </table>

            <p class=operations>
              <input type=hidden name=index_type value=6>
              <button type=submit class=save-button>作成する</>
              <action-status hidden stage-saver=作成中... />
          </form>
        </section>
      </tab-set>
    </section>

    <section>
      <h1>データのインポート</h1>

      <p>他のサービスからこのグループに<a href=import>データをインポート</a>できます。
    </section>
  </template>
</template-set>
  <t:include path=_common.html.tm m:app=$app />

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
