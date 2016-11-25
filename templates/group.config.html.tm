<html t:params="$group $account $app" pl:data-group-url="'/g/'.$group->{group_id}">
<head>
  <t:include path=_group_head.html.tm m:group=$group m:account=$account m:app=$app>
    設定
  </t:include>

<body>
  <t:include path=_group_header.html.tm m:group=$group m:account=$account m:app=$app m:group_nav=1 />

  <section class=page>
    <header>
      <h1><a href=./><t:text value="$group->{title}"></a></h1>
      <nav>
        <a pl:href="'/g/'.$group->{group_id}.'/'">トップ</a>
        / <a pl:href="'/g/'.$group->{group_id}.'/members'">メンバー</a>
        / <a pl:href="'/g/'.$group->{group_id}.'/config'" class=active>設定</a>
      </nav>
    </header>

    <section>
      <h1>作成</h1>

      <details>
        <summary>日記の作成</summary>

        <form method=post action=javascript: data-action=i/create.json
            data-href-template=/g/{group_id}/i/{index_id}/>
          <table class=config>
            <tbody>
              <tr>
                <th><label for=create-title>日記の題名</>
                <td><input name=title id=create-title required>
          </table>

          <p class=operations>
            <button type=submit class=save-button>作成する</>
        </form>
      </details>
    </section>
  </section>

<!--

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

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
