
<!-- also in dashboard.htt.tm -->
<template-set name=mn-email>
  <template>
    <gr-mn-main>
      メールアドレスが登録されていません。
      登録すると通知をメールでお届けします。
      <a href=/dashboard/receive#emails class=main-button>登録する</a>
    </gr-mn-main>
    <button type=button class=cancel-button title="今後このメッセージを表示しない">×</button>
  </template>
</template-set>

<!-- also in dashboard.htt.tm -->
<template-set name=mn-push>
  <template>
    <gr-mn-main>
      通知の受信設定がありません。
      <a href=/dashboard/receive#notifications class=main-button>設定する</a>
    </gr-mn-main>
    <button type=button class=cancel-button title="今後このメッセージを表示しない">×</button>
  </template>
</template-set>

<!-- also in dashboard.htt.tm -->
<template-set name=gr-navigate-external>
  <template>
    <p>外部 (<code data-field=origin></code>) に移動しようとしています。
    <p class=buttons>
      <a data-href-field=href target=_top rel="noreferrer" class=main-button>このまま移動する</a>
      <a data-href-field=href target=_blank rel="noreferrer noopener" class=main-button>別窓で開く</a>
      <a href=javascript: class="main-button">移動しない</a>
  </template>
</template-set>

<!-- also in dashboard.htt.tm -->
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
    <p><a data-href-template=/g/{group.group_id}/files>ファイル</a>
    <p><a data-href-template=/g/{group.group_id}/search>検索</a>
    <hr>
    <p><a is=copy-url data-href-template=/g/{group.group_id}/>
      URLをコピー
    </a>
    <p><a is=gr-jump-add data-href-template=/g/{group.group_id}/ data-title-field=group.title>
      ジャンプリストに追加
    </a>
    <hr>
    <p><a data-href-template=/g/{group.group_id}/my/config>個人設定</a>
    <hr>
    <p><a data-href-template=/g/{group.group_id}/members>参加者</a>
    <p><a data-href-template=/g/{group.group_id}/config>グループ設定</a>
    <hr>
    <p><a data-href-template=/g/{group.group_id}/guide>グループのガイド</a>
    <p><a href=/help#groups target=help>ヘルプ</a>
  </template>
</template-set>

<template-set name=gr-menu-index>
  <template>
    <p><a data-href-template=/g/{group.group_id}/i/{index.index_id}/>トップ</a>
    <p><a is=copy-url data-href-template=/g/{group.group_id}/i/{index.index_id}/>
      URLをコピー
    </a>
    <p><a is=gr-jump-add data-href-template=/g/{group.group_id}/i/{index.index_id}/ data-title-field=index.title>
      ジャンプリストに追加
    </a>
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
    <p><a is=copy-url data-href-field=wiki.url>URLをコピー</a>
    <p><a is=gr-jump-add data-href-field=wiki.url data-title-field=wiki.name>ジャンプリストに追加</a>
    <p><a href=/help#wiki target=help>ヘルプ</a>
  </template>
</template-set>

<template-set name=page-index>
  <template>

    <section>
      <h1>最近の更新</h1>

      <list-container loader=recentIndexListLoader class=main-menu-list-container>
        <template>
          <a href data-href-template="i/{index_id}/#{updated}" class=antenna-item>
            <span data-field=title data-empty=■></span>
            <small><time data-field=updated data-format=ambtime /></small>
          </a>
        </template>
        <list-main class=main-menu-list />
        <action-status hidden stage-loader=読込中... />
      </list-container>
    </section>

  </template>
</template-set>

<template-set name=page-guide-none>
  <template>
    <section>
      <header class=page>
        <h1>グループのガイド</h1>
      </header>
      
      <p>このグループのガイドはまだありません。
      <a href=config#guide>設定ページから作成</a>してください。
    </section>
  </template>
</template-set>

<template-set name=page-files>
  <template title=ファイル class=is-subpage>
    <section>
      <header class=section>
        <h1>フォルダー一覧</h1>
        <popup-menu>
          <button type=button title=メニュー>
            <button-label>
              メニュー
            </button-label>
          </button>
          <menu-main>
            <p><a data-href-template=/g/{group.group_id}/config#create-fileset>フォルダーの作成</a>
            <hr>
            <p><a is=copy-url href>URLをコピー</a>
            <p><a is=gr-jump-add href>ジャンプリストに追加</a>
            <hr>
            <p><a href=/help#filesets target=help>ヘルプ</a>
          </menu-main>
        </popup-menu>
      </header>

      <list-container loader=filesetIndexListLoader class=main-menu-list-container>
        <template>
          <a href data-href-template="i/{index_id}/#{updated}" data-class-template="antenna-item fileset-{subtype}">
            <span data-field=title data-empty=■></span>
            <small><time data-field=updated data-format=ambtime /></small>
          </a>
        </template>
        <list-main class=main-menu-list />
        <action-status hidden stage-loader=読込中... />
      </list-container>
      
    </section>

  </template>
</template-set>

<template-set name=page-search>
  <template title=検索 class=is-subpage>
    <section>
      <header class=section>
        <h1>検索</h1>
        <popup-menu>
          <button type=button title=メニュー>
            <button-label>
              メニュー
            </button-label>
          </button>
          <menu-main>
            <p><a is=copy-url href>URLをコピー</a>
            <p><a is=gr-jump-add href>ジャンプリストに追加</a>
            <hr>
            <p><a href=/help#search target=help>ヘルプ</a>
          </menu-main>
        </popup-menu>
      </header>

      <form is=gr-search method=get action=search>
        <input type=search name=q data-field=search.q>
        <button type=submit class=search-button>検索</button>
      </form>
      
      <list-container loader=groupLoader src=o/search.json loader-search loader-limit=20 class=search-result key=objects template=gr-search-result-item>

        <gr-search-wiki-name hidden>
          <list-item>
            <a href data-href-template=wiki/{name}>Wiki:
              <cite data-field=name data-empty=■ />
            </a>
          </list-item>
        </gr-search-wiki-name>
        <list-main></list-main>
        <list-is-empty hidden>
          <p>一致する記事は見つかりませんでした。</p>
        </list-is-empty>
        <action-status hidden stage-loader=読込中...></action-status>
        <p class="operations pager">
          <button type=button class=list-next>もっと昔</button>
        </p>
      </list-container>

    </section>

  </template>
