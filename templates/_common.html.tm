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
            <img data-src-template=/g/{group_id}/account/{account_id}/icon class=icon alt>
            <gr-account-name data-field=name data-filling>アカウント</>
          </gr-account>
        </summary>
        <p><a href=/dashboard>ダッシュボード</a></p>
        <gr-list-container src=/jump/list.json key=items>
          <template>
            <p><a href data-href-template={URL} data-ping-template=/jump/ping.json?url={HREF} data-field=label></a>
          </template>
          <list-main/>
        </gr-list-container>
      </details>
      <details open>
        <summary>
          <gr-group>
            <img data-src-template=/g/{group_id}/icon class=icon alt>
            <gr-group-name data-field=title data-filling>グループ</>
          </gr-group>
        </summary>
        <gr-group>
          <p><a data-href-template=/g/{group_id}/>トップ</a>
          <p class=if-has-default-index><a data-href-template=/g/{group_id}/i/{member.default_index_id}/>自分の日記</a>
          <form is=gr-search method=get action=search>
            <input type=search name=q required placeholder=グループ内検索>
            <button type=submit class=search-button>検索</button>
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
      <gr-error message="The group has no default wiki" hidden>
        <a href=/help#default-wiki-index target=help>グループの Wiki</a>
        が設定されていません。
      </gr-error>
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

<template-set name=gr-menu-wiki>
  <template>
    <p><a data-href-field=wiki.url>Wikiページ</a>
    <p><copy-button>
      <a data-href-field=wiki.url>URLをコピー</a>
    </copy-button>
    <p><copy-button type=jump>
      <a data-href-field=wiki.url data-title-field=wiki.name>ジャンプリストに追加</a>
    </copy-button>
    <p><a href=/help#wiki target=help>ヘルプ</a>
  </template>
</template-set>

<template-set name=page-index>
  <template>
      
  <section class=page>
    <section>
      <h1>最近の更新</>

      <gr-list-container src=i/list.json?index_type=1&index_type=2&index_type=3 key=index_list sortkey=updated class=index-list>
        <template>
          <p>
            <a href data-href-template="i/{index_id}/#{updated}">
              <time data-field=updated />
              <strong data-field=title></strong>
            </a>
            <gr-list-container
                data-src-template="o/get.json?index_id={index_id}&limit=5"
                data-parent-template=i/{index_id}/
                data-context-template={index_type}
                key=objects sortkey=timestamp,created>
              <template>
                <a href data-href-template="o/{object_id}/"
                    data-2-href-template={PARENT}wiki/{title}#{updated}>
                  <strong data-field=title data-empty=■ />
                  (<time data-field=updated data-format=ambtime />)
                </a>
              </template>
              <list-main/>
            </gr-list-container>
        </template>
        <list-main/>
        <gr-action-status hidden stage-load=読み込み中... />
      </gr-list-container>
    </section>

  </template>
</template-set>

<template-set name=page-search>
  <template title=検索>
    <section>
      <header class=section>
        <h1>検索</h1>
        <a href=/help#search target=help>ヘルプ</a>
        <popup-menu>
          <button type=button title=メニュー>
            <button-label>
              メニュー
            </button-label>
          </button>
          <menu-main>
            <p><copy-button>
              <a href>URLをコピー</a>
            </copy-button>
            <p><copy-button type=jump>
              <a href>ジャンプリストに追加</a>
            </copy-button>
          </menu-main>
        </popup-menu>
      </header>

      <form is=gr-search method=get action=search>
        <input type=search name=q data-field=search.q>
        <button type=submit class=search-button>検索</button>
      </form>
      
      <list-container loader=groupLoader src=o/search.json src-search class=search-result key=objects>

        <gr-search-wiki-name hidden>
          <list-item>
            <a href data-href-template=wiki/{name}>Wiki:
              <cite data-field=name data-empty=■ />
            </a>
          </list-item>
        </gr-search-wiki-name>

        <template>
          <a href data-href-template=o/{object_id}/>
            <cite data-field=title data-empty=■></cite>
            <time data-field=timestamp data-format=date></time>
          </a>
          <p class=object-summary>
            <gr-search-snippet data-field=snippet></gr-search-snippet>
            <span>更新: <time data-field=updated></time></span>
        </template>
        <list-main></list-main>
        <list-is-empty hidden>
          <p>一致する記事は見つかりませんでした。</p>
        </list-is-empty>
        <action-status hidden stage-loader=読み込み中...></action-status>
        <p class=operations>
          <button type=button class=list-next>もっと昔</button>
        </p>
      </list-container>

    </section>

  </template>
