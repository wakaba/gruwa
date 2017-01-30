<html t:params="$group $index? $object? $wiki_name? $account $group_member $app"
    pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-index="defined $index ? $index->{index_id} : undef"
    pl:data-theme="(defined $index && defined $index->{options}->{theme})
                       ? $index->{options}->{theme}
                       : $group->{data}->{theme}">
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
          <t:text value="$group->{data}->{title}">
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
        <t:attr name="'query'" value="''">
        <t:class name="'todo-list'">
        <template>
          <todo-state data-data-field=todo_state label-1=未完了 label-2=完了済 />
          <p class=main-line>
            <a data-href-template={GROUP}/o/{object_id}/>
              <span data-data-field=title data-empty=■ />
            </a>
          <p class=info-line>
            <checkbox-count data-if-data-field=all_checkbox_count>
              <span>
                <count-value data-data-field=checked_checkbox_count data-empty=0 /> /
                <count-value data-data-field=all_checkbox_count />
              </span>
              <progress data-data-field=checked_checkbox_count data-max-data-field=all_checkbox_count />
            </checkbox-count>
            <time data-field=created class=ambtime />
            (<time data-field=updated class=ambtime /> 編集)
            <index-list data-data-field=index_ids filters='[{"key": ["index_type"], "value": "5"}]' title=里程標 />
            <index-list data-data-field=index_ids filters='[{"key": ["index_type"], "value": "4"}]' title=ラベル />
            <account-list data-data-field=assigned_account_ids title=担当者 />
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

          <article-comments>

            <list-container class=comment-list
                data-src-template="o/get.json?parent_object_id={object_id}&limit=5&with_data=1"
                key=objects sortkey=timestamp,created prepend
                template-selector=object>
              <template>
                <article itemscope itemtype=http://schema.org/Comment>
                  <header>
                    <a href data-href-template="{GROUP}/o/{object_id}/" class=timestamp>
                      <time data-field=created class=ambtime />
                      (<time data-field=updated class=ambtime />)
                    </a>
                  </header>
                  <main><iframe data-data-field=body /></main>
                </article>
              </template>
              <template data-name=close>
                <p><!-- XXX が -->閉じました。
                (<time data-field=created class=ambtime />)
              </template>
              <template data-name=reopen>
                <p><!-- XXX が -->開き直しました。
                (<time data-field=created class=ambtime />)
              </template>
              <template data-name=changed>
                <p><!-- XXX が -->
                変更しました。
                <!--
                <index-list data-field=data.body_data.new.index_ids />
                を追加しました。

                <index-list data-field=data.body_data.old.index_ids />
                を削除しました。

                <index-list data-field=data.body_data.new.assigned_account_ids />
                に割り当てました。

                <index-list data-field=data.body_data.old.assigned_account_ids />
                への割当を削除しました。
                -->
                (<time data-field=created class=ambtime />)
              </template>
              <p class="operations pager">
                <button type=button class=next-page-button hidden>もっと昔</button>
              </p>
              <action-status hidden stage-load=読み込み中... />
              <list-main/>
            </list-container>

          <details class=actions>
            <summary>コメントを書く</summary>

            <form action=javascript: data-action=o/create.json
                data-additional-stages="editCreatedObject editObject resetForm showCreatedObjectInCommentList"
                data-child-form>
              <input type=hidden data-edit-created-object data-name=parent_object_id data-field=object_id>
              <textarea data-edit-created-object data-name=body required></textarea>
              <p class=operations>
                <button type=submit class=save-button>投稿する</>

                <button type=submit class=save-button hidden data-if-data-field=todo_state data-if-value=1 data-subform=close>投稿・完了</button>
                <input type=hidden data-edit-object data-name=object_id data-field=object_id data-subform=close>
                <input type=hidden data-edit-object data-name=todo_state value=2 data-subform=close class=data-field>

                <button type=submit class=save-button hidden data-if-data-field=todo_state data-if-value=2 data-subform=reopen>投稿・未完了に戻す</button>
                <input type=hidden data-edit-object data-name=object_id data-field=object_id data-subform=reopen>
                <input type=hidden data-edit-object data-name=todo_state value=1 data-subform=reopen class=data-field>

                <action-status hidden
                    stage-fetch=作成中...
                    stage-editcreatedobject_fetch=保存中...
                    stage-editobject_fetch=状態を変更中...
                    stage-showcreatedobjectincommentlist=読み込み中...
                    ok=投稿しました />
            </form>
          </details>

          </article-comments>
        </template>
      </t:if>

      <t:if x="defined $index and
               not defined $object and
               not defined $wiki_name">
        <t:if x="$index->{index_type} == 1 or # blob
                 $index->{index_type} == 2 # wiki">
          <article class="object new">
            <p class=operations>
              <button type=button class=edit-button>新しい記事を書く</button>
          </article>
        <t:elsif x="$index->{index_type} == 3 # todo">
          <article class="object new">
            <p class=operations>
              <button type=button class=edit-button data-focus-title>新しい TODO</button>
          </article>
        </t:if>
      </t:if>

      <t:if x="not defined $wiki_name and
               defined $index and
               ($index->{index_type} == 3 or # todo
                $index->{index_type} == 4 or # label
                $index->{index_type} == 5) # milestone">
        <menu>
          <list-query>
            <label><input type=radio name=todo value=open> 未完了</label>
            <label><input type=radio name=todo value=closed> 完了済</label>
            <label><input type=radio name=todo value=all> すべて</label>

            <list-control name=index_id key=index_ids list=index-list>
              <template data-name=view>
                <list-item-label data-data-field=title data-color-data-field=color />
              </template>
              <template data-name=edit>
                <label data-color-data-field=color>
                  <input type=checkbox data-data-field=index_id data-checked-field=selected>
                  <span data-data-field=title></span>
                </label>
              </template>
              <template data-name=edit-milestone>
                <label data-color-data-field=color>
                  <input type=radio name=MILESTONE data-data-field=index_id data-checked-field=selected>
                  <span data-data-field=title></span>
                </label>
              </template>
              <template data-name=edit-milestone-clear>
                <label>
                  <input type=radio name=MILESTONE value checked>
                  (制約なし)
                </label>
              </template>

              <list-control-list template=view filters='[{"key": ["data", "index_type"], "value": "5"}]' data-empty=(里程標制約なし) />
              <popup-menu>
                <button type=button title=選択>...</button>
                <menu hidden>
                  <form action=javascript:>
                    <list-control-list editable template=edit-milestone clear-template=edit-milestone-clear filters='[{"key": ["data", "index_type"], "value": "5"}]' />
                  </form>
                </menu>
              </popup-menu>

              <list-control-list template=view filters='[{"key": ["data", "index_type"], "value": "4"}]' data-empty=(ラベル制約なし) />
              <popup-menu>
                <button type=button title=選択>...</button>
                <menu hidden>
                  <list-control-list editable template=edit filters='[{"key": ["data", "index_type"], "value": "4"}]' />
                </menu>
              </popup-menu>
            </list-control>

            <list-control name=assigned_account_id key=assigned_account_ids list=member-list>
              <template data-name=view>
                <list-item-label data-data-account-field=name />
              </template>
              <template data-name=edit>
                <label>
                  <input type=radio name=ONE data-data-field=account_id data-checked-field=selected>
                  <span data-data-account-field=name></span>
                </label>
              </template>
              <template data-name=edit-clear>
                <label>
                  <input type=radio name=ONE value checked>
                  (制約なし)
                </label>
              </template>

              <list-control-list template=view data-empty=(担当者制約なし) />
              <popup-menu>
                <button type=button title=変更>...</button>
                <menu hidden>
                  <form action=javascript:>
                    <list-control-list editable template=edit clear-template=edit-clear />
                  </form>
                </menu>
              </popup-menu>
            </list-control>
          </list-query>

          <button type=button class=reload-button hidden>再読込</button>
        </menu>

        <template id=index-list-item-template data-name>
          <a data-href-template=./?index={index_id} data-field=title data-color-field=color class=label-index></a>
        </template>
        <template id=account-list-item-template data-name>
          <a data-href-template=./?assigned={account_id}><account-name data-field=account_id /></a>
        </template>

        <list-main/>
      <t:else>
        <template id=index-list-item-template data-name>
          <a data-href-template={GROUP}/i/{index_id}/ data-field=title data-color-field=color class=label-index></a>
        </template>
        <template id=account-list-item-template data-name>
          <account-name data-field=account_id />
        </template>

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
        <p class="operations pager">
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
