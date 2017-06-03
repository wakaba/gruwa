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
        <h1><a href><t:text value=$wiki_name></a></h1>
        <m:wiki-menu m:group=$group m:wiki_name=$wiki_name />
      <t:elsif x="defined $index">
        <h1><a pl:href="'/g/'.$group->{group_id}.'/i/'.$index->{index_id}.'/'">
          <t:text value="$index->{title}">
        </a></h1>
        <m:index-menu m:group=$group m:index=$index />
      <t:else>
        <h1><a pl:href="'/g/'.$group->{group_id}.'/'">
          <t:text value="$group->{data}->{title}">
        </a></h1>
        <m:group-menu m:group=$group />
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
            <index-list data-data-field=index_ids filters='[{"key": ["index_type"], "value": "5"}]' title=マイルストーン />
            <index-list data-data-field=index_ids filters='[{"key": ["index_type"], "value": "4"}]' title=ラベル />
            <account-list data-data-field=assigned_account_ids title=担当者 />
        </template>
      <t:elsif x="not defined $wiki_name and
                  defined $index and
                  $index->{index_type} == 6 # fileset">
        <t:attr name="'src-limit'" value=100>
        <t:if x="($index->{options}->{subtype} // '') eq 'image'">
          <t:class name="'image-list'">
          <template>
            <popup-menu>
              <button type=button>⋁</button>
                <menu hidden>
                  <li><copy-button>
                    <a data-href-template={GROUP}/o/{object_id}/>記事URLをコピー</a>
                  </>
              </menu>
            </popup-menu>
            <figure>
              <a data-href-template={GROUP}/o/{object_id}/image data-title-data-field=title>
                <img src data-src-template={GROUP}/o/{object_id}/image>
              </a>
              <figcaption>
                <code data-data-field=file_name></code>
                <unit-number data-data-field=file_size type=bytes />
                <code data-data-field=mime_type />
                <a data-href-template={GROUP}/o/{object_id}/>
                  <time data-field=timestamp class=ambtime />
                </a>
              </figcaption>
            </figure>
          </template>
        <t:else>
          <t:class name="'file-list'">
          <template>
            <popup-menu>
              <button type=button>⋁</button>
                <menu hidden>
                  <li><copy-button>
                    <a data-href-template={GROUP}/o/{object_id}/>記事URLをコピー</a>
                  </>
              </menu>
            </popup-menu>
            <p class=main-line>
              <a data-href-template={GROUP}/o/{object_id}/file download>
                <span data-data-field=title data-empty=■ />
                <code data-data-field=file_name></code>
              </a>
            <p class=info-line>
              <unit-number data-data-field=file_size type=bytes />
              <code data-data-field=mime_type />
              <a data-href-template={GROUP}/o/{object_id}/>
                <time data-field=timestamp class=ambtime />
              </a>
          </template>
        </t:if>
      <t:else><!-- index_type == 1 (blog), wiki page, object permalink -->
        <t:attr name="'listitemtype'" value="'object'">
        <template class=object>
          <header>
            <div class=edit-by-dblclick>
              <h1><a data-data-field=title data-empty=■ data-href-template={GROUP}/o/{object_id}/ /></h1>
            </div>
            <todo-state data-data-field=todo_state label-1=未完了 label-2=完了済 />
            <popup-menu>
              <button type=button>⋁</button>
              <menu hidden>
                <li><a data-href-template={GROUP}/o/{object_id}/>記事</a>
                <li><copy-button>
                  <a data-href-template={GROUP}/o/{object_id}/>URLをコピー</a>
                </>
                <li><copy-button type=jump>
                  <a data-href-template={GROUP}/o/{object_id}/ data-title-data-field=title>ジャンプリストに追加</a>
                </>
                <li><button type=button class=edit-button>編集</button>
              </menu>
            </popup-menu>
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
          </footer>

          <article-comments>

            <list-container class=comment-list
                pl:data-src-template="'o/get.json?parent_object_id={object_id}&limit='.(defined $object ? 30 : 5).'&with_data=1'"
                key=objects sortkey=timestamp,created prepend
                template-selector=object>
              <template>
                <article itemscope itemtype=http://schema.org/Comment>
                  <header>
                    <if-defined data-if-data-field=author_name hidden>
                      <user-name>
                        <span data-data-field=author_name />
                        <if-defined data-if-data-field=author_hatena_id hidden>
                          <hatena-user>
                            <img data-src-template=https://cdn.www.st-hatena.com/users/{data.author_hatena_id:2}/{data.author_hatena_id}/profile.gif referrerpolicy=no-referrer alt>
                            <span data-data-field=author_hatena_id />
                          </hatena-user>
                        </if-defined>
                      </user-name>
                    </if-defined>

                    <a href data-href-template="{GROUP}/o/{object_id}/" class=timestamp>
                      <time data-field=timestamp class=ambtime />
                      (<time data-field=updated class=ambtime />)
                    </a>
                  </header>
                  <main><iframe data-data-field=body /></main>
                </article>
              </template>
              <template data-name=close class=change-action>
                <p><!-- XXX が -->閉じました。
                (<time data-field=created class=ambtime />)
              </template>
              <template data-name=reopen class=change-action>
                <p><!-- XXX が -->開き直しました。
                (<time data-field=created class=ambtime />)
              </template>
              <template data-name=changed class=change-action>
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
              <template data-name=trackback class=trackback>
                <time data-field=created class=ambtime />にこの記事が参照されました。
                <object-ref hidden data-field=data.body_data.trackback.object_id>
                  <a href data-href-template={GROUP}/o/{object_id}/>
                    <cite data-field=data.title data-empty=■ />
                    <body-snippet data-field=snippet />
                  </a>
                </object-ref>
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
        <t:elsif x="$index->{index_type} == 6 # fileset">
          <form action=javascript: method=post data-form-type=uploader pl:data-context="$index->{index_id}">
            <list-container type=table>
              <template>
                <td class=file-name><code data-data-field=file_name />
                <td class=file-size><unit-number data-data-field=file_size type=bytes />
                <td class=progress><action-status hidden
                        stage-create=作成中...
                        stage-upload=アップロード中...
                        stage-close=保存中...
                        stage-show=読み込み中...
                        ok=アップロード完了 />
              </template>
              <table>
                <thead>
                  <tr>
                    <th class=file-name>ファイル名
                    <th class=file-size>サイズ
                    <th class=progress>進捗
                <tbody>
              </table>
            </list-container>
            <p class=operations>
              <t:if x="($index->{options}->{subtype} // '') eq 'image'">
                <input type=file name=file multiple hidden accept=image/*>
                <button type=button name=upload-button class=edit-button>画像をアップロード...</button>
              <t:else>
                <input type=file name=file multiple hidden>
                <button type=button name=upload-button class=edit-button>ファイルをアップロード...</button>
              </t:if>
          </form>
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

              <list-control-list template=view filters='[{"key": ["data", "index_type"], "value": "5"}]' data-empty=(マイルストーン制約なし) />
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
      <run-action name=installPrependNewObjects />
    </list-container>

    <t:if x="defined $wiki_name">
      <article-comments>

        <list-container class=comment-list
            pl:src="'o/get.json?index_id=' . $index->{index_id} . '&parent_wiki_name=' . Web::URL::Encoding::percent_encode_c ($wiki_name) . '&limit=30&with_data=1'"
            key=objects sortkey=timestamp,created prepend
            template-selector=object>
          <template />
          <template data-name=trackback class=trackback>
            <time data-field=created class=ambtime />にこのWikiページが参照されました。
            <object-ref hidden data-field=data.body_data.trackback.object_id>
              <a href data-href-template={GROUP}/o/{object_id}/>
                <cite data-field=data.title data-empty=■ />
                <body-snippet data-field=snippet />
              </a>
            </object-ref>
          </template>
          <p class="operations pager">
            <button type=button class=next-page-button hidden>もっと昔</button>
          </p>
          <action-status hidden stage-load=読み込み中... />
          <list-main/>
        </list-container>
      </article-comments>

      <footer>
        <p><a pl:href="'/g/'.$group->{group_id}.'/search?q=' . Web::URL::Encoding::percent_encode_c $wiki_name">「<t:text value=$wiki_name>」を含む記事を検索する</a></p>
      </footer>
    </t:if>
  </section>

  <template class=body-template id=object-ref-template>
    <a href pl:data-href-template="'/g/'.$group->{group_id}.'/o/{object_id}/'">
      <cite data-field=data.title data-empty=■ />
      <body-snippet data-field=snippet />
    </a>
  </template>

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