</template-set>

<template-set name=gr-search-result-item>
  <template>
    <a href data-href-field=url>
      <cite data-field=object.title data-empty=■></cite>
      <time data-field=object.timestamp data-format=date></time>
    </a>
    <p class=object-summary>
      <gr-search-snippet data-field=object.snippet></gr-search-snippet>
      <span>更新: <time data-field=object.updated></time></span>
  </template>
</template-set>

<template-set name=gr-fileset-list-item-file>
  <template>
    <a href data-href-template={url}file download>
      <gr-object-name>
        <code data-field=object.data.file_name />
      </gr-object-name>
      <time data-field=object.timestamp data-format=date></time>
    </a>
    <p class=object-summary>
      <gr-object-meta>
        <cite data-field=object.title data-empty=■></cite>
        <unit-number data-field=object.data.file_size type=bytes />
        <code data-field=object.data.mime_type />
      </gr-object-meta>
      <span>
        更新: <a href data-href-field=url><time data-field=object.updated></time></a>
      </span>
  </template>
</template-set>

<template-set name=gr-fileset-list-item-image>
  <template>
    <figure>
      <a href data-href-template={url}image data-title-field=object.data.title>
        <img src data-src-template={url}image>
      </a>
      <figcaption class=object-summary>
        <gr-object-meta>
          <cite data-field=object.data.title data-empty=■ />
          <code data-field=object.data.file_name data-empty=■></code>
          <unit-number data-field=object.data.file_size type=bytes />
          <code data-field=object.data.mime_type />
        </gr-object-meta>
        <span>
          <a href data-href-field=url><time data-field=object.timestamp data-format=date></time></a>
        </span>
      </figcaption>
    </figure>
  </template>
</template-set>

<template-set name=gr-index-viewer-image>
  <template><!-- <panel-main> -->
    <details>
      <summary>新しい画像</summary>
      <gr-uploader data-indexid-field=index_id indexsubtype=image listselector=list-container listancestor=panel-main data-filled=indexid />
    </details>

    <list-container loader=groupIndexLoader data-loader-indexid-field=index_id loader-indextype=6 loader-limit=9 data-filled="loader-indexid">
      <template>
        <button type=button data-value-field=url data-filled=value>
          <img src data-src-template={url}image>
        </button>
      </template>
      <list-main/>
      <action-status hidden stage-loader=読込中... />
      <p class="operations pager">
        <button type=button class=list-next hidden>もっと昔</button>
    </list-container>
  </template>
</template-set>

<template-set name=gr-index-viewer-icon>
  <template><!-- <panel-main> -->
    <details>
      <summary>新しい画像</summary>
      <gr-uploader data-indexid-field=index_id indexsubtype=icon listselector=list-container listancestor=panel-main data-filled=indexid />
    </details>

    <list-container loader=groupIndexLoader data-loader-indexid-field=index_id loader-indextype=6 loader-limit=9 data-filled="loader-indexid">
      <template>
        <button type=button data-value-field=url data-filled=value>
          <img src data-src-template={url}image>
        </button>
      </template>
      <list-main/>
      <action-status hidden stage-loader=読込中... />
      <p class="operations pager">
        <button type=button class=list-next hidden>もっと昔</button>
    </list-container>
  </template>
</template-set>

<template-set name=gr-index-viewer-file>
  <template><!-- <panel-main> -->
    <details>
      <summary>新しいファイル</summary>
      <gr-uploader data-indexid-field=index_id indexsubtype=file listselector=list-container listancestor=panel-main data-filled=indexid />
    </details>

    <list-container loader=groupIndexLoader data-loader-indexid-field=index_id loader-indextype=6 loader-limit=10 loader-withdata data-filled="loader-indexid">
      <template>
        <button type=button data-value-field=url data-filled=value>
          <code data-field=object.data.file_name />
        </button>
      </template>
      <list-main/>
      <action-status hidden stage-loader=読込中... />
      <p class="operations pager">
        <button type=button class=list-next hidden>もっと昔</button>
    </list-container>
  </template>
</template-set>

