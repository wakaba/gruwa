<html t:params="$group $index $group_member $account $app"
    pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-theme="(defined $index->{options}->{theme})
                       ? $index->{options}->{theme}
                       : $group->{data}->{theme}">
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
      <h1>設定</>
      <form action=javascript: pl:data-action="'i/'.$index->{index_id}.'/edit.json'" id=edit-form>
        <table class=config>
          <tbody>
            <tr>
              <th>種別
              <td>
                <t:if    x="$index->{index_type} == 1"> 日記
                <t:elsif x="$index->{index_type} == 2"> Wiki
                <t:elsif x="$index->{index_type} == 3"> TODO リスト
                <t:elsif x="$index->{index_type} == 4"> ラベル
                <t:elsif x="$index->{index_type} == 5"> 里程標
                <t:else><t:text value="$index->{index_type}"></t:if>
            <tr>
              <th><label for=edit-title>名前</>
              <td><input name=title pl:value="$index->{title}" id=edit-title required>
            </tr>
            <t:if x="$index->{index_type} == 1 or
                     $index->{index_type} == 2 or
                     $index->{index_type} == 3">
              <tr>
                <th>
                  <label for=edit-theme>配色</>
                <td>
                  <select name=theme oninput=" document.documentElement.setAttribute ('data-theme', value) " id=edit-theme>
                    <option value=green pl:selected="$index->{options}->{theme} eq 'green'?'':undef">緑
                    <option value=blue pl:selected="$index->{options}->{theme} eq 'blue'?'':undef">青
                    <option value=red pl:selected="$index->{options}->{theme} eq 'red'?'':undef">赤
                    <option value=black pl:selected="$index->{options}->{theme} eq 'black'?'':undef">黒
                  </select>
            </t:if>
            <t:if x="$index->{index_type} == 4">
              <tr>
                <th><label for=edit-color>色</label>
                <td>
                  <input type=color name=color pl:value="$index->{options}->{color}" list=color-list>
                  <datalist id=color-list>
                    <option value=#800000>
                    <option value=#ff0000>
                    <option value=#800080>
                    <option value=#ff00ff>
                    <option value=#008000>
                    <option value=#00ff00>
                    <option value=#808000>
                    <option value=#ffff00>
                    <option value=#000080>
                    <option value=#0000ff>
                    <option value=#008080>
                    <option value=#00ffff>
                    <option value=#c0c0c0>
                    <option value=#808080>
                    <option value=#000000>
                  </datalist>
            </t:if>
            <t:if x="$index->{index_type} == 5">
              <tr>
                <th><label for=edit-deadline>締切</label>
                <td><input type=date name=deadline pl:value="
                  defined $index->{options}->{deadline}
                      ? Web::DateTime->new_from_unix_time ($index->{options}->{deadline})->to_date_string
                      : undef
                ">
            </t:if>
        </table>
        <p class=operations>
          <button type=submit class=save-button>保存する</>
          <action-status hidden stage-fetch=保存中... ok=保存しました。 />
      </form>

      <t:if x="defined $group_member->{data}->{default_index_id} and
               $group_member->{data}->{default_index_id} == $index->{index_id}">
        <p>この日記は<account-name><t:text value="$account->{name}"></account-name>の<a href=/help#default-blog-index rel=help>既定の日記</a>です。</p>
      <t:elsif x="$index->{index_type} == 1">
        <form method=post action=javascript: pl:data-action="'i/'.$index->{index_id}.'/my.json'">
          <p>この日記を<account-name><t:text value="$account->{name}"></account-name>の<a href=/help#default-blog-index rel=help>既定の日記</a>に設定できます。</p>
          <p class=operations>
            <input type=hidden name=is_default value=1>
            <button type=submit class=save-button>設定する</>
            <action-status hidden stage-fetch=保存中... ok=保存しました。 />
        </form>
      </t:if>

      <t:if x="$group->{data}->{default_wiki_index_id} and
               $group->{data}->{default_wiki_index_id} == $index->{index_id}">
        <p>この Wiki は<a href=/help#default-wiki-index rel=help>グループの Wiki</a> です。</p>
      <t:elsif x="$index->{index_type} == 2">
        <form method=post action=javascript: data-action=edit.json>
          <p>この Wiki を<a href=/help#default-wiki-index rel=help>グループの Wiki</a>に設定できます。</p>
          <p class=operations>
            <input type=hidden name=default_wiki_index_id pl:value="$index->{index_id}">
            <button type=submit class=save-button>設定する</>
            <action-status hidden stage-fetch=保存中... ok=保存しました。 />
        </form>
      </t:if>

      <t:if x="$index->{index_type} == 3 # todo">
        <p>ラベルや里程標は、<a href=../../config>グループ設定</a>から作成できます。
      </t:if>
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
