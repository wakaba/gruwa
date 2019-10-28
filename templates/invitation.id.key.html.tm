<html t:params="$group_title $app"
    pl:data-env="$app->config->{env_name}"
    data-theme=green>
<head>
  <t:include path=_other_head.html.tm m:app=$app m:needreferrer=1>
    &#x2066;グループに参加&#x2069; - &#x2066;<t:text value=$group_title>&#x2069;
  </t:include>

<body>
  <header class=page>
    <h1><t:text value=$group_title></h1>
  </header>

  <form method=post action=./ referrerpolicy=origin is=invitation-accept>
    <p>グループ「<bdi><t:text value="$group_title"></bdi>」に参加しますか?

    <p class=operations>
      <a pl:href="'/account/login?next=' . Web::URL::Encoding::percent_encode_c $app->http->url->stringify" class="button login-button">進む</a>
      <button type=submit class=save-button hidden>参加する</button>
  </form>

  <ul class=notes>
    <li><a href=/>Gruwa</a> でグループに参加しようとしています。
    <li><a href=/>Gruwa</a> はグループ活動のためのツール (グループウェア)
    です。詳しくは<a href=/help target=help>ヘルプ</a>をご覧ください。
    <li class=no-account>参加するにはまずログイン (初めての方は初回登録)
    する必要があります。このまま先へ進んでください。
  </ul>

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