</template-set>
  
<template-set name=page-config>
  <template title=設定>
    <section>
      <header class=section>
        <h1>グループ設定</>
        <a href=/help#config target=help>ヘルプ</a>
      </header>

      <form is=save-data data-saver=groupSaver method=post action=edit.json id=edit-form data-next=reloadGroupInfo>
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
            <tr>
              <th>アイコン
              <td>
                <gr-icon-editor name=icon_object_id>
                  <figure>
                    <img src=icon class=icon>
                  </figure>
                  <button type=button class=generate-icon-button
                      data-text-selector="input[name=title]">
                    自動生成
                  </button>
                  <button type=button class=reset-icon-button>
                    編集前に戻す
                  </button>
                </gr-icon-editor>
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

          <form is=save-data data-saver=groupSaver method=post action=i/create.json
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

    <section>
      <h1>参加者の管理</h1>

      <p>このグループの<a href=members>参加者を追加、変更</a>できます。
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

      <list-container loader=groupMembersLoader type=table class=main-table>
        <template>
          <th>
            <gr-account data-field=account_id>
              <a data-href-template=account/{account_id}/>
                <img data-src-template=account/{account_id}/icon class=icon alt>
                <gr-account-name data-field=name data-filling>アカウント</gr-account-name>
              </a>
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
              <form is=save-data data-saver=groupSaver method=post action=members/status.json data-next=reloadGroupInfo>
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

      <p><a href=my/config>自分の参加者設定を変更</a>
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
            <td>
              <gr-account data-field=author_account_id>
                <a data-href-template=account/{account_id}/>
                  <img data-src-template=account/{account_id}/icon class=icon alt>
                  <gr-account-name data-field=name data-empty=■ />
                </a>
              </gr-account>
            <td><gr-enum-value data-field=invitation_data.member_type text-1=一般参加者 text-2=所有者 />
            <td><time data-field=expires>
            <td>
              <only-if data-field=used cond="!=0" hidden>
                <p><gr-account data-field=user_account_id>
                  <a data-href-template=account/{account_id}/>
                    <img data-src-template=account/{account_id}/icon class=icon alt>
                    <gr-account-name data-field=name data-empty=■ />
                  </a>
                </gr-account>
                <p><time data-field=used />
              </only-if>
              <only-if data-field=used cond="==0" hidden>
                <form method=post action=javascript: data-data-action-template=members/invitations/{invitation_key}/invalidate.json data-next=reloadList:invitations-list>
                  <gr-action-status hidden stage-fetch=変更中... />
                  <button type=submit class=delete-button>無効にする</>
                </form>
              </only-if>
          </template>
          <table>
            <thead>
              <tr>
                <th>発行日
                <th>発行者
                <th>種別
                <th>有効期限
                <th>利用
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
          <action-status hidden stage-saver=保存中... ok=保存しました。 />
      </form>

      <p data-gr-if-default-wiki>この Wiki は<a href=/help#default-wiki-index rel=help>グループの Wiki</a> です。</p>
      <form is=save-data data-saver=groupSaver method=post action=edit.json data-gr-if-index-type=2 data-gr-if-not-default-wiki>
        <p>この Wiki を<a href=/help#default-wiki-index rel=help>グループの Wiki</a>に設定できます。</p>
        <p class=operations>
          <input type=hidden name=default_wiki_index_id data-field=index.index_id>
          <button type=submit class=save-button>設定する</>
          <action-status hidden stage-saver=保存中... ok=保存しました。 />
      </form>

      <p data-gr-if-index-type=3>ラベルやマイルストーンは、<a href=../../config>グループ設定</a>から作成できます。
    </section>
  </template>
</template-set>