<template-set name=page-config>
  <template title=設定 class=is-subpage>
    <section>
      <header class=section>
        <h1>グループ設定</>
        <a href=/help#config target=help>ヘルプ</a>
      </header>

      <form is=save-data data-saver=groupSaver method=post action=edit.json id=edit-form data-next=reloadGroupInfo>
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
                <gr-select-icon name=icon_object_id src=icon
                    generationtextselector="input[name=title]" />
        </table>
        <p class=operations>
          <button type=submit class=save-button data-enable-by-fill>保存する</>
          <action-status hidden stage-saver=保存中... ok=保存しました。 />
      </form>

      <div id=guide>
        <p id=guide-link><a href=guide>グループのガイドページ</a>があります。
        <form id=guide-create-form is=save-data data-saver=groupSaver method=post action=edit.json data-next="reloadGroupInfo">
          <p><a href=/help#group-guide target=help>グループのガイドページ</a>がありません。
          <gr-create-object name=guide_object_id />
          <p class=operations>
            <button type=submit class=save-button>作成する</>
            <action-status hidden stage-saver=作成中... ok=作成しました。 />
        </form>
      </div>
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
              data-next="reloadIndexInfo groupGo:i/{index_id}/config">
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
              data-next="reloadIndexInfo groupGo:i/{index_id}/config">
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
              data-next="reloadIndexInfo groupGo:i/{index_id}/config">
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
                data-next="reloadIndexInfo groupGo:i/{index_id}/config">
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
                data-next="reloadIndexInfo groupGo:i/{index_id}/config">
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
          <h1>フォルダー</h1>

          <section-intro>
            <p>新しいフォルダーを作成します。 (この操作は取り消せません。)
          </section-intro>

          <form is=save-data data-saver=groupSaver method=post action=i/create.json
              data-next="reloadIndexInfo groupGo:i/{index_id}/config">
            <table class=config>
              <tbody>
                <tr>
                  <th><label for=create-fileset-title>名前</>
                  <td><input name=title id=create-fileset-title required placeholder=フォルダー名>
                <tr>
                  <th>種別
                  <td>
                    <label><input type=radio name=subtype value=file checked required> ファイルフォルダー</label>
                    <label><input type=radio name=subtype value=image required> アルバム</label>
                    <label><input type=radio name=subtype value=icon required> アイコン集</label>
                    <label><input type=radio name=subtype value=stamp required> スタンプセット</label>
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
  <template title=参加者 class=is-subpage>

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
        <action-status hidden stage-loader=読込中... />
      </list-container>

      <p><a href=my/config>自分の個人設定を変更</a>
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
            
      <form is=save-data data-saver=groupSaver method=post action=members/invitations/create.json data-next="fill:#invite-invitation reloadList:#invitations-list" data-gr-if-group-owner>

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
              <tr>
                <th>既定の日記
                <td>
                  <gr-select-index type=blog optional=指定しない name=default_index_id />
          </table>
  
          <p class=operations>
            <button type=submit class=save-button>発行する</button>
            <action-status hidden stage-saver=発行中... ok=発行しました />
          </p>
          
          <div id=invite-invitation hidden>
            <p>次の文面を招待したい人に渡してください。</p>

