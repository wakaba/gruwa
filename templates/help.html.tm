<html t:params="$app">
  <head>
    <t:include path=_other_head.html.tm m:app=$app m:public=1>
      ヘルプ
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
  </header-area>
</header>

  <section class=help>
    <h1>Gruwa のヘルプ</>

    <p><dfn id=gruwa>Gruwa</> (ぐるわ) は、グループウェアのようなものです。
    <a href=#groups>グループ</a>に参加して、その中で色々なことができます。

    <section id=groups>
      <h1>グループ</h1>

      <p>Gruwa のほとんどの機能は<dfn>グループ</dfn>に属しています。
      <a href=#groups>グループ</a>は、
      1人以上で利用できます。どのような人の集まりでも構いませんが、
      比較的少人数で互いに信頼関係が構築された関係を想定しています。
      
      <p><a href=#groups>グループ</a>には次の機能があります。

      <ul>
        <li><a href=#blogs>日記</a>
        <li><a href=#wiki>Wiki</a>
        <li><a href=#todos>TODO リスト</a>
        <li><a href=#labels>ラベル</a>
        <li><a href=#milestones>マイルストーン</a>
        <li><a href=#filesets>ファイル</a>
      </ul>

      <p id=group-create><a href=#groups>グループ</a>は、
      <a href=#dashboard>ダッシュボード</a>の<a href=#dashboard-groups>グループ</a>ページから作成できます。
      (サーバー管理者がサーバー設定 JSON ファイルで
      <code>"no_create_group_key": true</code> に設定し<em>ない</em>場合、
      認証が必要です。
      ユーザー名は <code>g</code>、パスワードは
      <code>"create_group_key": "<var>...</var>"</code>
      で指定した文字列です。)
      
      <section id=group-members>
        <h1>参加者</h1>

        <p><a href=#groups>グループ</a>を使うには、
        まず<a href=#groups>グループ</a>の<dfn>参加者</dfn>となる必要があります。

        <p><a href=#groups>グループ</a>の<a href=#group-members>参加者</a>には<a href=#owner>所有者</a>と<a href=#normal-member>一般参加者</a>の
        2種別があります。
        作成者は<a href=#groups>グループ</a>の<a href=#owner>所有者</a>となります。
        <dfn id=owner>所有者</dfn>は<a href=#group-members>参加者</a>を管理できるので、
        新しい<a href=#group-members>参加者</a>を追加したり、
        種別を変更したりできます。

        <p><a href=#group-members>参加者</a>管理以外のほとんどの操作は、
        <dfn id=normal-member>一般参加者</dfn>を含むすべての<a href=#group-members>参加者</a>が行えます。

        <hr>
        
        <p><a href=#group-members>参加者</a>の一覧は、
        <a href=#groups>グループ</a>の<a href=#menu>メニュー</a>の
        「参加者」から見ることができます。

        <p>「参加者一覧」には、
        すべての<a href=#group-members>参加者</a>が表示されます。
        <a href=#owner>所有者</a>は、
        参加承認を取り消したり、メモを書いたりできます。

          <ul class=notes>

            <li>自分自身の参加承認は取り消せません。
            
          </ul>

        <hr>
        
        <p>「参加者の追加」では<dfn id=invitation>招待状</dfn>を発行できます
        (<a href=#owner>所有者</a>のみ)。
        <a href=#invitation>招待状</a>を開いて参加を選ぶと、
        招待された<a href=#groups>グループ</a>の<a href=#group-members>参加者</a>となります。
        1枚の<a href=#invitation>招待状</a>で参加できるのは1人だけです。
        <a href=#invitation>招待状</a>には有効期限が設定されています。

        <p><a href=#invitation>招待状</a>を発行すると、
        <a href=#invitation>招待状</a>を開くための URL
        が表示されます。この URL を渡して、
        Web ブラウザーで開いてもらってください。
        QR コードも表示されるので、こちらから招待状を開いてもらうこともできます。
        
        <p><a href=#invitation>招待状</a>発行時に
        「既定の日記」を指定すると、
        指定した<a href=#blogs>日記</a>が<a href=#default-blog-index>既定の日記</a>となった状態で参加させることができます。
        
        <p>「発行済招待状」にはこれまでに発行した<a href=#invitation>招待状</a>が表示されます
        (<a href=#owner>所有者</a>のみ)。
        発行済の<a href=#invitation>招待状</a>を無効にすることもできます。

        <hr>

        <p>グループの参加者が参加者ではなくなると、
        グループにはアクセスできなくなります。
        参加中に作成した<a href=#objects>記事</a>などは、
        そのまま残ります。
      </section>

      <section id=config>
        <h1>設定</h1>

        <p><a href=#groups>グループ</a>、
        <a href=#blogs>日記</a>、
        <a href=#wiki>Wiki</a>、
        <a href=#todos>TODO リスト</a>、
        <a href=#labels>ラベル</a>、
        <a href=#milestones>マイルストーン</a>、
        <a href=#filesets>フォルダー</a>の<dfn id=menu>メニュー</dfn>から「設定」を選ぶと、
        設定を変更できます。

        <p><a href=#groups>グループ</a>の<a href=#group-members>参加者</a>の個別の設定は、
        <a href=#groups>グループ</a>のメニューから「参加者」
        ページを開き、「自分の参加者設定を変更」を選ぶと、変更できます。

          <ul class=notes>

            <li>メニューは各ページの上部、右端にある
            「&#x25BC」印のボタンから開けます。
            <li><a href=#group-members>参加者</a>設定は、
            自身の設定のみ変更できます。
            
          </ul>
        
        
        <table>
          <thead>
            <tr>
              <th>項目
              <th>設定対象
              <th>説明
          <tbody>
            <tr>
              <th>名前
              <td>
                <a href=#groups>グループ</a>、
                <a href=#blogs>日記</a>、
                <a href=#wiki>Wiki</a>、
                <a href=#todos>TODO リスト</a>、
                <a href=#labels>ラベル</a>、
                <a href=#milestones>マイルストーン</a>、
                <a href=#filesets>フォルダー</a>、
                <a href=#group-members>参加者</a>
              <td>
                名前 (題名) です。
            <tr>
              <th>配色
              <td>
                <a href=#groups>グループ</a>、
                <a href=#blogs>日記</a>、
                <a href=#wiki>Wiki</a>、
                <a href=#todos>TODO リスト</a>
              <td>
                所属する<a href=#objects>記事</a>ページなどの表示に使う<a href=#themes>配色</a>です。
            <tr>
              <th>アイコン
              <td>
                <a href=#groups>グループ</a>、
                <a href=#group-members>参加者</a>
              <td>
                名前と共に表示されるアイコンです。

                <ul class=notes>
                  <li>アイコンは<a href=#fileset-icon>アイコン集</a>から選ぶか、保存されます。
                  <li>アイコンが変更されてから反映されるまで、
                  時間がかかることがあります。
                </ul>
            <tr id=group-guide>
              <th>ガイドページ
              <td>
                <a href=#groups>グループ</a>
              <td>
                <a href=#groups>グループ</a>の利用案内や、
                <a href=#owner>所有者</a>の決めたグループ利用規約を記述できる<a href=#objects>記事</a>です。
            <tr>
              <th>自己紹介ページ
              <td>
                <a href=#group-members>参加者</a>
              <td>
                <a href=#group-members>参加者</a>の紹介文を記述できる<a href=#objects>記事</a>です。
        </table>

        <p id=group-config-create><a href=#groups>グループ</a>の<a href=#config>設定</a>ページでは、
        <a href=#blogs>日記</a>、
        <a href=#wiki>Wiki</a>、
        <a href=#todos>TODO リスト</a>、
        <a href=#labels>ラベル</a>、
        <a href=#milestones>マイルストーン</a>、
        <a href=#filesets>フォルダー</a>を作成できます。
        (この操作は取り消せないのでご注意ください。)

        <p><a href=#groups>グループ</a>の<a href=#config>設定</a>ページから、
        <a href=#import>インポート</a>機能を利用できます。

      </section>

      <section id=themes>
        <h1>配色</h1>

        <p><a href=#groups>グループ</a>、
        <a href=#blogs>日記</a>、
        <a href=#wiki>Wiki</a>、
        <a href=#todos>TODO リスト</a>は、
        <a href=#config>設定</a>から「配色」 (デザインテーマ) を変更できます。グループの配色は、
        <a href=#blogs>日記</a>、
        <a href=#wiki>Wiki</a>、
        <a href=#todos>TODO リスト</a>以外のページに適用されます。

        <p>グループごと、日記ごとに違う配色を選ぶと、
        誤投稿しにくくなって便利です。

          <ul class=notes>
            <li><a href=https://github.com/wakaba/gruwa-themes>利用できる配色</a>の中には、
            他のソフトウェア
            (<cite>tDiary</cite> や<a href=http://d.hatena.ne.jp/keyword/%A4%CF%A4%C6%A4%CA%A5%C0%A5%A4%A5%A2%A5%EA%A1%BC%A5%C6%A1%BC%A5%DE%BA%EE%C0%AE%BB%FE%A4%CE%C3%ED%B0%D5?kid=1342#fn3><cite>はてなダイアリー</cite></a>)
            のために開発され、
            オープンソースライセンスで配布されているものも含まれます。
            Gruwa と他のソフトウェアの構造の違いのため、
            適切に表示できないものもあります
            (順次改善予定です)。
          </ul>
      </section>
    </section>

    <section id=blogs>
      <h1>日記</h1>

      <p>グループ内に日記を作ることができます。日記は、
      グループメンバーの誰でも、複数個でも作ることができます。
      メンバーごとに自分の作業日誌を作ったり、
      プロジェクトごとに開発日誌を作ったりできます。

      <hr>

      <p>グループ内の日記のうちの1つを自分の<dfn id=default-blog-index>既定の日記</dfn>に選ぶことができます。
      既定の日記は、<a href=/dashboard>ダッシュボード</a>やグループ内ページのヘッダーの「グループ内の自分の日記」からリンクされるので、すぐに移動できます。

      <hr>

      <p>日記内では、日毎に何本でも<a href=#objects>記事</a>を書くことができます。
      標準では当日の記事となりますが、他の日付に設定することもできます。
    </section>

    <section id=wikis>
      <h1>Wiki</h1>

      <p>グループ内に <dfn id=wiki><ruby>Wiki<rt>ウィキ</ruby></dfn>
      を作ることができます。

      <hr>

      <p>グループ内の Wiki のうちの1つを
      「<dfn id=default-wiki-index>グループの Wiki</dfn>」
      に選ぶことができます。
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

      <p>TODO リストは<a href=#labels>ラベル</a>や<a href=#milestones>マイルストーン</a>で整理できます。
    </section>

    <section id=labels>
      <h1>ラベル</h1>

      <p>グループ内に整理のためのラベルを設けることができます。

      <p>ラベルには、わかりやすいように色を設定できます。

      <hr>

      <p><a href=#objects>記事</a>にはラベルを付けることができます。
    </section>

    <section id=milestones>
      <h1>マイルストーン</h1>

      <p>グループ内にマイルストーン (里程標) を置くことができます。
      マイルストーンは、計画の各段階や期限を切った予定をまとめるために使えます。

      <p>マイルストーンには締切日を設定できます。

      <hr>

      <p><a href=#objects>記事</a>ごとにマイルストーンを設定できます。
    </section>

    <section id=filesets>
      <h1>ファイル</h1>

      <p><a href=#groups>グループ</a>には、
      ファイルを入れる<dfn>フォルダー</dfn>を作ることができます。

      <p><a href=#groups>グループ</a>の「ファイル」ページに、
      <a href=#filesets>フォルダー</a>の一覧が表示されます。
      新しい<a href=#filesets>フォルダー</a>は、
      <a href=#groups>グループ</a>の「設定」ページから作成できます。

      <p><a href=#filesets>フォルダー</a>には、いくつかの種類があります。

      <dl>
        <div>
          <dt><dfn id=fileset-file>ファイルフォルダー</dfn>
          <dd>
            <p>どんなファイルでもアップロードできます。
            
            <p>ファイルフォルダーは、記事編集ツールバーのファイル (&#x1F4C4;)
            ボタンから呼び出すことができます。
            新しいファイルをアップロードしたり、既存のファイルを選んだりして、
            ファイルへのリンクを記事に挿入できます。
        </div>

        <div>
          <dt><dfn id=fileset-image>アルバム</dfn>
          <dd>
            <p>画像をアップロードできます。
            
            <p>アルバムは、記事編集ツールバーの画像 (&#x1F5BC;) 
            ボタンから呼び出すことができます。
            新しい画像をアップロードしたり、既存の画像を選んだりして、
            画像を記事に挿入できます。
        </div>

        <div>
          <dt><dfn id=fileset-icon>アイコン集</dfn>
          <dd>
            <p>画像をアップロードできます。

            <p><a href=#groups>グループ</a>や<a href=#accounts>利用者アカウント</a>のアイコンの保存に使います。
        </div>

        <div>
          <dt><dfn id=fileset-stamp>スタンプセット</dfn>
          <dd>
            <p>画像をアップロードできます。
        </div>
      </dl>
      
      <p>アップロードした画像やファイルは、
      グループ参加者が閲覧・ダウンロードできるようになります。

      <p>アップロードボタンの他に、
      ドラッグしたファイルをアップロード欄枠線内にドロップすることでも、
      ファイルをアップロードできます。

      <p>1個のファイルのサイズの上限は、
      <unit-number type=bytes><number-value>100</><number-unit>MB</></> です。
    </section>

    <section id=objects>
      <h1>記事</h1>

      <p><a href=#blogs>日記</a>や <a href=#wikis>Wiki</a> や 
      <a href=#todos>TODO リスト</a>の各項目のことを<dfn>記事</dfn>といいます。

      <section id=object-edit>
        <h1>記事の編集</h1>

      <p>記事のメニューから「編集」を選ぶと、記事の題名や本文を変更できます。

      <p>編集は、「見たまま」モードと「ソース」モードとで切り替えることができます。
      見たままモードでは、記事が表示されるままの形で編集できます。
      ソースモードでは、記事の HTML タグを編集できます。

      <p id=syntaxes>編集画面の「設定」から、標準の<dfn id=syntax-wysiwyg>見たまま</dfn>の他に、
      はてな記法を編集形式として選ぶことができます。
      「見たまま」以外の編集形式を選ぶと、
      「ソース」モードと「プレビュー」モードを切り替えて編集できるようになります。

      <p><a href=https://wiki.suikawiki.org/n/%E3%81%AF%E3%81%A6%E3%81%AA%E8%A8%98%E6%B3%95><dfn id=syntax-hatena>はてな記法</dfn></a>は、
      <a href=http://hatenablog.com/>はてなブログ</a>で用いられている構文です。
      ただし、 Gruwa では一部の記法の扱いが異なっています。
      はてなキーワードへのリンクは、<a href=#default-wiki-index>グループの
      Wiki</a> へのリンクと解釈します。
      
      <hr>

        <p>保存時に関係者に<a href=#object-call>記事通知</a>を送信できます。
        「<a href=#called-editor>通知送信先</a>」欄から送信先を細かく設定できます。

        <p><dfn id=called-editor>通知送信先</dfn>には、
        次の選択肢が表示されます。

          <dl>
            <div>
              <dt>「スレッドの購読者」
              <dd><dfn id=threads>スレッド</dfn>とは、
              <a href=#objects>記事</a>やそれに対する<a href=#comments>コメント</a>をいいます。
              「スレッドの購読者」を選ぶと、
              <a href=#threads>スレッド</a>に投稿した人全員に<a href=#object-call>記事通知</a>が送信されます。
            </div>
            <div>
              <dt><a href=#groups>グループ</a>の各<a href=#group-members>参加者</a>
              <dd><a href=#groups>グループ</a>の各<a href=#group-members>参加者</a>が表示され、
              それぞれ<a href=#object-call>記事通知</a>を送信するか選べます。
            </div>
            <div>
              <dt>「自分を除外する」
              <dd>「自分を除外する」を選ぶと、
              自分には<a href=#object-call>記事通知</a>を送信しません。
            </div>
          </dl>

          <ul class=notes>
            <li>複数の条件に該当する人にも、
            1回だけ<a href=#object-call>記事通知</a>が送信されます。
          </ul>
          
      <p>記事ごとに「所属」を選ぶことができます。記事は複数の日記や
      Wiki などに所属させることができます。例えば、
      個人の開発日記とプロジェクト進行まとめ日記の両方に所属させたり、
      TODO 項目をプロジェクトで分類するためにプロジェクト日記に所属させたりできます。

      <hr>

      <p><a href=#objects>記事</a>の<a href=#menu>メニュー</a>から
      「削除」を選ぶと、<a href=#objects>記事</a>の内容を消去できます。

        <ul class=notes>
          <li><a href=#objects>記事</a>への<a href=#comments>コメント</a>や履歴は削除後も残ります。
        </ul>

      <p><a href=#objects>記事</a>の<a href=#menu>メニュー</a>から
      「編集履歴」を選ぶと、<a href=#objects>記事</a>の変更日時、
      変更者、変更内容が表示されます。
      変更前の状態を表示することもできます。
        
      </section>

      <section id=object-reactions>
        <h1>記事への反応</h1>

      <p>各記事には<dfn id=object-comments>コメント欄</dfn>があり、
      記事についての議論や追加情報などの<dfn id=comments>コメント</dfn>を書くことができます。

        <p><a href=#comments>コメント</a>を投稿するには、
        記事の「コメントを書く」を選んで、
        コメント投稿フォームを開いてください。

        <p><a href=#comments>コメント</a>を投稿すると、
        関係者に<a href=#object-call>記事通知</a>が送信されます。
        コメント投稿フォームの「<a href=#called-editor>通知送信先</a>」欄から送信先を細かく設定できます。
        
      <p>同じグループ内の他の記事からリンク機能などで記事を参照すると、
      その記事への逆リンク (<dfn id=trackbacks>トラックバック</dfn>)
      が作成され、コメント欄に表示されます。

      <hr>

      <p><a href=#objects>記事</a>には<dfn id=stars><ruby>&#x2B50;<rt>スター</ruby></dfn>をつけることができます。
      「見ました」「すごい」「がんばれ」
      といったちょっとした気持ちを伝えるためにお使いください。
      ボタンを押すだけで、いくつでも簡単につけることができます。

      <p>間違えて<a href=#stars><ruby>&#x2B50;<rt>スター</ruby></a>をつけたときは、
      <a href=#stars><ruby>&#x2B50;<rt>スター</ruby></a>の横のメニューから
      「<ruby>&#x2B50;<rt>スター</ruby>を消す」
      を選ぶと、<a href=#stars><ruby>&#x2B50;<rt>スター</ruby></a>を
      1つ減らすことができます。
      
      <p>自分が作成した<a href=#objects>記事</a>に<a href=#stars><ruby>&#x2B50;<rt>スター</ruby></a>がつくと、
      <a href=#reports>活動レポート</a>でお知らせします。

      </section>
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

      <p>Gruwa の利用者には、それぞれの<dfn>利用者アカウント</dfn>が発行されます。
      <a href=#accounts>利用者アカウント</a>には他のサービスのアカウントを使ってログインできます。

      <p><a href=#accounts>利用者アカウント</a>には、
      <a href=#group>グループ</a>ごとの<dfn id=account-name>名前</dfn>と<dfn id=account-icon>アイコン</dfn>を設定できます。
      <a href=#account-name>名前</a>と<a href=#account-icon>アイコン</a>は<a href=#group-members>参加者</a>一覧、
      <a href=#comments>コメント</a>一覧、編集履歴などで使われます。

      <ul class=notes>
        <li><a href=#accounts>利用者アカウント</a>を作成して Gruwa
        を利用するためには、
        <a href=/terms>利用規約</a>にご同意いただく必要があります。
        <li><a href=#accounts>利用者アカウント</a>の識別のためにクッキーを使用します。
        <li>ログインに使ったサービスに、 Gruwa が無断で投稿することはありません。
        <li><a href=#account-icon>アイコン</a>は<a href=#groups>グループ</a>内の<a href=#objects>記事</a>として保存されます。

        <li><a href=#account-icon>アイコン</a>が変更されてから反映されるまで、
        時間がかかることがあります。
      </ul>
    </section>

    <section id=dashboard>
      <h1>ダッシュボード</h1>

      <p><a href=/dashboard><dfn>ダッシュボード</dfn></a>では、
      <a href=#groups>グループ</a>を横断して<a href=#accounts>自分</a>に関係ある情報を一覧できます。

      <p><a href=#dashboard>ダッシュボード</a>は、
      <a href=/>Gruwa のトップページ</a>や、
      グループ内ページ共通のメニューから開けます。

      <p><a href=#dashboard>ダッシュボード</a>には次のページがあります。

        <ul>
          <li><a href=#dashboard-groups>グループ</a>
          <li><a href=#jump>ジャンプリスト</a>
          <li><a href=#dashboard-calls>記事通知</a>
          <li><a href=#dashboard-receive>受信設定</a>
        </ul>
        
      <section id=dashboard-groups>
        <h1>グループ</h1>

        <p><a href=/dashboard/groups>グループ</a>ページには、
        参加中の<a href=#groups>グループ</a>の一覧が表示されます。
        更新があった順で表示されます。

        <p>他のグループに参加するには、
        <a href=#groups>グループ</a>の<a href=#owner>所有者</a>から<a href=#invitation>招待状</a>を発行してもらってください。

        <p>ここから<a href=#group-create>新しいグループも作成</a>できます。
        
          <ul class=notes>
            <li><a href=#owner>所有者</a>により<a href=#group-members>参加者</a>から外されると、
            一覧に表示されなくなります。
          </ul>
      </section>
      
    <section id=jump>
      <h1>ジャンプリスト</h1>

      <p><dfn id=jump-list>ジャンプリスト</dfn>は、 Gruwa 内の個人用の栞
      (ブックマーク) 機能です。グループ、日記、記事などを登録できます。
      登録したページへは、
      メニューから簡単に移動できます。

      <p>ジャンプリストへの登録は、
      登録したいグループや記事などの<a href=#menu>メニュー</a>から
      「ジャンプリストに追加」を選ぶだけです。
      ジャンプリストには最大100件のページを登録できます。
      ジャンプリストの表示順序は、利用頻度に応じて自動的に決まります。

      <p><a href=/jump>ジャンプリスト</a>ページでは、
      登録した各項目のラベル (文字列) を変更したり、
      項目を削除したりできます。
      </section>

      <section id=dashboard-calls>
        <h1>記事通知</h1>

        <p><a href=/dashboard/calls>記事通知</a>ページには、
        受信した<dfn id=object-call>記事通知</dfn>が表示されます。

        <p><a href=#object-call>記事通知</a>をプッシュ通知やインターネットメールで受け取るには、
        <a href=#dashboard-receive>受信設定</a>ページから設定してください。
      </section>

      <section id=dashboard-receive>
        <h1>受信設定</h1>
        
        <p id=notifications>「デスクトップ/スマートフォン通知」
        欄では、<a href=#object-call>記事通知</a>があったとき、
        デスクトップOSやスマートフォンの通知機能
        (プッシュ通知)
        でお知らせするよう設定できます。
        (お使いの Web ブラウザーが対応している必要があります。)
        設定していると、
        <a href=#object-call>記事通知</a>があるたびに、
        ほぼリアルタイムでお知らせします。

        <hr>

        <p id=emails>「インターネットメール」
        欄では、お知らせメールを受け取るメールアドレスを設定できます。
        メールアドレスは複数登録できます。
        どのアドレスにも同じ内容が配信されます。

        <p id=reports>お知らせ<a href=#emails>メール</a>は次の2種類があります。

          <dl>

            <div>
              <dt>活動レポート
              <dd>
                <a href=#groups>グループ</a>の更新があったときにお知らせします。
                1日1通程度を目安に、まとめてお届けします。
            </div>

            <div>
              <dt>記事通知
              <dd>
                <a href=#object-call>記事通知</a>により呼ばれたときにお知らせします。
                直近十数分程度の呼び出しをまとめてお届けします。
            </div>

          </dl>
          
          <ul class=notes>
            <li>同じ Web ブラウザーで複数の<a href=#accounts>アカウント</a>を使い分けていると、
            通知は正しく動作しません。
            <li>メールアドレスを追加すると、
            確認メールを送信します。確認メールから登録を完了すると、
            そのメールアドレスで受信できるようになります。
            <li>登録されたメールアドレスは、
            お知らせメール送信のほか、
            サービス運営者からのお知らせのため使用することがあります。
            (<a href=#privacy target=help>プライバシーについて</a>)
            <li>メール送信のエラーが繰り返される場合、
            そのメールアドレスへの配信を停止することがあります。
            <li>更新された<a href=#groups>グループ</a>がとても多いときは、
            活動レポートメールから一部省略する場合があります。
            <li><a href=#object-call>記事通知</a>がとても多いときは、
            <a href=#object-call>記事通知</a>お知らせメールから一部省略する場合があります。
          </ul>
          
      </section>
      
    </section>

    <section id=import>
      <h1>インポート</h1>

      <p><strong>警告</strong>: この機能は実験的なものです。

      <p>インポート機能を使うと、他の Web アプリケーションのデータを
      Gruwa のグループにコピーすることができます。

      <p>この機能は他のアプリケーションの既存のデータを Gruwa 
      に移行するために使うことを想定しています。
      インポートは何度でも繰り返し実行できますが、
      インポート後に他のアプリケーションと
      Gruwa の両方で編集していると、
      データの整合性を維持できなくなる可能性がありますので、
      ご注意ください。

      <p>同じ Web サイトからのインポートを同時に実行すると、
      同じ項目が重複してインポートされてしまう場合がありますので、
      ご注意ください。

      <p>インポート機能は (スマートフォンやタブレットではなく)
      デスクトップ環境で安定したネットワーク回線を確保して利用することをおすすめします。
      動作が長時間となるため、
      省電力設定などのために途中で自動停止することがないよう、
      ご注意ください。

      <p>長時間進行しない場合、何らかのエラーで停止している可能性があります。
      Gruwa と Web サイトの両方を再読込してからもう一度試してみてください。
      
      <section id=import-hatenagroup>
        <h1>はてなグループからのインポート</h1>

        <p><a href=http://g.hatena.ne.jp>はてなグループ</a>の特定のグループの内容を
        Gruwa のグループにインポートする機能です。

        <p>はてなグループと Gruwa の機能の対応関係は、
        次の表の通りとなっています。

        <table>
          <thead>
            <tr>
              <th>はてなグループ
              <th>Gruwa
              <th>補足
          <tbody>
            <tr>
              <td>グループ
              <td>グループ
              <td>
                読み取り権限があるグループのみ。
            <tr>
              <td>グループの参加者
              <td>-
              <td>
                対応していません。
            <tr>
              <td>グループの設定
              <td>-
              <td>
                配色以外には対応していません。
                スタイルシート、 HTML、トップページの設定、
                favicon、はてなメッセージ受信設定などは引き継げません。
            <tr>
              <td>グループ日記
              <td><a href=#blogs>日記</a>
              <td>
                読み取り権限がある日記のみ。
            <tr>
              <td>グループ日記の設定
              <td>-
              <td>
                タイトルと配色以外には対応していません。
                スタイルシート、 HTML などは引き継げません。
            <tr>
              <td>日
              <td><a href=#blogs>日記</a>の<a href=#objects>記事</a>
              <td>
                読み取り権限がある日記のみ。
                「今日の一枚」には対応していません。
            <tr>
              <td>日の最上位の見出し
              <td><a href=#blogs>日記</a>の<a href=#objects>記事</a>内の最上位の見出し
              <td>
                読み取り権限がある日記のみ。
            <tr>
              <td>日の最上位の見出しのはてなスター
              <td><a href=#blogs>日記</a>の<a href=#objects>記事</a>内の最上位の見出しのスター
              <td>
                読み取り権限がある日記のみ。
                インポートされたスターは表示のみ可能です
                (通常の Gruwa のスターとは異なります)。
            <tr>
              <td>日の最上位の見出しのはてなスターコメント
              <td><a href=#blogs>日記</a>の<a href=#objects>記事</a>への<a href=#object-comments>コメント</a>
              <td>
                読み取り権限がある日記、
                かつ読み取り権限があるはてなスターコメントのみ。
                投稿日時はインポート時点となります
                (はてなスターから取得できないため)。
            <tr>
              <td>日へのコメント
              <td><a href=#blogs>日記</a>の<a href=#objects>記事</a>への<a href=#object-comments>コメント</a>
              <td>
                読み取り権限がある日記のみ。
            <tr>
              <td>日へのトラックバック
              <td><a href=#blogs>日記</a>の<a href=#objects>記事</a>への<a href=#trackbacks>トラックバック</a>
              <td>
                トラックバック自体はインポートせず、
                記事内のリンク関係から再生成します。
                IDコールやインポート時点で存在しない記事からのリンク、
                グループ外からのトラックバックは生成されません。
                投稿日時は参照元記事の日時となります。
            <tr>
              <td>日の参照元
              <td>-
              <td>対応していません。
            <tr>
              <td>キーワード
              <td><a href=#wikis>Wiki</a> の<a href=#objects>記事</a>
              <td>
            <tr>
              <td>キーワードを含む日記、含むキーワード
              <td><a href=#wikis>Wiki</a> の<a href=#objects>記事</a>への<a href=#trackbacks>トラックバック</a>
              <td>
                含む日記、含むキーワード自体はインポートせず、
                記事内のリンク関係から再生成します。
            <tr>
              <td>掲示板
              <td>-
              <td>
                対応していません。
            <tr>
              <td>あしかのタスクグループ
              <td><a href=#labels>ラベル</a>
              <td>
            <tr>
              <td>あしかのタスク
              <td><a href=#todos>TODO リスト</a>の<a href=#objects>項目</a>
              <td>
                タスクの状態と所属タスクグループは過去の変更の有無に関わらずインポート時点のものとなります
                (はてなグループから変更履歴を取得できないため)。
            <tr>
              <td>あしかのタスクへのコメント
              <td><a href=#todos>TODO リスト</a>の<a href=#objects>項目</a>への<a href=#object-comments>コメント</a>
              <td>
                投稿日時はインポート時点となります
                (はてなグループから取得できないため)。
            <tr>
              <td>ファイル
              <td><a href=#fileset-file>ファイルフォルダー</a>のファイル
              <td>
                ファイル一覧の読み取り権限がある場合のみ。
        </table>

        <p>グループ日記は、「日記モード」と 「日記モード・見出し別ページ」
        のどちらを使っている場合でも、見出し単位ではなく日単位で
        Gruwa の<a href=#objects>記事</a>に変換します。
        これははてなグループ側で記事が日単位のデータとして保存されているための制約です。

        <hr>

        <p>インポートはグループの設定ページから実行できます。
        はてなグループのインポートしたいグループのトップページで、
        ブックマークレットを実行してください。
        操作方法の詳細は、設定ページをご覧ください。

        <p>インポート完了まで、数分から数十分の時間が必要です
        (グループの規模により変化します)。処理中は Gruwa
        とはてなグループを Web ブラウザーで表示したままお待ちください。

        <p>インポートは、 Chrome のシークレットウィンドウでは動作しません。

        <p>はてなグループからのインポートは、
        十分な機能が公式に提供されていないため、
        ブックマークレットにより Web 
        ブラウザー内で通信することで実現しています。
        ブックマークレットを実行した Web ページは、
        他のページに遷移するまで、 Gruwa 
        から情報を取得できる状態になっています。

        <p>はてなグループの仕様により、
        インポートできる情報は、
        どのはてなIDでログインしている状態かによって変化します。

          <ul>

          <li>グループ日記やキーワードのソース (はてな記法のテキスト)
          は、編集権限があるはてなIDでのアクセス時のみ取得できます。
          編集権限がない場合には、 HTML に変換された状態でインポートします。
          (ただしグループ日記へのアクセス権限がない場合には、
          その日記はスキップします。)

          <li>キーワードの編集履歴は、
          キーワードの編集権限があるはてなIDでのアクセス時のみ取得できます。

          <li>スターコメントは、はてなスターの仕様で定められた条件を満たすはてなIDでのアクセス時のみ取得できます。

          <li>編集権限があるグループ日記からのインポートでは、
          日へのコメントがはてなIDを持つ利用者によるものか、
          そうでない利用者によるものかの区別が失われます
          (どちらもはてなIDではなく利用者名としてインポートされます)。
          (編集権限があってもどちらか判断することは不可能ではありませんが、
          はてなグループへのアクセス数の削減のため省略しています。)

          <li>ファイルのインポートは、
          ファイル一覧の読み取り権限が必要です。
          有料オプションを解約すると読み取り権限が剥奪されるのでご注意ください。

          </ul>

        <p>既にインポートしたことのあるグループを再度インポートする場合、
        変更があった部分のみ Gruwa に保存します。
        他のはてなIDで取得できなかった部分も、
        できるだけ生に近いものを保存します。
        (例えば編集権限のないはてなIDで HTML をインポートした後、
        編集権限のあるはてなIDでインポートすると、
        はてな記法のテキストで改めてインポートします。)

        <p>まずすべてのグループ日記の編集権限を持ったはてなIDでインポートしてから、
        全グループメンバーのはてなIDで順にインポートを実行していくと、
        最も情報損失なくインポートできると思われます。

        <p>しかしはてなグループの仕様上、
        変更を確実に検出することが難しいため、
        一旦インポートした後の差分更新や編集履歴のインポートは補助的なものとお考えください。
        キーワードやコメントの削除にも追随できません。
        同じ名前のファイルの内容差し替えは、別ファイルとなります。

        <hr>

        <p>はてなグループのはてな記法の詳細な仕様は公表されていないため、
        Gruwa の<a href=https://github.com/wakaba/Text-Hatena>はてな記法の解釈</a>と細部において異なっていることがあります
        (Gruwa の<a href=https://github.com/wakaba/Text-Hatena>はてな記法の解釈</a>は、はてなブログに近いものです)。
        
        <p>キーワードの自動リンクには対応していません。
        ただし、編集権限がなく (はてな記法でなく) HTML 
        としてインポートした場合には、元の自動リンクを保持したままとなります。

        <p>グループ内のリンクは、インポートされた Gruwa
        内のページへのリンクへ書き換えられます。
        グループ内のファイル (画像を含みます。) へのリンクや埋め込みも、
        Gruwa 内のものに書き換えられます。
        ただし、他のグループへのリンクやはてなフォトライフの画像へのリンクは書き換えられないので注意してください。

        <p><code>iframe</code> の URL が <code>http<strong>s</strong>:</code>
        ではなく <code>http:</code> である場合など、
        そのままでは正しく表示されないものもあります。

        <p>はてなグループでは日の見出しにカテゴリーを記入できますが、 Gruwa 
        には<a href=#objects>記事</a>の見出しにカテゴリーを付与する機能がないないため、
 
        単なる見出しの一部分として扱われます。

        <hr>

        <p>インポートにより作成された<a href=#objects>記事</a>の編集<a href=#accounts>アカウント</a>は、
        インポートを実行した<a href=#accounts>アカウント</a>となります。
        作成者のはてなIDがわかるコメントなどは、
        その情報も保存します。グループ日記の記事は、
        (編集権限を持った他の人が作成した可能性もありますが)
        日記のはてなIDを作成者とみなして保存します。

        <p><a href=#objects>記事</a>の作成や変更の日時は、
        インポートを実行した日時となります。
        表示に使われる日時
        (<a href=#blogs>日記</a>ページの日付や一覧での順序などに使う日時)
        は、はてなグループ側の日時を (取得可能なら) 利用します。

        <p>はてなグループの「テーマ」の設定は、
        可能なら相当する<a href=#theme>配色</a>の指定に置き換えます。
        多くの「テーマ」には相当する<a href=#theme>配色</a>があります。
        ただし、相当する<a href=#theme>配色</a>があってもはてなグループと同じ表示にはなりません。
        一部正しく表示できないものもあります。

        <p>グループ日記のテーマは、
        <a href=#blogs>日記</a>の<a href=#theme>配色</a>となります。
        グループ全体のテーマは、
        <a href=#wikis>Wiki</a> と
        <a href=#todos>TODO リスト</a>の<a href=#theme>配色</a>となります。
        
      </section>

      <section id=import-bitbucket>
        <h1>Bitbucket からのインポート</h1>

        <p><a href=https://bitbucket.org/>Bitbucket</a>
        の特定のリポジトリーの Issues を Gruwa グループの 
        <a href=#todos>TODO リスト</a>としてインポートする機能です。

        <ul>
          <li>Issue の title と description は、<a href=#todos>TODO 
          リスト</a>の項目の題名と本文となります。

          <li>Issue の status が new, open, on hold のとき未完了、
          それ以外のとき完了済として扱います。

          <li>Issue の reporter, assignee, kind, priority, status
          は内部情報として保持しますが、画面には表示されません。

          <li>Issue の attachment, votes, watcher はインポートしません。

          <li>Issue のコメントは、 <a href=#todos>TODO リスト</a>の項目へのコメントとなります。

          <li>状態変更・編集の履歴は、インポートできません。

          <li>Issue とコメントの本文は Markdown として扱いますが、
          再編集できません (再編集時に他の形式に変更する必要があります)。

        </ul>

        <p>Issues 以外 (ソースコード、Wiki など) には<strong>対応していません</>。

        <hr>

        <p>インポートはグループの設定ページから実行できます。
        ページ内でリポジトリーを選択して「インポート開始」
        ボタンを押してください。

        <p>Bitbucket からの情報の取得には OAuth を用いた Web API
        を使っています。 OAuth によって取得したアクセス許可は、
        インポートにのみ利用しています。情報取得のみで、
        Bitbucket 側への書き込みは行いません。

        <p>インポート完了まで、数分から数十分の時間が必要です 
        (リポジトリーの規模により変化します)。処理中は Gruwa
        を Web ブラウザーで表示したままお待ちください。

        <hr>

        <p>既にインポートしたことのあるリポジトリーを再度インポートする場合、
        変更があった部分のみ Gruwa に保存します。
        しかし変更を検出できない場合もあるため、
        一旦インポートした後の差分更新は補助的なものとお考えください。

        <p>インポートにより作成された<a href=#objects>記事</a>の編集<a href=#accounts>アカウント</a>は、
        インポートを実行した<a href=#accounts>アカウント</a>となります。 
        <a href=#objects>記事</a>の作成や変更の日時は、
        インポートを実行した日時となります。
        表示に使われる日時は、 Bitbucket 側の日時となります。

      </section>

    </section>

    <section id=privacy>
      <h1>プライバシーについて</h1>

      <p>個人情報その他の情報の取り扱いは、
      <a href=/terms#privacy>プライバシーポリシー</a>に定めるところによります。

      <p>Gruwa では次の情報を扱います。

      <dl>

        <div>
          <dt>アクセスした者の IP アドレス、
          利用者エージェントの識別子、
          アクセスの日時
          <dd>サービスの利用の状況を記録し一定期間保持します。
          サービスに対する攻撃の防止など、
          サービスの正常な稼働を維持するために使用します。
          <dd><a href=#accounts>アカウント</a>に関する重要な操作について適宜記録し、
          利用者自身の便宜や不正利用の防止のため、
          当該<a href=#accounts>アカウント</a>自身による閲覧に供します。
          <dd><a href=#groups>グループ</a>内での操作について適宜記録し、
          監査のため当該<a href=#groups>グループ</a>の<a href=#owner>所有者</a>による閲覧に供します。
        </div>

        <div>
          <dt>ログインに使用した他のサービスのプロフィール
          (他のサービスにおける識別子、名前、
          画像、メールアドレス)
          <dd><a href=#accounts>アカウント</a>の作成や識別のために使用、
          記録します。
          <dd>サービスに対する攻撃の防止など、
          サービスの正常な稼働を維持するために使用します。
          <dd>当該<a href=#accounts>アカウント</a>自身に対する<a href=#accounts>アカウント</a>情報の表示のため使います。
        </div>

        <div>
          <dt>メールアドレス
          (直接登録されたもの、他のサービスのプロフィールから自動登録されたもの)
          <dd>サービスからの通知メールの送信に使います。
          <dd>サービス運営者から利用者への連絡に使います。
        </div>

        <div>
          <dt>デスクトップ/スマートフォン通知の通知先
          <dd>サービスからの通知の送信に使います。
        </div>

        <div>
          <dt><a href=#import>インポート</a>に使用した他のサービスのプロフィール
          (他のサービスにおける識別子、名前)
          <dd><a href=#import>インポート</a>に使用します。
          完了後に破棄します。
        </div>
        
      </dl>
      
    </section>

    <section>
      <h1>お知らせ</h1>

      <p>Gruwa の新機能や変更点のご紹介や、
      サービスの運営に関するご案内は、
      <a href=/news>お知らせ</a>にて行います。
        
    </section>
    
  </section>

<!--

Copyright 2016-2020 Wakaba <wakaba@suikawiki.org>.

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
