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
    <h1>ヘルプ</>

    <p><dfn id=gruwa>Gruwa</> (ぐるわ) は、グループウェアのようなものです。

    <section id=groups>
      <h1>グループ</h1>

      <p>グループには次の機能があります。

      <ul>
        <li><a href=#blogs>日記</a>
        <li><a href=#wiki>Wiki</a>
        <li><a href=#todos>TODO リスト</a>
      </ul>
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

      <p>Wiki の記事は、題名 (<dfn id=wiki-name>Wiki名</dfn>) で識別されます。
      他の記事から「Wiki名リンク」を使ってリンクできます。
    </section>

    <section id=todos>
      <h1>TODO リスト</h1>

      <p>グループ内に TODO リストを作ることができます。

    </section>

    <section id=objects>
      <h1>記事</h1>

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