<gr-invitation-text>
グループの招待状です。
Web ブラウザーで開いてください。
&lt;<code data-field=invitation_url />>
</gr-invitation-text>

            <p class=operations>
              <button type=button is=copy-text-content data-selector=gr-invitation-text>コピー</button>

            <p>QRコードから招待状を開くこともできます。

              <figure class=qrcode>
                <qr-code data-data-field=invitation_url data-filled=data />
              </figure>

            <p class=operations>
              <button type=button is=gr-download-img data-selector="#invite qr-code img" data-filename=qrcode.png>ダウンロード</button>

          </div>
          
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
                <form method=post action=javascript: data-data-action-template=members/invitations/{invitation_key}/invalidate.json data-next=reloadList:invitations-list class=transparent>
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
          <gr-action-status hidden stage-load=読込中... />
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
  <template title=設定 class=is-subpage>
    <section>
      <header class=section>
        <h1>設定</h1>
        <a href=/help#config target=help>ヘルプ</a>
      </header>
      <form is=save-data data-saver=groupSaver method=post data-action-template=i/{index.index_id}/edit.json id=edit-form data-next=reloadIndexInfo>
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
                    label-file=ファイルフォルダー
                    label-icon=アイコン集
                    label-stamp=スタンプセット
                    label-null label-undefined />
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

    <article class="object new" data-gr-if-index-type=2><!-- wiki -->
      <p class=operations>
        <button type=button class=edit-button onclick="
          var data = {index_ids: {}, timestamp: (new Date).valueOf () / 1000,
                      body_type: 1, body: ''};
          data.index_ids[this.getAttribute ('data-indexid')] = 1;
          editObject (this.parentNode.parentNode, {data: data}, {open: true, focusTitle: true});
        " data-data-indexid-field=index.index_id data-filled=data-indexid>新しい記事を書く</button>
    </article>

    <section>
      <h1>記事一覧</h1>
      
      <list-container loader=groupIndexLoader data-loader-indexid-field=index.index_id data-loader-indextype-field=index.index_type loader-limit=20 data-filled="loader-indexid loader-indextype" template=gr-search-result-item class=search-result>
        <list-main></list-main>
        <list-is-empty hidden>
          <p>記事は見つかりませんでした。</p>
        </list-is-empty>
        <action-status hidden stage-loader=読込中... />
        <p class="operations pager">
          <button type=button class=list-next hidden>もっと昔</button>
      </list-container>
    </section>
  </template><!-- default -->
  <template data-name=blog>
  
    <gr-list-container key=objects grouped=1 listitemtype=object src-limit=5>
        <template class=object>
          <header>
            <div class=edit-by-dblclick>
              <h1><a data-data-field=title data-empty=■ data-href-template={GROUP}/o/{object_id}/ /></h1>
            </div>
            <enum-value class=todo-state data-data-field=todo_state
                label-1=未完了 label-2=完了済
                label-undefined
            />
            <popup-menu>
              <button type=button title=メニュー>
                <button-label>
                  メニュー
                </button-label>
              </button>
              <menu-main>
                <p><a data-href-template={GROUP}/o/{object_id}/>記事ページ</a>
                <hr>
                <p><button type=button class=edit-button>編集</button>
                <form is=save-data data-saver=objectSaver method=post data-action-template=o/{object_id}/edit.json data-confirm=削除します。 data-next=markAncestorArticleDeleted>
                  <input type=hidden name=user_status value=2><!-- deleted -->
                  <p>
                    <button type=submit class=delete-button>削除</button>
                </form>
                <p><a data-href-template={GROUP}/o/{object_id}/revisions>編集履歴</a>
                <hr>
                <p><a is=copy-url data-href-template={GROUP}/o/{object_id}/>URLをコピー</a>
                <p><a is=gr-jump-add data-href-template={GROUP}/o/{object_id}/ data-title-data-field=title>ジャンプリストに追加</a>
                <hr>
                <p><a href=/help#objects target=help>ヘルプ</a>
              </menu-main>
            </popup-menu>
          </header>
          <gr-article-main class=fullbody>
            <gr-html-viewer seamlessheight checkboxeditable data-objectid-field=object_id data-filled=objectid data-field=data />
          </gr-article-main>
          <footer class=object-info>
            <gr-stars data-field=object_id />

            <gr-article-status>
              <action-status stage-saver=保存中... ok=保存しました />
            </gr-article-status>
            <gr-action-status hidden
                stage-edit=保存中...
                ok=保存しました />

            <gr-object-meta>
              <gr-account-list data-data-field=assigned_account_ids title=担当者 />
              <gr-index-list data-data-field=index_ids nocurrentindex />
              <time data-field=created data-format=ambtime />
              (<time data-field=updated data-format=ambtime /> 編集)
            </gr-object-meta>
          </footer>

          <article-comments>
            <list-container loader=groupCommentLoader data-loader-parentobjectid-field=object.object_id loader-limit=5 data-filled="loader-parentobjectid" template=gr-comment-object reverse>
              <p class="operations pager">
                <button type=button class=list-next data-list-scroll=preserve hidden>もっと昔のコメント</button>
              </p>
              <action-status hidden stage-loader=読込中... />
              <list-main></list-main>
            </list-container>

            <details is=gr-comment-form data-parentobjectid>
              <summary>コメントを書く</summary>
            </details>

          </article-comments>
        </template>

          <article class="object new">
            <p class=operations>
              <button type=button class=edit-button>新しい記事を書く</button>
          </article>

        <list-main></list-main>

      <gr-action-status hidden stage-load=読込中... />
        <p class="operations pager">
          <button type=button class=next-page-button hidden>もっと昔</button>
    </gr-list-container>
  </template><!-- blog -->
  <template data-name=todos>
    <section>
      <header class=section data-gr-if-index-type="4 5"><!-- label milestone -->
        <h1><a data-href-template=/g/{group.group_id}/i/{index.index_id}/ data-field=index.title data-empty=■ /></h1>
        <gr-menu type=index />
      </header>
      
      <gr-list-container key=objects sortkey=updated src-limit=50 query class=todo-list>
        <template>
            <enum-value class=todo-state data-data-field=todo_state
                label-1=未完了 label-2=完了済
                label-undefined
            />
          <p class=main-line>
            <a data-href-template={GROUP}/o/{object_id}/>
              <span data-data-field=title data-empty=■ />
            </a>
          <p class=info-line>
            <gr-count data-data-field=checked_checkbox_count data-all-data-field=all_checkbox_count data-filled=all template=gr-count />
            <gr-timestamp>
              <time data-field=created data-format=ambtime />
              (<time data-field=updated data-format=ambtime /> 編集)
            </gr-timestamp>
            <gr-index-list data-data-field=index_ids indextype=5 title=マイルストーン />
            <gr-index-list data-data-field=index_ids indextype=4 title=ラベル />
            <gr-account-list data-data-field=assigned_account_ids title=担当者 />
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
          </list-query>
        </menu>

        <list-main/>

      <gr-action-status hidden stage-load=読込中... />
        <p class="operations pager">
          <button type=button class=next-page-button hidden>もっと昔</button>
      </gr-list-container>
    </section>
  </template><!-- todos -->
  <template data-name=fileset>
    <section>
      <header class=section>
        <h1 data-gr-if-index-subtype=image>アルバム</h1>
        <h1 data-gr-if-index-subtype=file>ファイルフォルダー</h1>
        <h1 data-gr-if-index-subtype=icon>アイコン集</h1>
        <h1 data-gr-if-index-subtype=stamp>スタンプセット</h1>
      </header>

      <details>
        <summary>ファイルを追加</summary>
        <gr-uploader data-indexid-field=index.index_id data-indexsubtype-field=index.subtype data-filled="indexid indexsubtype" listselector=.search-result />
      </details>

      <list-container loader=groupIndexLoader data-loader-indexid-field=index.index_id data-loader-indextype-field=index.index_type loader-limit=30 loader-withdata data-filled="loader-indexid loader-indextype" template=gr-fileset-list-item-file class="search-result fileset-file" data-gr-if-index-subtype=file>
        <list-main></list-main>
        <list-is-empty hidden>
          <p>このフォルダーは空です。</p>
        </list-is-empty>
        <action-status hidden stage-loader=読込中... />
        <p class="operations pager">
          <button type=button class=list-next hidden>もっと昔</button>
      </list-container>
      <list-container loader=groupIndexLoader data-loader-indexid-field=index.index_id data-loader-indextype-field=index.index_type loader-limit=36 loader-withdata data-filled="loader-indexid loader-indextype" template=gr-fileset-list-item-image class="search-result fileset-image" data-gr-if-index-subtype="image icon stamp">
        <list-main></list-main>
        <list-is-empty hidden>
          <p>このフォルダーは空です。</p>
        </list-is-empty>
        <action-status hidden stage-loader=読込中... />
        <p class="operations pager">
          <button type=button class=list-next hidden>もっと昔</button>
      </list-container>
    </section>
  </template><!-- fileset -->
</template-set>

<template-set name=gr-count>
  <template>
    <gr-count-line>
      <data data-field=value data-empty=0 />
      /
      <data data-field=all />
    </gr-count-line>
    <progress data-value-field=value data-max-field=all data-filled="max value" />
  </template>
</template-set>

<template-set name=gr-account-list-item>
  <template>
    <gr-account data-field=account_id>
      <a data-href-template=/g/{group_id}/account/{account_id}/>
        <img data-src-template=/g/{group_id}/account/{account_id}/icon class=icon alt>
        <gr-account-name data-field=name data-empty=■ />
      </a>
    </gr-account>
  </template>
</template-set>

<template-set name=gr-index-list-item>
  <template>
    <a data-href-template=/g/{index.group_id}/i/{index.index_id}/ data-field=index.title data-class-field=class data-style-field=style data-filled=style data-empty=■ />
  </template>
</template-set>

