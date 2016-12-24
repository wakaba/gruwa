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

    <section id=search>
      <h1>検索</h1>

      <p>グループ内の各ページの最上部には、検索フォームがあります。
      グループ内から指定した条件の記事を探すことができます。

      <p>指定した検索キーワードを含む記事の一覧が表示されます。
      スペース区切りで検索キーワードを複数個指定できます。

      <p>検索キーワードの前に <code>-</code> を書くと、
      指定したキーワードを含ま<em>ない</em>記事が表示されます。
    </section>

    <section id=diary-index>
      <h1>日記</h1>

      <p>グループ内の日記のうちの1つを自分の<dfn id=default-diary-index>既定の日記</dfn>に選ぶことができます。
      既定の日記は、<a href=/dashboard>ダッシュボード</a>やグループ内ページのヘッダーからリンクされるので、すぐに移動できます。
    </section>

    <section id=keyword-index>
      <h1>キーワード集</h1>

      <p>グループ内のキーワード集のうちの1つを「<dfn id=default-keyword-index>既定のキーワード集</dfn>」に選ぶことができます。
      既定のキーワード集は、グループ内のキーワードページやキーワードリンクで使われます。
      既定のキーワード集は、グループのすべての参加者で共通です。

      <p>既定のキーワード集の選択は、キーワード集の設定ページから行えます。
    </section>
  </section>
