<html t:params="$app">
  <body>

    <gr-nav-button>
      <button type=button onclick="
        var active = ! document.querySelector ('gr-nav-button').hasAttribute ('active');
        document.querySelectorAll ('gr-nav-button, gr-nav-panel').forEach (_ => {
          if (active) {
            _.setAttribute ('active', '');
          } else {
            _.removeAttribute ('active');
          }
        });
        document.querySelector ('gr-nav-panel').focus ();
      ">三</button>
    </gr-nav-button>
    
    <gr-nav-panel tabindex=0>
      <details open>
        <summary>
          <gr-account self>
            <gr-account-name data-field=name data-filling>アカウント</>
          </gr-account>
        </summary>
        <p><a href=/dashboard>ダッシュボード</a></p>
        <hr>
        <gr-list-container src=/jump/list.json key=items>
          <template>
            <p><a href data-href-template={URL} data-ping-template=/jump/ping.json?url={HREF} data-field=label></a>
          </template>
          <list-main/>
        </gr-list-container>
        <p><a href=/jump>ジャンプリストの編集</></li>
      </details>
      <details open>
        <summary>
          <gr-group>
            <gr-group-name data-field=title data-filling>グループ</>
          </gr-group>
        </summary>
        <gr-group>
          <p><a data-href-template=/g/{group_id}/>トップ</a>
          <p class=if-has-default-index><a data-href-template=/g/{group_id}/i/{member.default_index_id}/>自分の日記</a>
          <form method=get data-action-template=/g/{group_id}/search class=search-form>
            <input type=search name=q required placeholder=グループ内検索>
            <button type=submit>検索</button>
          </form>
        </gr-group>
      </details>
      <details>
        <summary>Gruwa</summary>
        <p><a href=/help target=help>ヘルプ</a>
      </details>
    </gr-nav-panel>

    <gr-navigate-status>
      <action-status stage-loading=読込中... />
    </gr-navigate-status>

<template-set name=gr-menu>
  <template>
    <popup-menu>
      <button type=button title=メニュー>
        <button-label>
          メニュー
        </button-label>
      </button>
      <menu-main/>
    </popup-menu>
  </template>
</template-set>

<t:macro name=group-menu t:params=$group>
  <gr-popup-menu>
    <button type=button>⋁</button>
    <menu hidden>
      <li>
        <a pl:href="'/g/'.$group->{group_id}.'/'">
          トップ
        </a>
      <li><copy-button>
        <a pl:href="'/g/'.$group->{group_id}.'/'">
          URLをコピー
        </a>
      </copy-button>
      <li><copy-button type=jump>
        <a pl:href="'/g/'.$group->{group_id}.'/'" pl:title="$group->{data}->{title}">
          ジャンプリストに追加
        </a>
      </copy-button>
      <li>
        <a pl:href="'/g/'.$group->{group_id}.'/members'">
          参加者
        </a>
      <li>
        <a pl:href="'/g/'.$group->{group_id}.'/config'">
          設定
        </a>
    </menu>
  </gr-popup-menu>
</t:macro>
<template-set name=gr-menu-group>
  <template>
    <p><a data-href-template=/g/{group.group_id}/>トップ</a>
    <p><copy-button><a data-href-template=/g/{group.group_id}/>
      URLをコピー
    </a></copy-button>
    <p><copy-button type=jump>
      <a data-href-template=/g/{group.group_id}/ data-title-field=group.title>
        ジャンプリストに追加
      </a>
    </copy-button>
    <p><a data-href-template=/g/{group.group_id}/members>参加者</a>
    <p><a data-href-template=/g/{group.group_id}/config>設定</a>
    <p><a href=/help#groups target=help>ヘルプ</a>
  </template>
</template-set>

