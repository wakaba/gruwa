<html t:params="$group_title $app"
    pl:data-env="$app->config->{env_name}"
    data-theme=green>
  <head>
    <t:include path=_other_head.html.tm m:app=$app m:needreferrer=1>
      グループに参加 - <t:text value=$group_title>
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
    <a href=/help target=help>ヘルプ</a>
  </header-area>
</header>

  <section>
    <h1><t:text value="$group_title"></h1>

    <form method=post action=./ referrerpolicy=origin>
      <p>グループ「<t:text value="$group_title">」に参加しますか?

      <p class=operations>
        <a pl:href="'/account/login?next=' . Web::URL::Encoding::percent_encode_c $app->http->url->stringify" class=button>進む</a>
        <button type=submit class=save-button hidden>参加する</button>
        <!-- XXX -->
        <script>
          fetch ('/my/info.json', {credentials: 'same-origin', referrerPolicy: 'origin'}).then (function (res) {
            return res.json ();
          }).then (function (json) {
            if (json.account_id) {
              $$ (document, '.operations a.button').forEach (function (e) { e.hidden = true });
              $$ (document, '.operations [type=submit]').forEach (function (e) { e.hidden = false });
            }
          });
        </script>
    </form>

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
