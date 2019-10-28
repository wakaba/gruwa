<html t:params="$app $servers"
    data-theme=green
>
<head>
  <base target=_top>
  <!-- XXX until browsers support <form referrerpolicy=""> -->
  <meta name=referrer content=origin>
  <!--<meta name=referrer content=no-referrer>-->
  <meta name=robots content="NOINDEX,NOFOLLOW,NOARCHIVE">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name=theme-color content="green">
  <link rel=stylesheet pl:href="'/css/common.css?r='.$app->rev">
  <title>ログイン - Gruwa</title>
  <t:if x="$app->bare_param ('done')">
    <script>
      if (window.opener)
      window.opener.top.postMessage ({grAccountUpdated: true});
      window.close ();
    </script>
  </t:if>
  
<body>
  <header class=page>
    <h1><a href=/>Gruwa</a></h1>
  </header>

  <section>
    <header class=section>
      <h1>ログイン</h1>
      <a href=/help#accounts target=help>ヘルプ</a>
    </header>
  
    <form method=post action=/account/login referrerpolicy=origin class=transparent>
    <t:my as=$next x="$app->text_param ('next')">
    <t:if x="defined $next">
      <input type=hidden name=next pl:value=$next>
    </t:if>
    <ul class=main-menu-list>
      <t:for as=$server x=$servers>
        <li>
          <button type=submit name=server pl:value=$server>
            <t:text value="{
              google => 'Google',
              github => 'GitHub',
            }->{$server} || $server"> のアカウントでログイン
          </button>
      </t:for>
    </ul>
    </form>

    <ul class=notes>
      <li><a href=/>Gruwa</a> はグループ活動のためのツール (グループウェア)
      です。詳しくは<a href=/help target=help>ヘルプ</a>をご覧ください。
      <li>初めての方もこのまま先へお進みいただけます。
      <li>Gruwa のご利用には、
      <a href=/terms target=help>利用規約</a>への同意が必要です。
      <li>利用者アカウントの識別のためにクッキーを使用します。
      <li>ログインに使ったサービスに、 Gruwa が無断で投稿することはありません。
    </ul>
  </section>
  <script>
    if (window.top !== window) {
      document.querySelector ('form').target = 'login' + Math.random ();
      document.documentElement.classList.add ('page-in-iframe');
    }
  </script>
  
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