<template-set name=gr-select-icon>
  <template>
    <popup-menu>
      <button type=button>
        <figure>
          <img class=icon>
        </figure>
      </button>
      <menu-main>
        <gr-select-index type=icon empty=アイコン集がありません。 title=アイコン集 />

        <gr-index-viewer type=icon selectselector=gr-select-index selectancestor=gr-select-icon />

        <p>
          <button type=button class=generate-icon-button>
            自動生成
          </button>
        <p>
          <button type=button class=reset-icon-button>
            編集前に戻す
          </button>
      </menu-main>
    </popup-menu>
  </template>
</template-set>

<template-set name=gr-uploader>
  <template>
    <form method=post action=javascript: class=explicit>
      <gr-list-container>
        <template>
          <p><code data-field=file_name />
          (<unit-number data-field=file_size type=bytes />)
          <gr-action-status hidden
                    stage-create=作成中...
                    stage-upload=アップロード中...
                    stage-close=保存中...
                    stage-show=読み込み中...
                    ok=アップロード完了 />
        </template>
        <list-main/>
      </gr-list-container>

      <p>枠内にファイルをドロップしてもアップロードできます。

      <p class=operations>
        <input type=file name=file multiple hidden>
        <button type=button is=gr-uploader-button class=edit-button>アップロード...</button>
    </form>
  </template>
</template-set>

<template-set name=gr-comment-form>
  <template>
    <tab-set>
      <tab-menu/>
      <section>
        <h1>テキスト</h1>
        <form is=save-data data-saver=newObjectSaver action method=post data-next="reloadCommentList reset resetCalledEditor grFocus:[name=body]" data-gr-emptybodyerror=本文がありません。 class=comment-form>
      <input type=hidden name=parent_object_id data-field=parent_object_id>
      <p>
        <gr-account self>
          <img data-src-template=/g/{group_id}/account/{account_id}/icon class=icon data-alt-field=name data-title-field=name data-filled=alt>
        </gr-account>
        <textarea name=body placeholder=コメント本文></textarea>
        <input type=hidden name=body_type value=2><!-- plaintext -->
        <p class=operations>
          <span class=submit-buttons>
            <button type=submit class=save-button>投稿する</>
            <button type=submit class=save-button data-gr-if-parent-todo name=todo_state value=2>投稿・完了</button>
            <button type=submit class=save-button data-gr-if-parent-todo name=todo_state value=1>投稿・未完了に戻す</button>
          </span>

          <span class=submit-options>
            <gr-group>
              <img data-src-template=/g/{group_id}/icon class=icon alt>
              <gr-group-name data-field=title data-filling>グループ</>
            </gr-group>
            <span>
              通知送信先:
              <gr-called-editor template=gr-called-editor />
            </span>
          </span>

          <span class=submit-status>
            <action-status stage-saver=投稿中... />
          </span>
        </form>
      </section>
    </tab-set>
  </template>
</template-set>

<template-set name=page-object-index>
  <template>
    <section>
      <header class=section>
        <h1><time data-field=object.timestamp data-format=date /></h1>
      </header>

      <big-banner data-gr-if-revision>
        <p>
          <gr-account data-field=object.revision_author_account_id>
            <a data-href-template=/g/{group_id}/account/{account_id}/>
              <img data-src-template=/g/{group_id}/account/{account_id}/icon class=icon alt>
              <gr-account-name data-field=name data-empty=■ />
            </a>
          </gr-account>
          による
          <time data-field=object.updated />
          版を表示しています。

        <p class=operations>
          <a href=./>最新版</a>
          <a href=revisions>編集履歴</a>
      </big-banner>
      
      <gr-list-container key=objects listitemtype=object>
        <template class=object>
          <header>
            <div class=edit-by-dblclick>
              <enum-value class=todo-state data-data-field=todo_state
                  label-1=未完了 label-2=完了済
                  label-undefined
              />
              <h1><a data-data-field=title data-empty=■ data-href-template={GROUP}/o/{object_id}/ /></h1>
            </div>
            <popup-menu>
              <button type=button title=メニュー>
                <button-label>
                  メニュー
                </button-label>
              </button>
              <menu-main>
                <p><a data-href-template={GROUP}/o/{object_id}/>記事ページ</a>
                <hr>
                <p><button type=button class=edit-button>編集</button>
                <form is=save-data data-saver=objectSaver method=post data-action-template=o/{object_id}/edit.json data-confirm=削除します。 data-next=markAncestorArticleDeleted>
                  <input type=hidden name=user_status value=2><!-- deleted -->
                  <p><button type=submit class=delete-button>削除</button>
                </form>
                <p><a data-href-template={GROUP}/o/{object_id}/revisions>編集履歴</a>
                <hr>
                <p><a is=copy-url data-href-template={GROUP}/o/{object_id}/>URLをコピー</a>
                <p><a is=gr-jump-add data-href-template={GROUP}/o/{object_id}/ data-title-data-field=title>ジャンプリストに追加</a>
                <hr>
                <p><a href=/help#objects target=help>ヘルプ</a>
              </menu-main>
            </popup-menu>
          </header>
          <gr-article-main class=fullbody>
            <gr-html-viewer seamlessheight checkboxeditable data-objectid-field=object_id data-filled=objectid data-field=data />
          </gr-article-main>
          <footer class=object-info>
            <gr-stars data-field=object_id />

            <gr-article-status>
              <action-status stage-saver=保存中... ok=保存しました />
            </gr-article-status>
            <gr-action-status hidden
                stage-edit=保存中...
                ok=保存しました />

            <gr-object-meta>
              <gr-account-list data-data-field=assigned_account_ids title=担当者 />
              <gr-index-list data-data-field=index_ids nocurrentindex />
              <time data-field=created data-format=ambtime />
              (<time data-field=updated data-format=ambtime /> 編集)
            </gr-object-meta>
          </footer>

          <article-comments>
            <list-container loader=groupCommentLoader data-loader-parentobjectid-field=object.object_id loader-limit=30 data-filled="loader-parentobjectid" template=gr-comment-object reverse>
              <p class="operations pager">
                <button type=button class=list-next data-list-scroll=preserve hidden>もっと昔のコメント</button>
              </p>
              <action-status hidden stage-loader=読込中... />
              <list-main></list-main>
            </list-container>

            <details is=gr-comment-form data-parentobjectid>
              <summary>コメントを書く</summary>
            </details>
          </article-comments>
        </template>

        <list-main></list-main>
        <gr-action-status hidden stage-load=読込中... />
      </gr-list-container>
    </section>
  </template>
