<html t:params="$group $index $group_member $account $app" pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-theme="$index->{options}->{theme}">
<head>
  <t:include path=_group_head.html.tm m:group=$group m:account=$account m:app=$app>
    設定 -
    <t:text value="$index->{title}">
  </t:include>

<body>
  <t:include path=_group_header.html.tm m:group=$group m:account=$account m:group_member=$group_member m:app=$app />

  <section class=page>
    <header>
      <h1><a href=./><t:text value="$index->{title}"></a></h1>
      <nav>
        <a href=./>トップ</a>
        / <a href=config class=active>設定</a>
      </nav>
    </header>

    <section>
      <h1>日記の設定</>
      <form action=javascript: pl:data-action="'i/'.$index->{index_id}.'/edit.json'" id=edit-form>
        <table class=config>
          <tbody>
            <tr>
              <th><label for=edit-title>日記の題名</>
              <td><input name=title pl:value="$index->{title}" id=edit-title required>
            <tr>
              <th><label for=edit-theme>配色</>
              <td>
                <select name=theme oninput=" document.documentElement.setAttribute ('data-theme', value) ">
                  <option value=green pl:selected="$index->{options}->{theme} eq 'green'?'':undef">緑
                  <option value=blue pl:selected="$index->{options}->{theme} eq 'blue'?'':undef">青
                  <option value=red pl:selected="$index->{options}->{theme} eq 'red'?'':undef">赤
                  <option value=black pl:selected="$index->{options}->{theme} eq 'black'?'':undef">黒
                </select>
        </table>
        <p class=operations>
          <button type=submit class=save-button>保存する</>
          <action-status hidden stage-fetch=保存中... ok=保存しました。 />
      </form>

      <t:if x="$group_member->{default_index_id} and
               $group_member->{default_index_id} == $index->{index_id}">
        <p>この日記は<account-name><t:text value="$account->{name}"></account-name>の既定の日記です。</p>
      <t:else>
        <form method=post action=javascript: pl:data-action="'i/'.$index->{index_id}.'/my.json'">
          <p>この日記を<account-name><t:text value="$account->{name}"></account-name>の既定の日記に設定できます。</p>
          <p class=operations>
            <input type=hidden name=is_default value=1>
            <button type=submit class=save-button>設定する</>
        </form>
      </t:if>
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