<t:macro name=index-menu t:params="$group $index">
  <gr-popup-menu>
    <button type=button>⋁</button>
    <menu hidden>
      <li>
        <a pl:href="'/g/'.$group->{group_id}.'/i/'.$index->{index_id}.'/'">
          トップ
        </a>
      <li><copy-button>
        <a pl:href="'/g/'.$group->{group_id}.'/i/'.$index->{index_id}.'/'">
          URLをコピー
        </a>
      </copy-button>
      <li><copy-button type=jump>
        <a pl:href="'/g/'.$group->{group_id}.'/i/'.$index->{index_id}.'/'" pl:title="$index->{title}">
          ジャンプリストに追加
        </a>
      </copy-button>
      <li>
        <a pl:href="'/g/'.$group->{group_id}.'/i/'.$index->{index_id}.'/config'">
          設定
        </a>
      </li>
      <t:if x="$index->{index_type} == 6 # fileset">
        <li><a href=/help#filesets>ヘルプ</a>
      </t:if>
    </menu>
  </gr-popup-menu>
</t:macro>
<template-set name=gr-menu-index>
  <template>
    <p><a data-href-template=/g/{group.group_id}/i/{index.index_id}/>トップ</a>
    <p><copy-button><a data-href-template=/g/{group.group_id}/i/{index.index_id}/>
      URLをコピー
    </a></copy-button>
    <p><copy-button type=jump>
      <a data-href-template=/g/{group.group_id}/i/{index.index_id}/ data-title-field=index.title>
        ジャンプリストに追加
      </a>
    </copy-button>
    <p><a data-href-template=/g/{group.group_id}/i/{index.index_id}/config>設定</a>
    <p data-gr-if-index-type=1><a href=/help#blogs target=help>ヘルプ</a>
    <p data-gr-if-index-type=2><a href=/help#wiki target=help>ヘルプ</a>
    <p data-gr-if-index-type=3><a href=/help#todos target=help>ヘルプ</a>
    <p data-gr-if-index-type=4><a href=/help#labels target=help>ヘルプ</a>
    <p data-gr-if-index-type=5><a href=/help#milestones target=help>ヘルプ</a>
    <p data-gr-if-index-type=6><a href=/help#filesets target=help>ヘルプ</a>
  </template>
</template-set>

<t:macro name=wiki-menu t:params="$wiki_name">
  <gr-popup-menu>
    <button type=button>⋁</button>
    <menu hidden>
      <li>
        <a href>
          Wikiページ
        </a>
      <li><copy-button>
        <a href>
          URLをコピー
        </a>
      </>
      <li><copy-button type=jump>
        <a href pl:title=$wiki_name>
          ジャンプリストに追加
        </a>
      </>
    </menu>
  </gr-popup-menu>
</t:macro>
  