<template-set name=page-index-index templateselector=selectIndexIndexTemplate>
  <template><!-- default / wiki -->

    <gr-list-container key=objects sortkey=updated src-limit=100>
        <template>
          <p><a data-href-template={GROUP}/i/{INDEX_ID}/wiki/{title}#{object_id}>
            <strong data-data-field=title data-empty=■ />
            <time data-field=created data-format=ambtime />
            (<time data-field=updated data-format=ambtime /> 編集)
          </a></p>
        </template>

          <article class="object new" data-gr-if-index-type=2><!-- wiki -->
            <p class=operations>
              <button type=button class=edit-button>新しい記事を書く</button>
          </article>
        <template id=index-list-item-template data-name>
          <a data-href-template={GROUP}/i/{index_id}/ data-field=title data-color-field=color class=label-index></a>
        </template>
        <template id=account-list-item-template data-name>
          <gr-account-name data-field=account_id />
        </template>

        <list-main></list-main>

      <gr-action-status hidden stage-load=読み込み中... />
        <p class="operations pager">
          <button type=button class=next-page-button hidden>もっと昔</button>
      <run-action name=installPrependNewObjects />
    </gr-list-container>
  </template><!-- default -->
  <template data-name=blog>
  
    <gr-list-container key=objects grouped=1 listitemtype=object>
        <template class=object>
          <header>
            <div class=edit-by-dblclick>
              <h1><a data-data-field=title data-empty=■ data-href-template={GROUP}/o/{object_id}/ /></h1>
            </div>
            <todo-state data-data-field=todo_state label-1=未完了 label-2=完了済 />
            <gr-popup-menu>
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
            </gr-popup-menu>
          </header>
          <main><iframe data-data-field=body /></main>
          <footer>
            <p>
              <gr-action-status hidden
                  stage-edit=保存中...
                  ok=保存しました />
              <span data-if-data-non-empty-field=assigned_account_ids>
                担当者:
                <account-list data-data-field=assigned_account_ids />
              </span>
              <index-list data-data-field=index_ids />
              <time data-field=created data-format=ambtime />
              (<time data-field=updated data-format=ambtime /> 編集)
          </footer>

          <article-comments>

            <gr-list-container class=comment-list
                data-src-template=o/get.json?parent_object_id={object_id}&limit=5&with_data=1
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
                      <time data-field=timestamp data-format=ambtime />
                      (<time data-field=updated data-format=ambtime />)
                    </a>
                  </header>
                  <main><iframe data-data-field=body /></main>
                </article>
              </template>
              <template data-name=close class=change-action>
                <p><!-- XXX が -->閉じました。
                (<time data-field=created data-format=ambtime />)
              </template>
              <template data-name=reopen class=change-action>
                <p><!-- XXX が -->開き直しました。
                (<time data-field=created data-format=ambtime />)
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
                (<time data-field=created data-format=ambtime />)
              </template>
              <template data-name=trackback class=trackback>
                <time data-field=created data-format=ambtime />にこの記事が参照されました。
                <object-ref hidden data-field=data.body_data.trackback.object_id template=#object-ref-template />
              </template>
              <p class="operations pager">
                <button type=button class=next-page-button hidden>もっと昔</button>
              </p>
              <gr-action-status hidden stage-load=読み込み中... />
              <list-main/>
            </gr-list-container>

          <details class=actions>
            <summary>コメントを書く</summary>

            <form action=javascript: data-action=o/create.json
                data-next="editCreatedObject editObject resetForm showCreatedObjectInCommentList updateParent"
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

                <gr-action-status hidden
                    stage-fetch=作成中...
                    stage-editcreatedobject_fetch=保存中...
                    stage-editobject_fetch=状態を変更中...
                    stage-showcreatedobjectincommentlist=読み込み中...
                    ok=投稿しました />
            </form>
          </details>

          </article-comments>
        </template>

          <article class="object new">
            <p class=operations>
              <button type=button class=edit-button>新しい記事を書く</button>
          </article>

        <template id=index-list-item-template data-name>
          <a data-href-template={GROUP}/i/{index_id}/ data-field=title data-color-field=color class=label-index></a>
        </template>
        <template id=account-list-item-template data-name>
          <gr-account-name data-field=account_id />
        </template>

        <list-main></list-main>

      <gr-action-status hidden stage-load=読み込み中... />
        <p class="operations pager">
          <button type=button class=next-page-button hidden>もっと昔</button>
      <run-action name=installPrependNewObjects />
    </gr-list-container>
  </template><!-- blog -->
  <template data-name=todos>
    <section>
      <header class=section data-gr-if-index-type="4 5"><!-- label milestone -->
        <h1><a data-href-template=/g/{group.group_id}/i/{index.index_id}/ data-field=index.title data-empty=■ /></h1>
        <gr-menu type=index />
      </header>
      
      <gr-list-container key=objects sortkey=updated src-limit=100 query class=todo-list>
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
            <time data-field=created data-format=ambtime />
            (<time data-field=updated data-format=ambtime /> 編集)
            <index-list data-data-field=index_ids filters='[{"key": ["index_type"], "value": "5"}]' title=マイルストーン />
            <index-list data-data-field=index_ids filters='[{"key": ["index_type"], "value": "4"}]' title=ラベル />
            <account-list data-data-field=assigned_account_ids title=担当者 />
        </template>

          <article class="object new" data-gr-if-index-type=3><!-- todos -->
            <p class=operations>
              <button type=button class=edit-button data-focus-title>新しい TODO</button>
          </article>

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
              <gr-popup-menu>
                <button type=button title=選択>...</button>
                <menu hidden>
                  <form action=javascript:>
                    <list-control-list editable template=edit-milestone clear-template=edit-milestone-clear filters='[{"key": ["data", "index_type"], "value": "5"}]' />
                  </form>
                </menu>
              </gr-popup-menu>

              <list-control-list template=view filters='[{"key": ["data", "index_type"], "value": "4"}]' data-empty=(ラベル制約なし) />
              <gr-popup-menu>
                <button type=button title=選択>...</button>
                <menu hidden>
                  <list-control-list editable template=edit filters='[{"key": ["data", "index_type"], "value": "4"}]' />
                </menu>
              </gr-popup-menu>
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
              <gr-popup-menu>
                <button type=button title=変更>...</button>
                <menu hidden>
                  <form action=javascript:>
                    <list-control-list editable template=edit clear-template=edit-clear />
                  </form>
                </menu>
              </gr-popup-menu>
            </list-control>
          </list-query>

          <button type=button class=reload-button hidden>再読込</button>
        </menu>

        <template id=index-list-item-template data-name>
          <a data-href-template=./?index={index_id} data-field=title data-color-field=color class=label-index></a>
        </template>
        <template id=account-list-item-template data-name>
          <a data-href-template=./?assigned={account_id}><gr-account-name data-field=account_id /></a>
        </template>

        <list-main/>

      <gr-action-status hidden stage-load=読み込み中... />
        <p class="operations pager">
          <button type=button class=next-page-button hidden>もっと昔</button>
      <run-action name=installPrependNewObjects />
      </gr-list-container>
    </section>
  </template><!-- todos -->
  <template data-name=fileset>
    <section>
      <header class=section>
        <h1><a data-href-template=/g/{group.group_id}/i/{index.index_id}/ data-field=index.title data-empty=■ /></h1>
        <gr-menu type=index />
      </header>

      <gr-list-container key=objects sortkey=created src-limit=100>
          <template data-gr-if-index-subtype=image>
            <gr-popup-menu>
              <button type=button>⋁</button>
                <menu hidden>
                  <li><copy-button>
                    <a data-href-template={GROUP}/o/{object_id}/>記事URLをコピー</a>
                  </>
              </menu>
            </gr-popup-menu>
            <figure>
              <a data-href-template={GROUP}/o/{object_id}/image data-title-data-field=title>
                <img src data-src-template={GROUP}/o/{object_id}/image>
              </a>
              <figcaption>
                <code data-data-field=file_name></code>
                <unit-number data-data-field=file_size type=bytes />
                <code data-data-field=mime_type />
                <a data-href-template={GROUP}/o/{object_id}/>
                  <time data-field=timestamp data-format=ambtime />
                </a>
              </figcaption>
            </figure>
          </template>
          <template data-gr-if-index-subtype=file>
            <gr-popup-menu>
              <button type=button>⋁</button>
                <menu hidden>
                  <li><copy-button>
                    <a data-href-template={GROUP}/o/{object_id}/>記事URLをコピー</a>
                  </>
              </menu>
            </gr-popup-menu>
            <p class=main-line>
              <a data-href-template={GROUP}/o/{object_id}/file download>
                <span data-data-field=title data-empty=■ />
                <code data-data-field=file_name></code>
              </a>
            <p class=info-line>
              <unit-number data-data-field=file_size type=bytes />
              <code data-data-field=mime_type />
              <a data-href-template={GROUP}/o/{object_id}/>
                <time data-field=timestamp data-format=ambtime />
              </a>
          </template>

          <form action=javascript: method=post data-form-type=uploader>
            <gr-list-container type=table>
              <template>
                <td class=file-name><code data-data-field=file_name />
                <td class=file-size><unit-number data-data-field=file_size type=bytes />
                <td class=progress><gr-action-status hidden
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
            </gr-list-container>
            <p class=operations>
                <input type=file name=file multiple hidden accept=image/* data-gr-if-index-subtype=image>
                <button type=button name=upload-button class=edit-button data-gr-if-index-subtype=image>画像をアップロード...</button>
                <input type=file name=file multiple hidden data-gr-if-index-subtype=file>
                <button type=button name=upload-button class=edit-button data-gr-if-index-subtype=file>ファイルをアップロード...</button>
          </form>

        <template id=index-list-item-template data-name>
          <a data-href-template={GROUP}/i/{index_id}/ data-field=title data-color-field=color class=label-index></a>
        </template>
        <template id=account-list-item-template data-name>
          <gr-account-name data-field=account_id />
        </template>

        <list-main></list-main>

      <gr-action-status hidden stage-load=読み込み中... />
        <p class="operations pager">
          <button type=button class=next-page-button hidden>もっと昔</button>
      <run-action name=installPrependNewObjects />
    </gr-list-container>
  </template><!-- fileset -->
</template-set>

<template-set name=page-object-index>
  <template>
    <section>
      <header class=section>
        <h1><time data-field=object.timestamp data-format=date /></h1>
      </header>
    
      <gr-list-container key=objects listitemtype=object>
        <template class=object>
          <header>
            <div class=edit-by-dblclick>
              <h1><a data-data-field=title data-empty=■ data-href-template={GROUP}/o/{object_id}/ /></h1>
            </div>
            <todo-state data-data-field=todo_state label-1=未完了 label-2=完了済 />
            <gr-popup-menu>
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
            </gr-popup-menu>
          </header>
          <main><iframe data-data-field=body /></main>
          <footer>
            <p>
              <gr-action-status hidden
                  stage-edit=保存中...
                  ok=保存しました />
              <span data-if-data-non-empty-field=assigned_account_ids>
                担当者:
                <account-list data-data-field=assigned_account_ids />
              </span>
              <index-list data-data-field=index_ids />
              <time data-field=created data-format=ambtime />
              (<time data-field=updated data-format=ambtime /> 編集)
          </footer>

          <article-comments>

            <gr-list-container class=comment-list
                data-src-template=o/get.json?parent_object_id={object_id}&limit=30&with_data=1
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
                      <time data-field=timestamp data-format=ambtime />
                      (<time data-field=updated data-format=ambtime />)
                    </a>
                  </header>
                  <main><iframe data-data-field=body /></main>
                </article>
              </template>
              <template data-name=close class=change-action>
                <p><!-- XXX が -->閉じました。
                (<time data-field=created data-format=ambtime />)
              </template>
              <template data-name=reopen class=change-action>
                <p><!-- XXX が -->開き直しました。
                (<time data-field=created data-format=ambtime />)
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
                (<time data-field=created data-format=ambtime />)
              </template>
              <template data-name=trackback class=trackback>
                <time data-field=created data-format=ambtime />にこの記事が参照されました。
                <object-ref hidden data-field=data.body_data.trackback.object_id template=#object-ref-template />
              </template>
              <p class="operations pager">
                <button type=button class=next-page-button hidden>もっと昔</button>
              </p>
              <gr-action-status hidden stage-load=読み込み中... />
              <list-main/>
            </gr-list-container>

          <details class=actions>
            <summary>コメントを書く</summary>

            <form action=javascript: data-action=o/create.json
                data-next="editCreatedObject editObject resetForm showCreatedObjectInCommentList updateParent"
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

                <gr-action-status hidden
                    stage-fetch=作成中...
                    stage-editcreatedobject_fetch=保存中...
                    stage-editobject_fetch=状態を変更中...
                    stage-showcreatedobjectincommentlist=読み込み中...
                    ok=投稿しました />
            </form>
          </details>

          </article-comments>
        </template>

        <template id=index-list-item-template data-name>
          <a data-href-template={GROUP}/i/{index_id}/ data-field=title data-color-field=color class=label-index></a>
        </template>
        <template id=account-list-item-template data-name>
          <gr-account-name data-field=account_id />
        </template>

        <list-main></list-main>
        <gr-action-status hidden stage-load=読み込み中... />
      </gr-list-container>
    </section>
  </template>
</template-set>

<template-set name=page-wiki>
  <template>
    <section>
      <header class=section>
        <h1><a data-href-field=wiki.url data-field=wiki.name data-empty=■ /></h1>
        <gr-menu type=wiki />
      </header>

      <gr-list-container key=objects sortkey=created listitemtype=object>
        <template class=object>
          <header>
            <div class=edit-by-dblclick>
              <h1><a data-data-field=title data-empty=■ data-href-template={GROUP}/o/{object_id}/ /></h1>
            </div>
            <todo-state data-data-field=todo_state label-1=未完了 label-2=完了済 />
            <gr-popup-menu>
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
            </gr-popup-menu>
          </header>
          <main><iframe data-data-field=body /></main>
          <footer>
            <p>
              <gr-action-status hidden
                  stage-edit=保存中...
                  ok=保存しました />
              <span data-if-data-non-empty-field=assigned_account_ids>
                担当者:
                <account-list data-data-field=assigned_account_ids />
              </span>
              <index-list data-data-field=index_ids />
              <time data-field=created data-format=ambtime />
              (<time data-field=updated data-format=ambtime /> 編集)
          </footer>

          <article-comments>

            <gr-list-container class=comment-list
                data-src-template=o/get.json?parent_object_id={object_id}&limit=30&with_data=1
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
                      <time data-field=timestamp data-format=ambtime />
                      (<time data-field=updated data-format=ambtime />)
                    </a>
                  </header>
                  <main><iframe data-data-field=body /></main>
                </article>
              </template>
              <template data-name=close class=change-action>
                <p><!-- XXX が -->閉じました。
                (<time data-field=created data-format=ambtime />)
              </template>
              <template data-name=reopen class=change-action>
                <p><!-- XXX が -->開き直しました。
                (<time data-field=created data-format=ambtime />)
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
                (<time data-field=created data-format=ambtime />)
              </template>
              <template data-name=trackback class=trackback>
                <time data-field=created data-format=ambtime />にこの記事が参照されました。
                <object-ref hidden data-field=data.body_data.trackback.object_id template=#object-ref-template />
              </template>
              <p class="operations pager">
                <button type=button class=next-page-button hidden>もっと昔</button>
              </p>
              <gr-action-status hidden stage-load=読み込み中... />
              <list-main/>
            </gr-list-container>

          <details class=actions>
            <summary>コメントを書く</summary>

            <form action=javascript: data-action=o/create.json
                data-next="editCreatedObject editObject resetForm showCreatedObjectInCommentList updateParent"
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

                <gr-action-status hidden
                    stage-fetch=作成中...
                    stage-editcreatedobject_fetch=保存中...
                    stage-editobject_fetch=状態を変更中...
                    stage-showcreatedobjectincommentlist=読み込み中...
                    ok=投稿しました />
            </form>
          </details>

          </article-comments>
        </template>

        <template id=index-list-item-template data-name>
          <a data-href-template={GROUP}/i/{index_id}/ data-field=title data-color-field=color class=label-index></a>
        </template>
        <template id=account-list-item-template data-name>
          <gr-account-name data-field=account_id />
        </template>

        <list-main></list-main>

        <list-is-empty hidden>
          <p>記事はまだありません。</p>

          <article class="object new">
            <p class=operations>
              <button type=button class=edit-button>記事を書く</button>
          </article>
        </list-is-empty>

        <gr-action-status hidden stage-load=読み込み中... />
        <run-action name=installPrependNewObjects />
      </gr-list-container>

      <article-comments>

        <gr-list-container class=comment-list
            data-src-template=o/get.json?index_id={index.index_id}&parent_wiki_name={wiki.name}&limit=30&with_data=1
            key=objects sortkey=timestamp,created prepend
            template-selector=object>
          <template />
          <template data-name=trackback class=trackback>
            <time data-field=created data-format=ambtime />にこのWikiページが参照されました。
            <object-ref hidden data-field=data.body_data.trackback.object_id template=#object-ref-template />
          </template>
          <p class="operations pager">
            <button type=button class=next-page-button hidden>もっと昔</button>
          </p>
          <gr-action-status hidden stage-load=読み込み中... />
          <list-main/>
        </gr-list-container>
      </article-comments>

      <footer>
        <p><a data-href-template=/g/{group.group_id}/search?q={url:wiki.name}>「<bdi data-field=wiki.name />」を含む記事を検索する</a></p>
      </footer>
    </section>
  </template>
</template-set>

  <template class=body-template id=object-ref-template>
    <a href data-href-template={GROUP}/o/{object_id}/>
      <ref-header>
        <gr-enum-value data-field=data.todo_state text-1=未完了 text-2=完了済 />
        <cite data-field=data.title data-empty=■ />
        <time data-field=created />
      </ref-header>
      <body-snippet data-field=snippet />
    </a>
  </template>
  <template class=body-template id=hatena-star-template>
    <a href data-href-template=https://profile.hatena.ne.jp/{name}/ referrerpolicy=no-referrer data-title-template=" {name} {quote}" data-class-template=star-type-{type}>
      <span>★</span><!--
      --><img data-src-template=https://cdn1.www.st-hatena.com/users/{name2}/{name}/profile.gif data-alt-template={name} referrerpolicy=no-referrer class=hatena-user-icon><!--
      --><star-count data-field=count data-class-template=star-count-{count} />
    </a>
  </template>

  <t:include path=_object_editor.html.tm />
  
<template-set name=page-account-index>
  <template>
    <section>
      <header class=section>
        <h1>
          <img src=icon class=icon alt>
          <bdi data-field=account.name data-empty=■ />
        </h1>
        <popup-menu>
          <button type=button title=メニュー>
            <button-label>
              メニュー
            </button-label>
          </button>
          <menu-main>
            <p><copy-button>
              <a href>URLをコピー</a>
            </copy-button>
            <p><copy-button type=jump>
              <a href>ジャンプリストに追加</a>
            </copy-button>
          </menu-main>
        </popup-menu>
      </header>
        <table class=config>
          <tbody>
            <tr>
              <th>名前
              <td>
                <img src=icon class=icon alt>
                <bdi data-field=account.name data-empty=■ />
            <tr>
              <th>種別
              <td>
                <enum-value data-field=account.member_type
                    label-1=一般参加者
                    label-2=所有者  />
            <tr>
              <th>参加承認
              <td>
                <enum-value data-field=account.owner_status
                    label-1=承認済 label-2=未承認 />
        </table>
    </section>
  </template>
</template-set>
  
<template-set name=page-my-config>
  <template title=グループ参加者設定>
    <section>
      <header class=section>
        <h1>グループ参加者設定</h1>
        <a href=/help#config target=help>ヘルプ</a>
      </header>
      <form is=save-data data-saver=groupSaver method=post data-action-template=my/edit.json id=edit-form data-next=reloadGroupInfo>
        <table class=config>
          <tbody>
            <tr>
              <th><label for=edit-name>名前</>
              <td><input name=name data-field=account.name id=edit-name required>
            <tr>
              <th>種別
              <td>
                <enum-value data-field=group.member.member_type
                    label-1=一般参加者
                    label-2=所有者  />
            <tr>
              <th>アイコン
              <td>
                <gr-icon-editor name=icon_object_id>
                  <figure>
                    <img data-src-template=/g/{group.group_id}/account/{account.account_id}/icon class=icon>
                  </figure>
                  <button type=button class=generate-icon-button
                      data-text-selector="input[name=name]">
                    自動生成
                  </button>
                  <button type=button class=reset-icon-button>
                    編集前に戻す
                  </button>
                </gr-icon-editor>
        </table>
        <p class=operations>
          <button type=submit class=save-button>保存する</>
          <action-status hidden stage-saver=保存中... ok=保存しました。 />
      </form>

      <p><a href=/jump>ジャンプリストの編集</a>
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
