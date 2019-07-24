<html t:params="$group $account $group_member $app" pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-theme="$group->{data}->{theme}"
    pl:data-bb-clientid="$app->config->{bitbucket}->{public}->{client_id}">
<!--

  The bitbucket.public.client_id value has to be the Key of a
  BitBucket OAuth consumer, with following configurations:

    Callback URL: https://{host}/account/done
    This is a private consumer: Unchcked
    Permissions: Account - Read, Repositories - Read, Issues - Read

-->
<head>
  <t:include path=_group_head.html.tm m:group=$group m:account=$account m:app=$app>
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
      <form action=javascript: data-action=edit.json id=edit-form>
        <table class=config>
          <tbody>
            <tr>
              <th><label for=edit-title>グループ名</>
              <td><input name=title pl:value="$group->{data}->{title}" id=edit-title>
            <tr>
              <th><label for=edit-theme>配色</>
              <td>
                <select name=theme oninput=" document.documentElement.setAttribute ('data-theme', value) " id=edit-theme onchange="
                  var opt = this.selectedOptions[0];
                  $fill (document.querySelector ('gr-theme-info'), opt.grDef);
                ">
                  <option value=green pl:selected="$group->{data}->{theme} eq 'green'?'':undef">緑
                  <option value=blue pl:selected="$group->{data}->{theme} eq 'blue'?'':undef">青
                  <option value=red pl:selected="$group->{data}->{theme} eq 'red'?'':undef">赤
                  <option value=black pl:selected="$group->{data}->{theme} eq 'black'?'':undef">黒
                </select>
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
                <script>
                  $with ('GR').then (() => {
                    return GR.theme.list ();
                  }).then (json => {
                    var select = document.querySelector ('select[name=theme]');
                    select.textContent = '';
                    json.names.forEach (theme => {
                      var def = json.themes[theme];
                      var option = document.createElement ('option');
                      option.value = theme;
                      option.label = def.label;
                      option.grDef = def;
                      def.name = theme;
                      select.appendChild (option);
                    });
                    select.value = document.documentElement.getAttribute ('data-theme');
                    select.onchange ();
                  });
                </script>
        </table>
        <p class=operations>
          <button type=submit class=save-button>保存する</>
          <gr-action-status hidden stage-fetch=保存中... ok=保存しました。 />
      </form>
    </section>

    <section>
      <h1>作成</h1>

      <gr-tab-set>
        <menu/>

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
      </gr-tab-set>
    </section>

  <section class=group-config-import>
    <h1>データのインポート</h1>

    <p><strong>警告</strong>: この機能は実験的なものです。
    予期せぬ結果となることがあります。

    <p>他のサービスからこのグループにデータをインポートできます。
    詳しくは<a href=/help#import target=help>ヘルプ</a>をご参照ください。</p>

    <gr-tab-set>
      <menu />

      <section>
        <h1>はてなグループ</h1>

        <p><strong>上級者向け</strong>:
        はてなグループの日記、キーワード、
        共有ファイルをこのグループにインポートできます。

        <ol>
          <li><a href id=bookmarklet-link data-confirm=ブックマークレットとしてお使いください>Gruwa インポート用ブックマークレット</a>をお使いの
          Web ブラウザーのブックマークに登録してください。
    <script>
      var url = "javascript:var script=document.createElement('script');script.src='"+location.origin+"/js/embedded.js';document.body.appendChild(script)";
      var a = document.querySelector ("#bookmarklet-link");
      a.href = url;
      a.onclick = function () {
        alert (this.getAttribute ('data-confirm'));
        return false;
      };
    </script>

          <li>インポートしたい Web サイトを Web 
          ブラウザーの新しい窓 (タブ) で開き、
          ブックマークレットを実行してください。

          <li>一覧から「インポート開始」を選んでください。
          インポートには数分から数十分かかります。インポートしたい Web
          サイトとこのページの両方を開いた状態でお待ちください。

        </ol>

        <script src=/js/sha1.js />
        <script src=/js/import.js />
    <gr-list-container loader=import key=sources type=table id=import-list>
      <p class=buttons>
        <button type=button class=reload-button>再読込</button>
      </p>

      <template>
        <td><code data-field=origin></code>
        <td>
          <input type=hidden name=sourceId data-field=sourceId>
          <button type=button class=save-button onclick="
            Importer.run (previousElementSibling.value,
                          document.querySelector ('#import-status'),
                          {forceUpdate: hasAttribute ('data-force')});
          ">インポート開始</button>
      </template>
      <table>
        <thead>
          <tr>
            <th>サイト
            <th>操作
        <tbody>
      </table>
      <gr-action-status hidden stage-load=読込中... />
      <list-is-empty>
        現在インポートできるグループはありません。
      </list-is-empty>
    </gr-list-container>

      </section>

      <section>
        <h1>Bitbucket</h1>

        <p>Bitbucket リポジトリーの Issues をこのグループにインポートできます。</p>

    <gr-list-container loader=bitbucket-repos noautoload key=repos type=table id=import-bb-list>
      <p class=buttons>
        <button type=button class=reload-button>再読込</button>
      </p>

      <template>
        <td><a data-href-template="https://bitbucket.org/{full_name}" target=bitbucket><code data-field=full_name></code></a>
        <td>
          <input type=hidden name=username data-field=owner.username>
          <input type=hidden name=slug data-field=slug>
          <button type=button class=save-button onclick="
            var bb = new Importer.BitBucket;
            bb.run (parentNode.querySelector ('[name=username]').value,
                    parentNode.querySelector ('[name=slug]').value,
                    document.querySelector ('#import-status'),
                    {forceUpdate: hasAttribute ('data-force')});
          ">インポート開始</button>
      </template>
      <table>
        <thead>
          <tr>
            <th>リポジトリー
            <th>操作
        <tbody>
      </table>
      <gr-action-status hidden stage-load=読込中... />
      <list-is-empty>
        現在インポートできるリポジトリーはありません。
      </list-is-empty>
    </gr-list-container>

      </section>
    </gr-tab-set>

    <div id=import-status>
      <gr-action-status
          stage-auth=アクセス許可を取得中...
          stage-getimported=インポート済みデータを確認中...
          stage-getkeywordlist=キーワード一覧を取得中...
          stage-createkeywordwiki=キーワード用Wikiを作成中...
          stage-createkeywordobjects=キーワードをインポート中...
          stage-getdiarylist=日記一覧を取得中...
          stage-creatediary=日記を作成中...
          stage-getfilelist=ファイル一覧を取得中...
          stage-createfileuploader=ファイルアップローダーを作成中...
          stage-getfiles=ファイルを取得中...
          stage-createtodo=TODOリストを作成中...
          stage-getissuelist=Issue一覧を取得中...
          stage-createissueobjects=Issueをインポート中...
          ok=完了しました />
      <gr-list-container type=table class=mapping-table>
        <template>
          <td><cite data-field=originalTitle>
          <td><a data-href-template=i/{index_id}/ data-field=title data-empty=(トップページ) />
          <td><data data-field=itemCount />
          <td><gr-action-status
                  stage-objects=変換中...
                  ok=完了 />
        </template>
        <table hidden>
          <thead>
            <tr>
              <th>元サイト
              <th>インポート先
              <th>件数
              <th>進捗
          <tbody>
        </table>
      </gr-list-container>
    </div>
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
