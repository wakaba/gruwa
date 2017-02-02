<html t:params="$app">
<title>ヘルプ - Gruwa</title>
<t:if x="not $app->config->{is_production}">
  <meta name=referrer content=no-referrer>
<t:else>
  <meta name=referrer content=origin>
</t:if>
<link rel=stylesheet href=/css/common.css>
<script src=/js/pages.js async />

<header class=common>
  <header-area>
    <hgroup>
      <h1><a href=/ rel=top>Gruwa</h1>
    </>
  </header-area>
  <header-area>
    <a href=/dashboard>ダッシュボード</>
    <a href=/help rel=help>ヘルプ</a>
  </header-area>
</header>

  <section class=help>
    <h1>Gruwa のヘルプ</>

    <p><dfn id=gruwa>Gruwa</> (ぐるわ) は、グループウェアのようなものです。
    <a href=#groups>グループ</a>に参加して、その中で色々なことができます。

    <section id=groups>
      <h1>グループ</h1>

      <p>グループには次の機能があります。

      <ul>
        <li><a href=#blogs>日記</a>
        <li><a href=#wiki>Wiki</a>
        <li><a href=#todos>TODO リスト</a>
        <li><a href=#labels>ラベル</a>
        <li><a href=#milestones>里程標</a>
      </ul>

      <p>グループの参加者は、所有者と一般参加者に分かれます。
      所有者は、グループの参加者を管理することができます。
    </section>

    <section id=blogs>
      <h1>日記</h1>

      <p>グループ内に日記を作ることができます。日記は、
      グループメンバーの誰でも、複数個でも作ることができます。
      メンバーごとに自分の作業日誌を作ったり、
      プロジェクトごとに開発日誌を作ったりできます。

      <hr>

      <p>グループ内の日記のうちの1つを自分の<dfn id=default-blog-index>既定の日記</dfn>に選ぶことができます。
      既定の日記は、<a href=/dashboard>ダッシュボード</a>やグループ内ページのヘッダーからリンクされるので、すぐに移動できます。

      <hr>

      <p>日記内では、日毎に何本でも<a href=#objects>記事</a>を書くことができます。
      標準では当日の記事となりますが、他の日付に設定することもできます。
    </section>

    <section id=wikis>
      <h1>Wiki</h1>

      <p>グループ内に Wiki を作ることができます。

      <hr>

      <p>グループ内の Wiki のうちの1つを「<dfn id=default-wiki-index>グループの Wiki</dfn>」に選ぶことができます。
      グループの Wiki は、グループ内の Wiki 名リンクのリンク先となります。

      <p>グループの Wiki の選択は、 Wiki の設定ページから行えます。

      <p>なお、グループの作成時に自動的に Wiki が作成され、
      グループの Wiki に選択された状態となっています。

      <hr>

      <p>Wiki の<a href=#objects>記事</a>は、
      題名 (<dfn id=wiki-name>Wiki名</dfn>) で識別されます。
      他の<a href=#objects>記事</a>から「Wiki名リンク」を使ってリンクできます。
    </section>

    <section id=todos>
      <h1>TODO リスト</h1>

      <p>グループ内に TODO リストを作ることができます。

      <p>TODO リストは<a href=#labels>ラベル</a>や<a href=#milestones>里程標</a>で整理できます。
    </section>

    <section id=labels>
      <h1>ラベル</h1>

      <p>グループ内に整理のためのラベルを設けることができます。

      <p>ラベルには、わかりやすいように色を設定できます。

      <hr>

      <p><a href=#objects>記事</a>にはラベルを付けることができます。
    </section>

    <section id=milestones>
      <h1><ruby>里程標<rt>マイルストーン</ruby></h1>

      <p>グループ内に里程標を置くことができます。
      里程標は、計画の各段階や期限を切った予定をまとめるために使えます。

      <p>里程標には締切日を設定できます。

      <hr>

      <p><a href=#objects>記事</a>は里程標に登録できます。
    </section>

    <section id=objects>
      <h1>記事</h1>

      <p><a href=#blogs>日記</a>や <a href=#wikis>Wiki</a> や 
      <a href=#todos>TODO リスト</a>の各項目のことを<dfn>記事</dfn>といいます。

      <p>記事ごとに「所属」を選ぶことができます。記事は複数の日記や
      Wiki などに所属させることができます。例えば、
      個人の開発日記とプロジェクト進行まとめ日記の両方に所属させたり、
      TODO 項目をプロジェクトで分類するためにプロジェクト日記に所属させたりできます。
    </section>

    <section id=search>
      <h1>検索</h1>

      <p>グループ内の各ページの最上部には、検索フォームがあります。
      グループ内から指定した条件の記事を探すことができます。

      <p>指定した検索キーワードを含む記事の一覧が表示されます。
      スペース区切りで検索キーワードを複数個指定できます。

      <p>検索キーワードの前に <code>-</code> を書くと、
      指定したキーワードを含ま<em>ない</em>記事が表示されます。
    </section>

    <section id=accounts>
      <h1>利用者アカウント</h1>

      <p>Gruwa の利用者アカウントは、数値 ID で識別されます。
      このアカウントIDは、64ビット符号無し整数です。
      一旦割り当てられたアカウントIDは、他のアカウントに再利用されません。

      <p>アカウントには利用者自身が名前を登録できます。
      この名前はグループのメンバー一覧などで使われます。

      <p>名前は全グループ共通であり、公開情報として扱われます。
    </section>

    <section id=jump>
      <h1>ジャンプリスト</h1>

      <p><dfn id=jump-list>ジャンプリスト</dfn>は、 Gruwa 内の個人用の栞
      (ブックマーク) 機能です。グループ、日記、記事などを登録できます。
      登録したページへは、 Gruwa 内のどのページでも、
      上部のメニューから簡単に移動できます。

      <p>登録した各項目のラベル (文字列) は、
      ジャンプリストページから変更できます。
      ジャンプリストの表示順序は、利用頻度に応じて自動的に決まります。

      <p>ジャンプリストには最大100件のページを登録できます。
    </section>
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