</template-set>

<template-set name=gr-comment-object templateselector=grCommentObjectTemplateSelector>
  <template>
    <article itemscope itemtype=http://schema.org/Comment>
      <gr-object-author template=gr-object-author data-field=object.data />
      <gr-stars data-field=object.object_id />
      <gr-comment-main class=fullbody>
        <gr-html-viewer seamlessheight checkboxeditable data-objectid-field=object.object_id data-filled=objectid data-field=object.data />
        <gr-comment-info>
          <gr-article-status>
            <action-status stage-saver=保存中... ok=保存しました />
          </gr-article-status>
          <a href data-href-template="/g/{object.group_id}/o/{object.object_id}/" class=timestamp>
            <time data-field=object.timestamp data-format=ambtime />
            (<time data-field=object.updated data-format=ambtime />)
          </a>
        </gr-comment-info>
      </gr-comment-main>
    </article>
  </template>
  <template data-name=plaintextbody>
    <article itemscope itemtype=http://schema.org/Comment>
      <gr-object-author template=gr-object-author data-field=object.data />
      <gr-stars data-field=object.object_id />
      <gr-comment-main class=plaintextbody>
        <gr-plaintext-body data-field=object.data.body />
        <gr-comment-info>
          <a href data-href-template="/g/{object.group_id}/o/{object.object_id}/" class=timestamp>
            <time data-field=object.timestamp data-format=ambtime />
            (<time data-field=object.updated data-format=ambtime />)
          </a>
        </gr-comment-info>
      </gr-comment-main>
    </article>
  </template>
  <template data-name=empty />
  <template data-name=close>
    <gr-action-log>
      <p><gr-object-author template=gr-object-author data-field=object.data />
      閉じました。
      <time data-field=object.created data-format=ambtime />
    </gr-action-log>
  </template>
  <template data-name=reopen>
    <gr-action-log>
      <p><gr-object-author template=gr-object-author data-field=object.data />
      開き直しました。
      <time data-field=object.created data-format=ambtime />
    </gr-action-log>
  </template>
  <template data-name=changed>
    <gr-action-log>
      <p><gr-object-author template=gr-object-author data-field=object.data />
      記事情報を変更しました。
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
      <time data-field=object.created data-format=ambtime />
    </gr-action-log>
  </template>
  <template data-name=trackback class=trackback>
    <gr-action-log>
      <p><time data-field=object.created data-format=ambtime />に参照されました。
      <gr-object-ref data-field=object.data.body_data.trackback.object_id />
    </gr-action-log>
  </template>
</template-set>

<template-set name=page-object-revisions>
  <template title=編集履歴 class="is-subpage subpage-back-to-subdirectory">
    <section>
      <header class=section>
        <h1><bdi data-field=object.title data-empty=■ />の編集履歴</h1>
            <popup-menu>
              <button type=button title=メニュー>
                <button-label>
                  メニュー
                </button-label>
              </button>
              <menu-main>
                <p><a data-href-template=./>記事ページ</a>
                <hr>
                <!-- XXX edit, delete -->
                <p><a href=revisions>編集履歴</a>
                <hr>
                <p><a is=copy-url data-href-template=./>URLをコピー</a>
                <p><a is=gr-jump-add data-href-template=./ data-title-data-field=title>ジャンプリストに追加</a>
                <hr>
                <p><a href=/help#objects target=help>ヘルプ</a>
              </menu-main>
            </popup-menu>
      </header>
      
      <list-container loader=groupLoader data-src-template=o/{object.object_id}/revisions.json?with_revision_data=1 key=items template=object-revision type=table class=main-table>
        <table>
          <thead>
            <tr>
              <th>日時
              <th>編集者
              <th>変更点
          <tbody>
        </table>
        <action-status hidden stage-loader=読込中...></action-status>
        <p class=operations>
          <button type=button class=list-next>もっと昔</button>
      </list-container>
    </section>
  </template>
</template-set>