<template-set name=page-config>
  <template title=設定>
    <section>
      <header class=section>
        <h1>グループ設定</>
        <a href=/help#config target=help>ヘルプ</a>
      </header>

      <form is=save-data data-saver=groupSaver method=post action=edit.json id=edit-form>
        <!-- XXX data-next=update group info -->
        <table class=config>
          <tbody>
            <tr>
              <th><label for=edit-title>名前</>
              <td><input name=title data-field=group.title id=edit-title required>
            <tr>
              <th><label for=edit-theme>配色</>
              <td>
                <gr-select-theme name=theme data-field=group.theme>
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
        </table>
        <p class=operations>
          <button type=submit class=save-button data-enable-by-fill>保存する</>
          <action-status hidden stage-saver=保存中... ok=保存しました。 />
      </form>
    </section>

    <section id=create>
      <header class=section>
        <h1>作成</h1>
        <a href=/help#group-config-create target=help>ヘルプ</a>
      </header>

      <tab-set>
        <tab-menu/>

        <section id=create-blog>
          <h1>日記</h1>

          <section-intro>
            <p>新しい日記 <small>(日記記事ではなく<strong>日記帳</>)</small>
            を作成します。 (この操作は取り消せません。)
          </section-intro>

          <form is=save-data data-saver=groupSaver method=post action=i/create.json
              data-next=groupGo:i/{index_id}/config>
            <table class=config>
              <tbody>
                <tr>
                  <th><label for=create-blog-title>名前</>
                  <td><input name=title id=create-blog-title required placeholder=題名>
            </table>

            <p class=operations>
              <gr-input-hidden-random-theme name=theme />
              <input type=hidden name=index_type value=1>
              <button type=submit class=save-button>作成する</>
              <action-status hidden stage-saver=作成中... />
          </form>
        </section>

        <section id=create-wiki>
          <h1>Wiki</h1>

          <section-intro>
            <p>新しい Wiki <small>(記事ではなく<strong>Wiki</>)</small>
            を作成します。 (この操作は取り消せません。)
          </section-intro>

          <form is=save-data data-saver=groupSaver method=post action=i/create.json
              data-next=groupGo:i/{index_id}/config>
            <table class=config>
              <tbody>
                <tr>
                  <th><label for=create-wiki-title>名前</>
                  <td><input name=title id=create-wiki-title required value=Wiki>
            </table>

            <p class=operations>
              <gr-input-hidden-random-theme name=theme />
              <input type=hidden name=index_type value=2>
              <button type=submit class=save-button>作成する</>
              <action-status hidden stage-saver=作成中... />
          </form>
        </section>

        <section id=create-todo-list>
          <h1>TODO リスト</h1>

          <section-intro>
            <p>新しい TODO リスト <small>(TODO
            ではなく<strong>リスト</>)</small>
            を作成します。 (この操作は取り消せません。)
          </section-intro>

          <form is=save-data data-saver=groupSaver method=post action=action=i/create.json
              data-next=groupGo:i/{index_id}/config>
            <table class=config>
              <tbody>
                <tr>
                  <th><label for=create-todo-list-title>名前</>
                  <td><input name=title id=create-todo-list-title required value=TODOリスト>
            </table>

            <p class=operations>
              <gr-input-hidden-random-theme name=theme />
              <input type=hidden name=index_type value=3>
              <button type=submit class=save-button>作成する</>
              <action-status hidden stage-saver=作成中... />
          </form>

          <section-intro>
            <p>ラベル、マイルストーンはグループ全体で共通です。
          </section-intro>

          <details>
            <summary>ラベルの作成</summary>

            <form is=save-data data-saver=groupSaver method=post action=i/create.json
                data-next=groupGo:i/{index_id}/config>
              <table class=config>
                <tbody>
                  <tr>
                    <th><label for=create-label-title>名前</>
                    <td><input name=title id=create-label-title required placeholder=ラベル>
              </table>

              <p class=operations>
                <input type=hidden name=index_type value=4>
                <button type=submit class=save-button>作成する</>
                <action-status hidden stage-saver=作成中... />
            </form>
          </details>

          <details>
            <summary>マイルストーンの作成</summary>

            <form is=save-data data-saver=groupSaver method=post action=i/create.json
                data-next=groupGo:i/{index_id}/config>
              <table class=config>
                <tbody>
                  <tr>
                    <th><label for=create-milestone-title>名前</>
                    <td><input name=title id=create-milestone-title required placeholder=マイルストーン名>
              </table>

              <p class=operations>
                <input type=hidden name=index_type value=5>
                <button type=submit class=save-button>作成する</>
                <action-status hidden stage-saver=作成中... />
            </form>
          </details>
        </section>

        <section id=create-fileset>
          <h1>アップローダー</h1>

          <section-intro>
            <p>新しいアップローダーを作成します。 (この操作は取り消せません。)
          </section-intro>

          <form is=save-data data-saver=groupSaver method=post action=i/create.json
              data-next=groupGo:i/{index_id}/config>
            <table class=config>
              <tbody>
                <tr>
                  <th><label for=create-fileset-title>名前</>
                  <td><input name=title id=create-fileset-title required placeholder=フォルダー名>
                <tr>
                  <th>種別
                  <td>
                    <label><input type=radio name=subtype value=file checked required> ファイルアップローダー</label>
                    <label><input type=radio name=subtype value=image required> アルバム</label>
            </table>

            <p class=operations>
              <input type=hidden name=index_type value=6>
              <button type=submit class=save-button>作成する</>
              <action-status hidden stage-saver=作成中... />
          </form>
        </section>
      </tab-set>
    </section>

    <section>
      <h1>データのインポート</h1>

      <p>他のサービスからこのグループに<a href=import>データをインポート</a>できます。
    </section>
  </template>
