<html t:params="$group $index $group_member $account $app"
    pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-theme="(defined $index->{options}->{theme})
                       ? $index->{options}->{theme}
                       : $group->{data}->{theme}"
    data-navigating>
<head>
  <t:include path=_group_head.html.tm m:group=$group m:app=$app />

<body>
  <header class=page>
    <h1><a href=./ data-href-field=url data-field=title><t:text value="$index->{title}"></a></h1>
    <gr-menu type=index pl:value="$index->{index_id}" />
  </header>
  <page-main/>
  <gr-navigate page=index-config pl:indexid="$index->{index_id}" />
  
<template-set name=page-index-config>
  <template title=設定>
    <section>
      <h1>設定</>
      <form is=save-data data-saver=groupSaver method=post data-action-template=i/{index.index_id}/edit.json id=edit-form>
        <table class=config>
          <tbody>
            <tr>
              <th>種別
              <td>
                <enum-value data-field=index.index_type
                    label-1=日記
                    label-2=Wiki
                    label-3="TODO リスト"
                    label-4=ラベル
                    label-5=マイルストーン
                    label-6 />
                <enum-value data-field=index.subtype
                    label-image=アルバム
                    label-file=ファイルアップローダー
                    label-null />
            <tr>
              <th><label for=edit-title>名前</>
              <td><input name=title data-field=index.title id=edit-title required>
            </tr>
            <tr data-gr-if-index-type="1 2 3">
              <th>
                <label for=edit-theme>配色</>
              <td>
                <gr-select-theme name=theme data-field=index.theme>
                  <select id=edit-theme form required />
                  <gr-theme-info>
                    <strong data-field=label />
                    <code data-field=name />
                    <span data-field=author />
                    <small>
                      <span data-field=license />
                      <span data-field=copyright />
                      (<a data-href-template={url} target=_blank rel="noreferrer noopener">出典</a>)
                    </small>
                  </gr-theme-info>
              </gr-select-theme>
            <tr data-gr-if-index-type=4>
              <th><label for=edit-color>色</label>
              <td>
                <input type=color name=color data-field=index.color list=color-list>
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
            <tr data-gr-if-index-type=5>
              <th><label for=edit-deadline>締切</label>
              <td><input type=date name=deadline data-field=index.deadline>
        </table>
        <p class=operations>
          <button type=submit class=save-button>保存する</>
          <action-status hidden stage-saver=保存中... ok=保存しました。 />
      </form>

      <t:if x="defined $group_member->{data}->{default_index_id} and
               $group_member->{data}->{default_index_id} == $index->{index_id}">
        <p>この日記は<gr-account self><gr-account-name data-field=name /></>の<a href=/help#default-blog-index target=help>既定の日記</a>です。</p>
      <t:else>
        <form is=save-data data-saver=groupSaver method=post data-action-template=i/{index.index_id}/my.json data-gr-if-index-type=1>
          <p>この日記を<gr-account self><gr-account-name data-field=name /></>の<a href=/help#default-blog-index target=help>既定の日記</a>に設定できます。</p>
          <p class=operations>
            <input type=hidden name=is_default value=1>
            <button type=submit class=save-button>設定する</>
            <gr-action-status hidden stage-fetch=保存中... ok=保存しました。 />
        </form>
      </t:if>

      <t:if x="$group->{data}->{default_wiki_index_id} and
               $group->{data}->{default_wiki_index_id} == $index->{index_id}">
        <p>この Wiki は<a href=/help#default-wiki-index rel=help>グループの Wiki</a> です。</p>
      <t:else>
        <form is=save-data data-saver=groupSaver method=post action=edit.json data-gr-if-index-type=2>
          <p>この Wiki を<a href=/help#default-wiki-index rel=help>グループの Wiki</a>に設定できます。</p>
          <p class=operations>
            <input type=hidden name=default_wiki_index_id data-field=index.index_id>
            <button type=submit class=save-button>設定する</>
            <gr-action-status hidden stage-fetch=保存中... ok=保存しました。 />
        </form>
      </t:if>

      <p data-gr-if-index-type=3>ラベルやマイルストーンは、<a href=../../config>グループ設定</a>から作成できます。
    </section>
  </template>
</template-set>

  <t:include path=_common.html.tm m:app=$app />

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
