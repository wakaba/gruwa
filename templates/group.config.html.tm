<html t:params="$group $app" pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-theme="$group->{data}->{theme}">
<head>
  <t:include path=_group_head.html.tm m:group=$group m:app=$app>
    設定
  </t:include>

<body>
  <!-- XXX -->
  <t:include path=_common.html.tm m:app=$app />

  <section class=page>
    <header>
      <h1><a href=./><t:text value="$group->{data}->{title}"></a></h1>
      <m:group-menu m:group=$group />
    </header>

    <section>
      <h1>グループ設定</>
      <form is=save-data data-saver=groupSaver method=post action=edit.json id=edit-form>
        <!-- XXX data-next=update group info -->
        <table class=config>
          <tbody>
            <tr>
              <th><label for=edit-title>グループ名</>
              <td><input name=title pl:value="$group->{data}->{title}" id=edit-title required>
            <tr>
              <th><label for=edit-theme>配色</>
              <td>
                <gr-select-theme name=theme pl:value="$group->{data}->{theme}">
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
          <button type=submit class=save-button>保存する</>
          <action-status hidden stage-saver=保存中... ok=保存しました。 />
      </form>
    </section>

    <section>
      <h1>作成</h1>

      <tab-set>
        <tab-menu/>

        <section>
          <h1>日記</h1>

        <form method=post action=javascript: data-action=i/create.json
            data-next=go:/g/{group_id}/i/{index_id}/config>
          <table class=config>
            <tbody>
              <tr>
                <th><label for=create-blog-title>日記の題名</>
                <td><input name=title id=create-blog-title required>
          </table>
          <script>
            ((c) => {
              $with ('GR').then (() => {
                return GR.theme.getDefault ();
              }).then (theme => {
                var input = document.createElement ('input');
                input.type = 'hidden';
                input.name = 'theme';
                input.value = theme;
                c.appendChild (input);
              });
            }) (document.currentScript.parentNode);
          </script>

          <p class=operations>
            <input type=hidden name=index_type value=1>
            <button type=submit class=save-button>作成する</>
            <gr-action-status hidden stage-fetch=作成中... stage-next=移動します... />
        </form>
        </section>

        <section>
          <h1>Wiki</h1>

        <form method=post action=javascript: data-action=i/create.json
            data-next=go:/g/{group_id}/i/{index_id}/config>
          <table class=config>
            <tbody>
              <tr>
                <th><label for=create-wiki-title>Wiki の題名</>
                <td><input name=title id=create-wiki-title required>
          </table>
          <script>
            ((c) => {
              $with ('GR').then (() => {
                return GR.theme.getDefault ();
              }).then (theme => {
                var input = document.createElement ('input');
                input.type = 'hidden';
                input.name = 'theme';
                input.value = theme;
                c.appendChild (input);
              });
            }) (document.currentScript.parentNode);
          </script>

          <p class=operations>
            <input type=hidden name=index_type value=2>
            <button type=submit class=save-button>作成する</>
            <gr-action-status hidden stage-fetch=作成中... stage-next=移動します... />
        </form>
        </section>

        <section>
          <h1>TODO リスト</h1>

        <form method=post action=javascript: data-action=i/create.json
            data-next=go:/g/{group_id}/i/{index_id}/config>
          <table class=config>
            <tbody>
              <tr>
                <th><label for=create-todo-list-title>TODOリストの題名</>
                <td><input name=title id=create-todo-list-title required>
          </table>
          <script>
            ((c) => {
              $with ('GR').then (() => {
                return GR.theme.getDefault ();
              }).then (theme => {
                var input = document.createElement ('input');
                input.type = 'hidden';
                input.name = 'theme';
                input.value = theme;
                c.appendChild (input);
              });
            }) (document.currentScript.parentNode);
          </script>

          <p class=operations>
            <input type=hidden name=index_type value=3>
            <button type=submit class=save-button>作成する</>
            <gr-action-status hidden stage-fetch=作成中... stage-next=移動します... />
        </form>

      <details>
        <summary>ラベルの作成</summary>

        <form method=post action=javascript: data-action=i/create.json
            data-next=go:/g/{group_id}/i/{index_id}/config>
          <table class=config>
            <tbody>
              <tr>
                <th><label for=create-label-title>ラベル</>
                <td><input name=title id=create-label-title required>
          </table>

          <p class=operations>
            <input type=hidden name=index_type value=4>
            <button type=submit class=save-button>作成する</>
            <gr-action-status hidden stage-fetch=作成中... stage-next=移動します... />
        </form>
      </details>

      <details>
        <summary>マイルストーンの作成</summary>

        <form method=post action=javascript: data-action=i/create.json
            data-next=go:/g/{group_id}/i/{index_id}/config>
          <table class=config>
            <tbody>
              <tr>
                <th><label for=create-milestone-title>マイルストーン名</>
                <td><input name=title id=create-milestone-title required>
          </table>

          <p class=operations>
            <input type=hidden name=index_type value=5>
            <button type=submit class=save-button>作成する</>
            <gr-action-status hidden stage-fetch=作成中... stage-next=移動します... />
        </form>
      </details>
        </section>

        <section>
          <h1>アップローダー</h1>

        <form method=post action=javascript: data-action=i/create.json
            data-next=go:/g/{group_id}/i/{index_id}/config>
          <table class=config>
            <tbody>
              <tr>
                <th><label for=create-fileset-title>フォルダー名</>
                <td><input name=title id=create-fileset-title required>
              <tr>
                <th>種別
                <td>
                  <label><input type=radio name=subtype value=file checked required> ファイルアップローダー</label>
                  <label><input type=radio name=subtype value=image required> アルバム</label>
          </table>

          <p class=operations>
            <input type=hidden name=index_type value=6>
            <button type=submit class=save-button>作成する</>
            <gr-action-status hidden stage-fetch=作成中... stage-next=移動します... />
        </form>
        </section>
      </tab-set>
    </section>

    <section>
      <h1>データのインポート</h1>

      <p>他のサービスからこのグループに<a href=import>データをインポート</a>できます。
    </section>
  </section>

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
