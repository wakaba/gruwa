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
      <t:if x="defined $tag">
        <h1><a pl:href="'/g/'.$group->{group_id}.'/t/'.(Web::URL::Encoding::percent_encode_c $tag).'/'">
          <tag-name><t:text value="$tag"></>
        </a></h1>
      <t:elsif x="defined $index">
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
      <t:else>
        <h1><a pl:href="'/g/'.$group->{group_id}.'/'">
          <t:text value="$group->{title}">
        </a></h1>
      </t:if>
    </header>

    <t:if x="defined $tag and defined $group->{options}->{default_keyword_index_id}">
      <list-container listitemtype=object key=objects
          pl:src-index_id="$group->{options}->{default_keyword_index_id}"
          pl:src-wiki_name=$tag>
        <template class=object>
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

        <list-is-empty>
          <article class="object new">
            <p class=operations>
              <button type=button class=edit-button><tag-name><t:text value=$tag></>の記事を書く</button>
          </article>
        </list-is-empty>

        <list-main></list-main>

        <action-status hidden stage-load=読み込み中... />
      </list-container>
    </t:if>

    <section>
      <t:if x="defined $tag and defined $group->{options}->{default_keyword_index_id}">
        <h1><tag-name><t:text value="$tag"></>の記事</h1>
      </t:if>

    <list-container listitemtype=object grouped key=objects>
      <t:if x="defined $object">
        <t:attr name="'src-object_id'" value="$object->{object_id}">
      <t:elsif x="defined $tag">
        <t:attr name="'src-tag'" value=$tag>
      <t:elsif x="defined $index">
        <t:attr name="'src-index_id'" value="$index->{index_id}">
      </t:if>
      <t:if x="defined $tag and defined $group->{options}->{default_keyword_index_id}">
        <t:attr name="'src-excluded_ptag'" value="$tag">
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

      <t:if x="defined $index and not defined $object and not defined $tag">
        <article class="object new">
          <p class=operations>
            <button type=button class=edit-button>新しい記事を書く</button>
        </article>
      </t:if>

      <list-main></list-main>

      <action-status hidden stage-load=読み込み中... />
      <p class=operations>
        <button type=button class=next-page-button hidden>もっと昔</button>
    </list-container>

      <t:if x="defined $tag and defined $group->{options}->{default_keyword_index_id}">
        <p><a pl:href="'/g/'.$group->{group_id}.'/search?q=' . Web::URL::Encoding::percent_encode_c $tag">「<t:text value=$tag>」を含む記事を検索する</a>
      </t:if>
    </section>

  </section>

  <t:include path=_object_editor.html.tm />

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