</template-set>

<template-set name=page-members>
  <template title=参加者>

    <section id=members>
      <header class=section>
        <h1>参加者一覧</h1>
        <a href=/help#group-members target=help>ヘルプ</a>
      </header>

      <list-container loader=groupLoader type=table src=members/list.json key=members class=main-table>
        <template>
          <th>
            <gr-account data-field=account_id>
              <gr-account-name data-field=name data-filling>アカウント</gr-account-name/>
            </gr-account>
            <input type=hidden name=account_id data-field=account_id>
          <td>
            <a href data-href-template="i/{default_index_id}/" data-if-field=default_index_id>日記</a>
          <td class=member_type>
            <enum-value data-field=member_type label-1=一般 label-2=所有者 class=if-not-editable />
            <select name=member_type data-field=member_type class=if-editable hidden>
              <option value=1>一般参加者
              <option value=2>所有者
            </select>
          <td class=owner_status>
            <enum-value data-field=owner_status label-1=承認済 label-2=未承認 class=if-not-editable />
            <select name=owner_status data-field=owner_status class=if-editable hidden>
              <option value=1>承認済
              <option value=2>未承認
            </select>
          <td class=desc>
            <span data-field=desc class=if-not-editable />
            <input name=desc data-field=desc class=if-editable hidden>
          <td class=operations>
            <gr-editable-tr owneronly>
              <form is=save-data data-saver=groupSaver method=post action=members/status.json>
                <button type=button class="edit-button if-not-editable">編集</>
                <button type=submit class="if-editable save-button" hidden>保存</>
                <action-status hidden stage-saver=保存中... ok=保存しました。 />
              </form>
            </gr-editable-tr>
        </template>

        <table>
          <thead>
            <tr>
              <th>名前
              <th>
              <th>種別
              <th>参加承認
              <th>メモ
              <th>
          <tbody>
        </table>
        <action-status hidden stage-loader=読み込み中... />
      </list-container>
    </section>

    <section id=invite>
      <header class=section>
        <h1>参加者の追加</h1>
        <a href=/help#invitation target=help>ヘルプ</a>
      </header>

      <section-intro data-gr-if-group-owner>
        <p>このグループへの招待状を発行します。 URL 
        をメールなどで渡して、 Web ブラウザーで開いてもらってください。
      </section-intro>
            
      <form method=post action=javascript: data-action=members/invitations/create.json data-next="fill:invite-invitation reloadList:invitations-list" data-gr-if-group-owner>

          <table class=config>
            <tbody>
              <tr>
                <th>対象者
                <td>誰でも利用できます。 (一回のみ)
              <tr>
                <th><label for=invite-member_type>種別</>
                <td><select name=member_type id=invite-member_type>
                  <option value=1 selected>一般参加者
                  <option value=2>所有者
                </select>
              <tr>
                <th>有効期間
                <td>発行から72時間
          </table>
  
          <p class=operations>
            <button type=submit class=save-button>発行する</button>
            <gr-action-status hidden stage-fetch=発行中... ok=発行しました />

          <p id=invite-invitation hidden>招待状の URL は
            <code data-field=invitation_url />
          です。招待したい人に渡して、 Web ブラウザーで開いてもらってください。
      </form>

      <section-intro data-gr-if-group-non-owner>
        <p>参加者の追加は、グループの<a href=/help#owner>所有者</a>に依頼してください。
      </section-intro>

    </section>

    <section id=invitations>
      <header class=section>
        <h1>発行済招待状</h1>
        <a href=/help#invitation target=help>ヘルプ</a>
      </header>

      <gr-list-container type=table src=members/invitations/list.json key=invitations sortkey=created class=main-table id=invitations-list data-gr-if-group-owner>
          <template>
            <td><a data-href-field=invitation_url><time data-field=created /></a>
            <td><account-name data-field=author_account_id />
            <td><gr-enum-value data-field=invitation_data.member_type text-1=一般参加者 text-2=所有者 />
            <td><time data-field=expires>
            <td>
              <only-if data-field=used cond="!=0" hidden>
                <time data-field=used />
              </only-if>
              <only-if data-field=used cond="==0" hidden>
                <form method=post action=javascript: data-data-action-template=members/invitations/{invitation_key}/invalidate.json data-next=reloadList:invitations-list>
                  <gr-action-status hidden stage-fetch=変更中... />
                  <button type=submit class=delete-button>無効にする</>
                </form>
              </only-if>
            <td>
              <only-if data-field=user_account_id cond="!=0" hidden>
                <account-name data-field=user_account_id />
              </only-if>
              <only-if data-field=user_account_id cond="==0" hidden>
                -
              </only-if>
          </template>
          <table>
            <thead>
              <tr>
                <th>発行日
                <th>発行者
                <th>種別
                <th>有効期限
                <th>利用日
                <th>利用者
            <tbody>
          </table>
          <list-is-empty hidden>
            <p>招待状はありません。
          </list-is-empty>
          <gr-action-status hidden stage-load=読み込み中... />
          <p class="operations pager">
            <button type=button class=next-page-button hidden>もっと昔</button>
          </p>
      </gr-list-container>

      <section-intro data-gr-if-group-non-owner>
        <p>招待状の一覧は、
        グループの<a href=/help#owner>所有者</a>が表示できます。
      </section-intro>
    </section>