<template-set name=object-revision>
  <template>
    <td>
      <a data-href-template=./?object_revision_id={object_revision_id}>
        <time data-field=created />
      </a>
    <td>
      <gr-account data-field=author_account_id>
        <a data-href-template=../../account/{account_id}/>
          <img data-src-template=../../account/{account_id}/icon class=icon alt>
          <gr-account-name data-field=name data-empty=■ />
        </a>
      </gr-account>
    <td>
      <XXX-multi-enum data-field=revision_data.changes.fields
        label-title=題名
        label-body=本文
        label-body_type
        label-timestamp=日付
        label-index_ids=所属
        label-user_status=公開状態
        label-called=記事通知
      />
      <enum-value data-field=revision_data.changes.action
          label-new=新規作成
          label-delete=削除
          label-undefined />
  
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
            <enum-value class=todo-state data-data-field=todo_state
                label-1=未完了 label-2=完了済
                label-undefined
            />
            <popup-menu>
              <button type=button title=メニュー>
                <button-label>
                  メニュー
                </button-label>
              </button>
              <menu-main>
                <p><a data-href-template={GROUP}/o/{object_id}/>記事ページ</a>
                <hr>
                <p><button type=button class=edit-button>編集</button>
                <form is=save-data data-saver=objectSaver method=post data-action-template=o/{object_id}/edit.json data-confirm=削除します。 data-next=markAncestorArticleDeleted>
                  <input type=hidden name=user_status value=2><!-- deleted -->
                  <p><button type=submit class=delete-button>削除</button>
                </form>
                <p><a data-href-template={GROUP}/o/{object_id}/revisions>編集履歴</a>
                <hr>
                <p><a is=copy-url data-href-template={GROUP}/o/{object_id}/>URLをコピー</a>
                <p><a is=gr-jump-add data-href-template={GROUP}/o/{object_id}/ data-title-data-field=title>ジャンプリストに追加</a>
                <hr>
                <p><a href=/help#objects target=help>ヘルプ</a>
              </menu-main>
            </popup-menu>
          </header>
          <gr-article-main class=fullbody>
            <gr-html-viewer seamlessheight checkboxeditable data-objectid-field=object_id data-filled=objectid data-field=data />
          </gr-article-main>
          <footer class=object-info>
            <gr-stars data-field=object_id />

            <gr-article-status>
              <action-status stage-saver=保存中... ok=保存しました />
            </gr-article-status>
            <gr-action-status hidden
                stage-edit=保存中...
                ok=保存しました />

            <gr-object-meta>
              <gr-account-list data-data-field=assigned_account_ids title=担当者 />
              <gr-index-list data-data-field=index_ids nocurrentindex />
              <time data-field=created data-format=ambtime />
              (<time data-field=updated data-format=ambtime /> 編集)
            </gr-object-meta>
          </footer>

          <article-comments>
            <list-container loader=groupCommentLoader data-loader-parentobjectid-field=object.object_id loader-limit=30 data-filled="loader-parentobjectid" template=gr-comment-object reverse>
              <p class="operations pager">
                <button type=button class=list-next data-list-scroll=preserve hidden>もっと昔のコメント</button>
              </p>
              <action-status hidden stage-loader=読込中... />
              <list-main></list-main>
            </list-container>

            <details is=gr-comment-form data-parentobjectid>
              <summary>コメントを書く</summary>
            </details>

          </article-comments>
        </template>

        <list-main></list-main>

        <list-is-empty hidden>
          <p>記事はまだありません。</p>

          <article class="object new">
            <p class=operations>
              <button type=button class=edit-button>記事を書く</button>
          </article>
        </list-is-empty>

        <gr-action-status hidden stage-load=読込中... />
      </gr-list-container>

      <article-comments class=section>
        <list-container loader=groupCommentLoader data-loader-indexid-field=index.index_id data-loader-parentwikiname-field=wiki.name loader-limit=30 data-filled="loader-indexid loader-parentwikiname" template=gr-comment-object reverse>
          <p class="operations pager">
            <button type=button class=list-next data-list-scroll=preserve hidden>もっと昔のコメント</button>
          </p>
          <action-status hidden stage-loader=読込中... />
          <list-main></list-main>
        </list-container>
      </article-comments>

      <footer class=section>
        <p><a data-href-template=/g/{group.group_id}/search?q={url:wiki.name}>「<bdi data-field=wiki.name />」を含む記事を検索する</a></p>
      </footer>
    </section>
  </template>
</template-set>

<template-set name=gr-object-ref>
  <template>
    <a href data-href-template=/g/{object.group_id}/o/{object.object_id}/>
      <gr-object-ref-header>
        <enum-value class=todo-state data-field=object.data.todo_state
            label-1=未完了 label-2=完了済
            label-undefined
        />
        <cite data-field=object.data.title data-empty=■ />
        <time data-field=object.created />
      </gr-object-ref-header>
      <body-snippet data-field=object.snippet />
    </a>
  </template>
</template-set>

<template-set name=gr-stars>
  <template>
    <button type=button class=add-star-button title="&#x2B50;をつける">&#x2B50;+</button>
    <gr-star-list></gr-star-list>
    <popup-menu>
      <button type=button title=メニュー>
        <button-label>メニュー</button-label>
      </button>
      <menu-main>
        <p><button type=button class=remove-star-button>&#x2B50;を消す</button>
        <p><a href=/help#stars target=help>ヘルプ</a>
      </menu-main>
    </popup-menu>
  </template>
</template-set>

<template-set name=gr-star-item templateselector=gr-star-item-selector>
  <template>
    <gr-account data-field=author_account_id>
      <a data-href-template=/g/{group_id}/account/{account_id}/>
        <img data-src-template=/g/{group_id}/account/{account_id}/icon data-alt-field=name data-title-field=name data-filled=alt class=icon>
      </a>
    </gr-account>
    <gr-star-count data-field=count />
  </template>
  <template data-name=single>
    <gr-account data-field=author_account_id>
      <a data-href-template=/g/{group_id}/account/{account_id}/>
        <img data-src-template=/g/{group_id}/account/{account_id}/icon data-alt-field=name data-title-field=name data-filled=alt class=icon>
      </a>
    </gr-account>
  </template>
</template-set>

<template-set name=gr-tooltip-box-object>
  <template>
    <gr-object-ref data-field=data.object_id />
  </template>
</template-set>

  <template class=body-template id=hatena-star-template>
    <a href data-href-template=https://profile.hatena.ne.jp/{name}/ referrerpolicy=no-referrer data-title-template=" {name} {quote}" data-class-template=star-type-{type}>
      <span>★</span><!--
      --><img data-src-template=https://cdn1.www.st-hatena.com/users/{name2}/{name}/profile.gif data-alt-template={name} referrerpolicy=no-referrer class=hatena-user-icon><!--
      --><star-count data-field=count data-class-template=star-count-{count} />
    </a>
  </template>

<template-set name=gr-object-author templateselector=gr-object-author>
  <template/>
  <template data-name=account>
    <gr-account data-field=author_account_id>
      <a data-href-template=/g/{group_id}/account/{account_id}/>
        <img data-src-template=/g/{group_id}/account/{account_id}/icon class=icon alt>
        <gr-account-name data-field=name data-empty=■ />
      </a>
    </gr-account>
  </template>
  <template data-name=hatenaguest>
    <gr-person><bdi data-field=author_name /></gr-person>
  </template>
  <template data-name=hatenauser>
    <gr-person hatena>
      <img data-src-template=https://cdn.www.st-hatena.com/users/{author_hatena_id_2}/{author_hatena_id}/profile.gif referrerpolicy=no-referrer class=icon alt>
      <code>id:<span data-field=author_hatena_id /></code>
    </gr-person>
  </template>
