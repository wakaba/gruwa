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
  
<body>
  <header class=page>
    <h1><a href=/>Gruwa</a></h1>
  </header>

  <section>
    <header class=section>
      <h1>ログイン</h1>
      <a href=/help#accounts target=help>ヘルプ</a>
    </header>
  
    <form method=post action=/account/agree referrerpolicy=origin class=transparent>
      <t:my as=$next x="$app->text_param ('next')">
      <t:if x="defined $next">
        <input type=hidden name=next pl:value=$next>
      </t:if>

      <p>続行するには、 Gruwa の利用規約にご同意いただく必要があります。

      <p class="operations main-button-container">
        <a href=/terms class=main-button target=help>利用規約</a>

      <p><label>
        <input type=checkbox name=agree value=1 required>
        利用規約に同意する
      </label></p>

      <t:if x="$app->bare_param ('disagree')">
        <p>[開発者用]
        <label>
          <input type=checkbox name=disagree value=1>
          利用規約への同意を取り消す
        </label>
      </t:if>

      <p class=operations>
        <button type=submit class=save-button>続行する</button>
    </form>

  </section>
  <script>
    if (window.top !== window) {
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
