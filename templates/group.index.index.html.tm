<html t:params="$group $index? $object? $tag? $account $group_member $app"
    pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-index="defined $index ? $index->{index_id} : undef"
    data-body-css-href=/css/body.css
    pl:data-theme="defined $index ? $index->{options}->{theme}
                                  : $group->{options}->{theme}">
<head>
  <t:include path=_group_head.html.tm m:group=$group m:account=$account m:app=$app>
    <t:if x="defined $object">
      <t:text value="
        my $title = $object->{data}->{title};
        length $title ? $title : '■';
      ">
      <t:if x="defined $index">
        - <t:text value="$index->{title}">
      </t:if>
    <t:elsif x="defined $index">
      <t:text value="$index->{title}">
    <t:elsif x="defined $tag">
      #<t:text value=$tag>
    </t:if>
  </t:include>

<body>
  <!-- XXX beforeunload -->
  <t:include path=_group_header.html.tm m:group=$group m:account=$account m:group_member=$group_member m:app=$app />

  <section class=page>
    <header>
      <t:if x="defined $index">
        <h1><a pl:href="'/g/'.$group->{group_id}.'/i/'.$index->{index_id}.'/'">
          <t:text value="$index->{title}">
        </a></h1>
        <nav>
          <a pl:href="'/g/'.$group->{group_id}.'/i/'.$index->{index_id}.'/'">
            <t:if x="not defined $object">
              <t:class name="'active'">
            </t:if>
            トップ
          </a>
          /
          <a pl:href="'/g/'.$group->{group_id}.'/i/'.$index->{index_id}.'/config'">
            設定
          </a>
        </nav>
      <t:elsif x="defined $tag">
        <h1><a pl:href="'/g/'.$group->{group_id}.'/t/'.(Web::URL::Encoding::percent_encode_c $tag).'/'">
          <t:text value="$tag">
        </a></h1>
      <t:else>
        <h1><a pl:href="'/g/'.$group->{group_id}.'/'">
          <tag-name><t:text value="$group->{title}"></>
        </a></h1>
      </t:if>
    </header>

<template id=edit-form-template>
  <form method=post action=javascript:>
    <header>
      <p><input name=title placeholder=題名>
      <p><list-control name=tag key=tags list=tag-list allowadd>
        <input type=hidden name=edit_tag value=1>
        <template>
          <list-item-label data-field=value />
        </template>
        <list-control-main placeholder=タグ />
        <list-control-footer>
          <button type=button class=edit-button title=編集>...</button>
          <list-dropdown hidden />
        </list-control-footer>
      </list-control>
    </header>
    <main>
      <menu>
        <button type=button data-action=execCommand data-command=bold title=太字><b>B</b></button
        ><button type=button data-action=execCommand data-command=italic title=斜体><i>I</i></button
        ><button type=button data-action=execCommand data-command=underline title=下線><u>U</u></button
        ><button type=button data-action=execCommand data-command=strikethrough title=取り消し線><s>S</s></button>
        <button type=button data-action=execCommand data-command=superscript title=上付き><var>x</var><sup>2</sup></button
        ><button type=button data-action=execCommand data-command=subscript title=下付き><var>x</var><sub>2</sub></button>

        <button type=button data-action=setBlock data-value=div title=段落>¶</button
        ><button type=button data-action=setBlock data-value=ol title=順序>1.</button
        ><button type=button data-action=setBlock data-value=ul title=箇条書き>◦</button>

        <!--<button type=button data-action=insertSection title=章節>§</button>-->

        <button type=button data-action=outdent title=浅く>←</button
        ><button type=button data-action=indent title=深く>→</button>

        <button type=button data-action=insertControl data-value=checkbox title=チェック項目>☑</button>
      </menu>
      <iframe class=control data-name=body />
      <input type=hidden name=body_type value=1>
    </main>
    <footer>
      <p class=operations>
        <button type=submit class=save-button>保存する</button>
        <button type=button class=cancel-button>取り消し</button>
        <action-status hidden
            stage-create=作成中...
            stage-edit=保存中...
            stage-update=更新中... />
    </footer>
    <details>
      <summary>詳細設定</>
      <table class=config>
        <tbody>
          <tr>
            <th>日付
            <td><input type=date name=timestamp required>
          <tr>
            <th>日記
            <td>
              <list-control name=index_id key=index_ids list=index-list>
                <input type=hidden name=edit_index_id value=1>
                <template>
                  <list-item-label data-field=label />
                </template>
                <list-control-main />
                <list-control-footer>
                  <button type=button class=edit-button title=編集>...</button>
                  <list-dropdown hidden />
                </list-control-footer>
              </list-control>
      </table>
    </details>
  </form>
</template>

    <template id=link-edit-template class=body-edit-template>
      <a href data-href-field=href class=open-button target=_blank rel="noreferrer noopener"><code data-field=host data-title-field=href></code></a>
      <button type=button class=edit-button data-prompt=リンク先のURLを指定してください。 title=リンク先を編集>編集</button>
    </template>

    <list-container listitemtype=object grouped key=objects>
      <t:if x="defined $object">
        <t:attr name="'object'" value="$object->{object_id}">
      <t:elsif x="defined $tag">
        <t:attr name="'tag'" value=$tag>
      <t:elsif x="defined $index">
        <t:attr name="'index'" value="$index->{index_id}">
      </t:if>
      <template class=object>
        <header>
          <div class=edit-by-dblclick>
            <h1><a data-data-field=title data-empty=■ data-href-template={GROUP}/o/{object_id}/ /></h1>
            <tag-list data-data-field=tags />
          </div>
        </header>
        <main><iframe data-data-field=body /></main>
    <footer>
      <p>
        <action-status hidden
            stage-edit=保存中...
            ok=保存しました />
        <index-list data-data-field=index_ids />
        <time data-field=created class=ambtime />
        (<time data-field=updated class=ambtime /> 編集)
        <button type=button class=edit-button>編集</button>
    </footer>
  </template>

      <t:if x="defined $index and not defined $object">
        <article class="object new">
          <p class=operations>
            <button type=button class=edit-button>新しい記事</button>
        </article>
      </t:if>

      <list-main></list-main>

      <action-status hidden stage-load=読み込み中... />
      <p class=operations>
        <button type=button class=next-page-button hidden>もっと昔</button>
    </list-container>

  </section>

  <list-container type=datalist src=i/list.json key=index_list>
    <template data-label=title data-value=index_id>
    </template>
    <datalist id=index-list />
  </list-container>

  <list-container type=datalist src=i/list.json key=index_list><!-- XXX -->
    <template data-label=title data-value=title>
    </template>
    <datalist id=tag-list />
  </list-container>

  <template id=list-control-editor>
    <template>
      <label>
        <input type=checkbox data-checked-field=selected>
        <span data-field=label></span>
      </label>
    </template>
    <form hidden class=add-form>
      <span>
        <input required>
      </span>
      <span>
        <button type=submit class=add-button title=追加>+</>
      </span>
    </form>
    <list-editor-main />
  </template>

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