</template-set>
  
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
            <p><a href is=copy-url>URLをコピー</a>
            <p><a href is=gr-jump-add>ジャンプリストに追加</a>
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
      
      <gr-list-container key=objects listitemtype=object>
        <template class=object>
          <header>
            <div class=edit-by-dblclick>
              <enum-value class=todo-state data-data-field=todo_state
                  label-1=未完了 label-2=完了済
                  label-undefined
              />
              <h1><a data-data-field=title data-empty=■ data-href-template={GROUP}/o/{object_id}/ /></h1>
            </div>
            <popup-menu>
              <button type=button title=メニュー>
                <button-label>
                  メニュー
                </button-label>
              </button>
              <menu-main>
                <p><a data-href-template={GROUP}/o/{object_id}/>記事ページ</a>
                <hr>
                <p><button type=button class=edit-button>編集</button>
                <form is=save-data data-saver=objectSaver method=post data-action-template=o/{object_id}/edit.json data-confirm=削除します。 data-next=markAncestorArticleDeleted>
                  <input type=hidden name=user_status value=2><!-- deleted -->
                  <p><button type=submit class=delete-button>削除</button>
                </form>
                <p><a data-href-template={GROUP}/o/{object_id}/revisions>編集履歴</a>
                <hr>
                <p><a is=copy-url data-href-template={GROUP}/o/{object_id}/>URLをコピー</a>
                <p><a is=gr-jump-add data-href-template={GROUP}/o/{object_id}/ data-title-data-field=title>ジャンプリストに追加</a>
                <hr>
                <p><a href=/help#objects target=help>ヘルプ</a>
              </menu-main>
            </popup-menu>
          </header>
          <gr-article-main class=fullbody>
            <gr-html-viewer seamlessheight checkboxeditable data-objectid-field=object_id data-filled=objectid data-field=data />
          </gr-article-main>
          <footer class=object-info>
            <gr-stars data-field=object_id />

            <gr-article-status>
              <action-status stage-saver=保存中... ok=保存しました />
            </gr-article-status>
            <gr-action-status hidden
                stage-edit=保存中...
                ok=保存しました />

            <gr-object-meta>
              <gr-account-list data-data-field=assigned_account_ids title=担当者 />
              <gr-index-list data-data-field=index_ids nocurrentindex />
              <time data-field=created data-format=ambtime />
              (<time data-field=updated data-format=ambtime /> 編集)
            </gr-object-meta>
          </footer>

          <article-comments>
            <list-container loader=groupCommentLoader data-loader-parentobjectid-field=object.object_id loader-limit=30 data-filled="loader-parentobjectid" template=gr-comment-object reverse>
              <p class="operations pager">
                <button type=button class=list-next data-list-scroll=preserve hidden>もっと昔のコメント</button>
              </p>
              <action-status hidden stage-loader=読込中... />
              <list-main></list-main>
            </list-container>

            <details is=gr-comment-form data-parentobjectid>
              <summary>コメントを書く</summary>
            </details>

          </article-comments>
        </template>

        <list-main></list-main>
        <gr-action-status hidden stage-load=読込中... />
      </gr-list-container>
    </section>
  </template>
</template-set>
  
<template-set name=page-my-config>
  <template title=グループ個人設定 class=is-subpage>
    <section>
      <header class=section>
        <h1>グループ個人設定</h1>
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
                <gr-select-icon name=icon_object_id
                    data-src-template=/g/{group.group_id}/account/{account.account_id}/icon
                    generationtextselector="input[name=name]" />
        </table>
        <p class=operations>
          <button type=submit class=save-button>保存する</>
          <action-status hidden stage-saver=保存中... ok=保存しました。 />
      </form>

      <gr-if-welcome>
        <p>グループに参加する準備は以上です。
        
        <p class=operations>
          <a data-href-template=/g/{group.group_id}/guide class=button>グループのガイドへ</a>
      </gr-if-welcome>

      <gr-if-not-welcome>
        <div id=account-guide>
          <p id=account-guide-link><a data-href-template=/g/{group.group_id}/account/{account.account_id}/#guide>自己紹介ページ</a>があります。
          <form id=account-guide-create-form is=save-data data-saver=groupSaver method=post action=my/edit.json data-next="reloadGroupInfo">
            <p>自己紹介ページがありません。
            <gr-create-object name=guide_object_id />
            <p class=operations>
              <button type=submit class=save-button>作成する</>
              <action-status hidden stage-saver=作成中... ok=作成しました。 />
          </form>
        </div>

        <p><a href=/jump>ジャンプリストの編集</a>
        <p><a href=/dashboard/receive>通知の受信設定</a>
      </gr-if-not-welcome>
    </section>
  </template>
</template-set>

<template-set name=editor-sub-window-content>
  <template>
    <sub-window-minimized>
      <gr-sub-window-menu>
        <gr-sub-window-label>編集中 <cite data-empty=■ data-field=title data-title-field=title></cite></gr-sub-window-label>
        <gr-sub-window-buttons>
          <button type=button data-sub-window-action=unminimize title=画面全体に表示>↑</button>
        </gr-sub-window-buttons>
      </gr-sub-window-menu>
    </sub-window-minimized>
    <gr-sub-window-menu>
      <gr-sub-window-buttons>
        <button type=button data-sub-window-action=minimize title=最小化>↓</button>
      </gr-sub-window-buttons>
    </gr-sub-window-menu>
    <edit-container></edit-container>
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

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
<https://www.gnu.org/licenses/>.

-->
