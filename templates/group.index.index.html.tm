<html t:params="$group $index? $object? $wiki_name? $account $group_member $app"
    pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-index="defined $index ? $index->{index_id} : undef"
    pl:data-theme="(defined $index && defined $index->{options}->{theme})
                       ? $index->{options}->{theme}
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
      <t:if x="defined $wiki_name">
        <t:text value=$wiki_name> -
      </t:if>
      <t:text value="$index->{title}">
    </t:if>
  </t:include>

<body>
  <!-- XXX beforeunload -->
  <t:include path=_group_header.html.tm m:group=$group m:account=$account m:group_member=$group_member m:app=$app />

  <section class=page>
    <header>
      <t:if x="defined $wiki_name">
        <h1><t:text value=$wiki_name></h1>
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

    <list-container key=objects>
      <t:if x="defined $object">
        <t:attr name="'src-object_id'" value="$object->{object_id}">
      <t:elsif x="defined $index">
        <t:attr name="'src-index_id'" value="$index->{index_id}">
      </t:if>
      <t:if x="defined $wiki_name">
        <t:attr name="'src-wiki_name'" value=$wiki_name>
        <t:attr name="'sortkey'" value="'created'">
      <t:else>
        <t:if x="defined $index and $index->{index_type} == 1 # blog">
          <t:attr name="'grouped'" value=1>
        <t:elsif x="defined $index and $index->{index_type} == 2 # wiki">
          <t:attr name="'sortkey'" value="'updated'">
        <t:elsif x="defined $index and
                    ($index->{index_type} == 3 or # todo
                     $index->{index_type} == 4 or # label
                     $index->{index_type} == 5) # milestone">
          <t:attr name="'sortkey'" value="'updated'">
        <t:else>
          <t:attr name="'sortkey'" value="'created'">
        </t:if>
      </t:if>
      <t:if x="not defined $wiki_name and
               defined $index and $index->{index_type} == 2 # wiki">
        <t:attr name="'src-limit'" value=100>
        <template>
          <p><a data-href-template={GROUP}/i/{INDEX_ID}/wiki/{title}#{object_id}>
            <strong data-data-field=title data-empty=■ />
            <time data-field=created class=ambtime />
            (<time data-field=updated class=ambtime /> 編集)
          </a></p>
        </template>
      <t:elsif x="not defined $wiki_name and
                  defined $index and
                  ($index->{index_type} == 3 or # todo
                   $index->{index_type} == 4 or # label
                   $index->{index_type} == 5) # milestone">
        <t:attr name="'src-limit'" value=100>
        <t:attr name="'type'" value="'table'">
        <t:attr name="'query'" value="''">
        <template>
          <td>
            <todo-state data-data-field=todo_state label-1=未完了 label-2=完了済 />
            <span data-if-data-field=all_checkbox_count>
              <span data-data-field=checked_checkbox_count data-empty=0 /> /
              <span data-data-field=all_checkbox_count />
            </span>
          <th scope=row>
            <a data-href-template={GROUP}/o/{object_id}/>
              <span data-data-field=title data-empty=■ />
            </a>
          <td>
            <time data-field=created class=ambtime />
            (<time data-field=updated class=ambtime /> 編集)
          <td title=担当者>
            <account-list data-data-field=assigned_account_ids />
        </template>
      <t:else><!-- index_type == 1 (blog), wiki page, object permalink -->
        <t:attr name="'listitemtype'" value="'object'">
        <template class=object>
          <header>
            <div class=edit-by-dblclick>
              <h1><a data-data-field=title data-empty=■ data-href-template={GROUP}/o/{object_id}/ /></h1>
            </div>
            <todo-state data-data-field=todo_state label-1=未完了 label-2=完了済 />
          </header>
          <main><iframe data-data-field=body /></main>
          <footer>
            <p>
              <action-status hidden
                  stage-edit=保存中...
                  ok=保存しました />
              <span data-if-data-non-empty-field=assigned_account_ids>
                担当者:
                <account-list data-data-field=assigned_account_ids />
              </span>
              <index-list data-data-field=index_ids />
              <time data-field=created class=ambtime />
              (<time data-field=updated class=ambtime /> 編集)
              <button type=button class=edit-button>編集</button>
          </footer>
          <div class=actions>
            <div data-if-data-field=todo_state data-if-value=1>
              <form action=javascript: data-data-action-template=o/{object_id}/edit.json>
                <input type=hidden name=todo_state value=2 class=data-field>
                <p><button type=submit class=save-button>完了</button>
                  <action-status hidden
                      stage-fetch=変更中... />
              </form>
            </div>
            <div data-if-data-field=todo_state data-if-value=2>
              <form action=javascript: data-data-action-template=o/{object_id}/edit.json>
                <input type=hidden name=todo_state value=1 class=data-field>
                <p><button type=submit class=save-button>未完了に戻す</button>
                  <action-status hidden
                      stage-fetch=変更中... />
              </form>
            </div>
          </div>
        </template>
      </t:if>

      <t:if x="defined $index and
               not defined $object and
               not defined $wiki_name and
               ($index->{index_type} == 1 or # blob
                $index->{index_type} == 2 or # wiki
                $index->{index_type} == 3) # todo">
        <article class="object new">
          <p class=operations>
            <button type=button class=edit-button>新しい記事を書く</button>
        </article>
      </t:if>

      <t:if x="not defined $wiki_name and
               defined $index and
               ($index->{index_type} == 3 or # todo
                $index->{index_type} == 4 or # label
                $index->{index_type} == 5) # milestone">
        <menu>
          <list-query>
            <list-control name=todo_state key=todo_states list=todo-state-list>
              <template>
                <list-item-label data-field=label />
              </template>
              <list-control-main />
              <list-control-footer>
                <button type=button class=edit-button title=編集>...</button>
                <list-dropdown hidden />
              </>
              <datalist id=todo-state-list data-loaded>
                <option label=未完了 value=1>
                <option label=完了済 value=2>
              </datalist>
            </list-control>
            <list-control name=assigned_account_id key=assigned_account_ids list=member-list>
              <template>
                <list-item-label data-field=label />
              </template>
              <list-control-main />
              <list-control-footer>
                <button type=button class=edit-button title=編集>...</button>
                <list-dropdown hidden />
              </>
            </list-control>
          </list-query>

          <button type=button class=reload-button hidden>再読込</button>
        </menu>

        <table>
          <tbody>
        </table>
      <t:else>
        <list-main></list-main>
      </t:if>

      <t:if x="defined $wiki_name">
        <list-is-empty hidden>
          <p>記事はまだありません。</p>

          <article class="object new">
            <p class=operations>
              <button type=button class=edit-button>記事を書く</button>
          </article>
        </list-is-empty>
      </t:if>

      <action-status hidden stage-load=読み込み中... />
      <t:if x="not defined $wiki_name">
        <p class=operations>
          <button type=button class=next-page-button hidden>もっと昔</button>
      </t:if>
    </list-container>


    <t:if x="defined $wiki_name">
      <footer>
        <p><a pl:href="'/g/'.$group->{group_id}.'/search?q=' . Web::URL::Encoding::percent_encode_c $wiki_name">「<t:text value=$wiki_name>」を含む記事を検索する</a></p>
      </footer>
    </t:if>
  </section>

  <t:include path=_object_editor.html.tm />

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
