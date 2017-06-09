<html t:params="$group $account $group_member $app" pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-theme="$group->{data}->{theme}">
<head>
  <t:include path=_group_head.html.tm m:group=$group m:account=$account m:app=$app>
    設定
  </t:include>

<body>
  <t:include path=_group_header.html.tm m:group=$group m:account=$account m:group_member=$group_member m:app=$app />

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
                <select name=theme oninput=" document.documentElement.setAttribute ('data-theme', value) " id=edit-theme>
                  <option value=green pl:selected="$group->{data}->{theme} eq 'green'?'':undef">緑
                  <option value=blue pl:selected="$group->{data}->{theme} eq 'blue'?'':undef">青
                  <option value=red pl:selected="$group->{data}->{theme} eq 'red'?'':undef">赤
                  <option value=black pl:selected="$group->{data}->{theme} eq 'black'?'':undef">黒
                </select>
        </table>
        <p class=operations>
          <button type=submit class=save-button>保存する</>
          <action-status hidden stage-fetch=保存中... ok=保存しました。 />
      </form>
    </section>

    <section>
      <h1>作成</h1>

      <details>
        <summary>日記の作成</summary>

        <form method=post action=javascript: data-action=i/create.json
            data-href-template=/g/{group_id}/i/{index_id}/config>
          <table class=config>
            <tbody>
              <tr>
                <th><label for=create-blog-title>日記の題名</>
                <td><input name=title id=create-blog-title required>
          </table>

          <p class=operations>
            <input type=hidden name=index_type value=1>
            <button type=submit class=save-button>作成する</>
            <action-status hidden stage-fetch=作成中... stage-next=移動します... />
        </form>
      </details>

      <details>
        <summary>Wiki の作成</summary>

        <form method=post action=javascript: data-action=i/create.json
            data-href-template=/g/{group_id}/i/{index_id}/config>
          <table class=config>
            <tbody>
              <tr>
                <th><label for=create-wiki-title>Wiki の題名</>
                <td><input name=title id=create-wiki-title required>
          </table>

          <p class=operations>
            <input type=hidden name=index_type value=2>
            <button type=submit class=save-button>作成する</>
            <action-status hidden stage-fetch=作成中... stage-next=移動します... />
        </form>
      </details>

      <details>
        <summary>TODOリストの作成</summary>

        <form method=post action=javascript: data-action=i/create.json
            data-href-template=/g/{group_id}/i/{index_id}/config>
          <table class=config>
            <tbody>
              <tr>
                <th><label for=create-todo-list-title>TODOリストの題名</>
                <td><input name=title id=create-todo-list-title required>
          </table>

          <p class=operations>
            <input type=hidden name=index_type value=3>
            <button type=submit class=save-button>作成する</>
            <action-status hidden stage-fetch=作成中... stage-next=移動します... />
        </form>
      </details>

      <details>
        <summary>ラベルの作成</summary>

        <form method=post action=javascript: data-action=i/create.json
            data-href-template=/g/{group_id}/i/{index_id}/config>
          <table class=config>
            <tbody>
              <tr>
                <th><label for=create-label-title>ラベル</>
                <td><input name=title id=create-label-title required>
          </table>

          <p class=operations>
            <input type=hidden name=index_type value=4>
            <button type=submit class=save-button>作成する</>
            <action-status hidden stage-fetch=作成中... stage-next=移動します... />
        </form>
      </details>

      <details>
        <summary>マイルストーンの作成</summary>

        <form method=post action=javascript: data-action=i/create.json
            data-href-template=/g/{group_id}/i/{index_id}/config>
          <table class=config>
            <tbody>
              <tr>
                <th><label for=create-milestone-title>マイルストーン名</>
                <td><input name=title id=create-milestone-title required>
          </table>

          <p class=operations>
            <input type=hidden name=index_type value=5>
            <button type=submit class=save-button>作成する</>
            <action-status hidden stage-fetch=作成中... stage-next=移動します... />
        </form>
      </details>

      <details>
        <summary>アップローダーの作成</summary>

        <form method=post action=javascript: data-action=i/create.json
            data-href-template=/g/{group_id}/i/{index_id}/config>
          <table class=config>
            <tbody>
              <tr>
                <th><label for=create-fileset-title>名前</>
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
            <action-status hidden stage-fetch=作成中... stage-next=移動します... />
        </form>
      </details>
    </section>
  </section>

  <section class=group-config-import>
    <h1>データのインポート</h1>

    <p><strong>上級者向け</strong>:
    他のサービスからこのグループにデータをインポートできます。
    詳しくは<a href=/help#import target=help>ヘルプ</a>をご参照ください。</p>

    <p>まずは<a href id=bookmarklet-link data-confirm=ブックマークレットとしてお使いください>Gruwa インポート用ブックマークレット</a>をお使いの
    Web ブラウザーのブックマークに登録してください。
    <script>
      var url = "javascript:var script=document.createElement('script');script.src='"+location.origin+"/js/embedded.js';document.body.appendChild(script)";
      var a = document.querySelector ("#bookmarklet-link");
      a.href = url;
      a.onclick = function () {
        alert (this.getAttribute ('data-confirm'));
        return false;
      };
    </script></p>

    <p>次にインポートしたい Web サイトを同じ Web 
    ブラウザーの別の窓やタブで開き、
    ブックマークレットを実行してください。</p>

    <p>その後、一覧から「インポート開始」を選んでください。
    インポートには数分から数十分かかります。インポートしたい Web
    サイトとこのページの両方を開いた状態でお待ちください。</p>

    <script src=/js/sha1.js />
    <script src=/js/import.js />
    <list-container loader=import key=sources type=table id=import-list>
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
      <action-status hidden stage-load=読込中... />
      <list-is-empty>
        現在インポートできるサイトはありません。
      </list-is-empty>
    </list-container>

    <div id=import-status>
      <action-status
          stage-getimported=インポート済みデータを確認中...
          stage-getkeywordlist=キーワード一覧を取得中...
          stage-createkeywordwiki=キーワード用Wikiを作成中...
          stage-createkeywordobjects=キーワードをインポート中...
          stage-getdiarylist=日記一覧を取得中...
          stage-creatediary=日記を作成中...
          stage-getfilelist=ファイル一覧を取得中...
          stage-createfileuploader=ファイルアップローダーを作成中...
          stage-getfiles=ファイルを取得中...
          ok=完了しました />
      <list-container type=table class=mapping-table>
        <template>
          <td><cite data-field=originalTitle>
          <td><a data-href-template=i/{index_id}/ data-field=title data-empty=(トップページ) />
          <td><data data-field=itemCount />
          <td><action-status
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
      </list-container>
    </div>
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
