<html t:params="$app $servers">
<head>
  <!-- XXX until browsers support <form referrerpolicy=""> -->
  <meta name=referrer content=origin>
  <!--<meta name=referrer content=no-referrer>-->
  <meta name=robots content="NOINDEX,NOFOLLOW,NOARCHIVE">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link rel=stylesheet pl:href="'/css/common.css?r='.$app->rev">
  <title>ログイン - Gruwa</title>

<body>
  <h1>ログイン</>

<form method=post action=/account/login referrerpolicy=origin>
  <t:my as=$next x="$app->text_param ('next')">
  <t:if x="defined $next">
    <input type=hidden name=next pl:value=$next>
  </t:if>
  <ul>
    <t:for as=$server x=$servers>
      <li>
        <button type=submit name=server pl:value=$server>
          <t:text value=$server> のアカウントでログイン
        </button>
    </t:for>
  </ul>
</form>

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