</template-set>
  
<template-set name=page-index-config>
  <template title=設定>
    <section>
      <header class=section>
        <h1>設定</h1>
        <a href=/help#config target=help>ヘルプ</a>
      </header>
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

      <p data-gr-if-default-index>この日記は<gr-account self><gr-account-name data-field=name /></>の<a href=/help#default-blog-index target=help>既定の日記</a>です。</p>
      <form is=save-data data-saver=groupSaver method=post data-action-template=i/{index.index_id}/my.json data-gr-if-index-type=1 data-gr-if-not-default-index>
        <p>この日記を<gr-account self><gr-account-name data-field=name /></>の<a href=/help#default-blog-index target=help>既定の日記</a>に設定できます。</p>
        <p class=operations>
          <input type=hidden name=is_default value=1>
          <button type=submit class=save-button>設定する</>
          <gr-action-status hidden stage-fetch=保存中... ok=保存しました。 />
      </form>

      <p data-gr-if-default-wiki>この Wiki は<a href=/help#default-wiki-index rel=help>グループの Wiki</a> です。</p>
      <form is=save-data data-saver=groupSaver method=post action=edit.json data-gr-if-index-type=2 data-gr-if-not-default-wiki>
        <p>この Wiki を<a href=/help#default-wiki-index rel=help>グループの Wiki</a>に設定できます。</p>
        <p class=operations>
          <input type=hidden name=default_wiki_index_id data-field=index.index_id>
          <button type=submit class=save-button>設定する</>
          <gr-action-status hidden stage-fetch=保存中... ok=保存しました。 />
      </form>

      <p data-gr-if-index-type=3>ラベルやマイルストーンは、<a href=../../config>グループ設定</a>から作成できます。
    </section>
  </template>
</template-set>
    
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
