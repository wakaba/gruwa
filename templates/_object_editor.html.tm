
<template id=edit-form-template>
  <with-sidebar>
    <form method=post action=javascript:>
      <header>
        <p><input name=title placeholder=題名>
      </header>
      <main>
        <body-control>
          <menu class=tab-buttons>
            <a href=javascript: class=active data-name=iframe>見たまま</a>
            <a href=javascript: data-name=textarea>ソース</a>
            <a href=javascript: data-name=preview>プレビュー</a>
            <a href=javascript: data-name=config>設定</a>
          </menu>
          <body-control-tab name=iframe>
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

          <button type=button data-action=link data-command=url title="Web サイトにリンク">://</button
          ><button type=button data-action=link data-command=wiki-name title="Wiki ページにリンク">[[]]</button>

              <button type=button data-action=insertControl data-value=checkbox title=チェック項目>☑</button
              ><button type=button data-action=panel data-value=image-list title=画像>&#x1F3A8;</button
              ><button type=button data-action=panel data-value=file-list title=ファイル>&#x1F4C4;</button>
            </menu>
            <iframe />
          </body-control-tab>
          <body-control-tab name=textarea hidden>
            <textarea />
          </body-control-tab>
          <body-control-tab name=preview hidden>
            <iframe/>
          </body-control-tab>
          <body-control-tab name=config hidden>
            <table class=config>
              <tbody>
                <tr>
                  <th><label data-bc-for=body_source_type>編集形式</label>
                  <td>
                    <select data-bc-name=body_source_type>
                      <option value=0>見たまま (推奨)
                      <!-- 1 SWML -->
                      <!-- 2 Markdown -->
                      <option value=3>はてな記法
                    </select>
                    (<a href=/help#syntaxes target=help>ヘルプ</a>)
                    <p><strong>注意</strong>: 
                    編集形式ごとに表現できる内容には違いがあります。
                    後から編集形式を変更すると、情報が失われることがあります。
            </table>
          </body-control-tab>
        </body-control>
      </main>
      <footer>
      <p class=operations>
        <button type=submit class=save-button>保存する</button>
        <button type=button class=cancel-button>取り消し</button>
        <gr-action-status hidden
            stage-loader=読込中...
            stage-saver=変換中...
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
            <th>担当者
            <td>
              <input type=hidden name=edit_assigned_account_id value=1>
              <list-control name=assigned_account_id key=assigned_account_ids list=member-list>
                <template data-name=view>
                  <list-item-label data-data-account-field=name />
                </template>
                <template data-name=edit>
                  <label>
                    <input type=checkbox data-data-field=account_id data-checked-field=selected>
                    <span data-data-account-field=name></span>
                  </label>
                </template>

                <list-control-list template=view data-empty=(なし) />
                <gr-popup-menu>
                  <button type=button title=変更>...</button>
                  <menu hidden>
                    <list-control-list editable template=edit />
                  </menu>
                </gr-popup-menu>
              </list-control>
      </table>

      <input type=hidden name=edit_index_id value=1>
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
            <input type=radio name=MILESTONE checked value>
            なし
          </label>
        </template>

        <table class=config>
          <tbody>
            <tr>
              <th>マイルストーン
              <td>
                <list-control-list template=view filters='[{"key": ["data", "index_type"], "value": "5"}]' data-empty=(なし) />
                <gr-popup-menu>
                  <button type=button title=変更>...</button>
                  <menu hidden>
                    <list-control-list editable template=edit-milestone clear-template=edit-milestone-clear filters='[{"key": ["data", "index_type"], "value": "5"}]' />
                  </menu>
                </gr-popup-menu>
            <tr>
              <th>ラベル
              <td>
                <list-control-list template=view filters='[{"key": ["data", "index_type"], "value": "4"}]' data-empty=(なし) />
                <gr-popup-menu>
                  <button type=button title=変更>...</button>
                  <menu hidden>
                    <list-control-list editable template=edit filters='[{"key": ["data", "index_type"], "value": "4"}]' />
                  </menu>
                </gr-popup-menu>
            <tr>
              <th>日記、Wiki、TODOリスト
              <td>
                <list-control-list template=view filters='[{"key": ["data", "index_type"], "valueIn": {"1": true, "2": true, "3": true}}]' data-empty=(なし) />
                <gr-popup-menu>
                  <button type=button title=変更>...</button>
                  <menu hidden>
                    <list-control-list editable template=edit filters='[{"key": ["data", "index_type"], "valueIn": {"1": true, "2": true, "3": true}}]' />
                  </menu>
                </gr-popup-menu>
        </table>
      </list-control>
    </details>
    </form>
    <aside hidden/>
  </with-sidebar>
</template>

  <template id=link-edit-template class=body-edit-template>
    <a href data-href-field=href class=open-button target=_blank rel="noreferrer noopener">
      <code data-field=host data-title-field=href hidden></code>
      <span data-field=wikiName hidden />
    </a>
    <button type=button class=edit-button
        data-url-prompt=リンク先のURLを指定してください。
        data-wiki-name-prompt=リンク先のWiki名を指定してください。
        title=リンク先を編集>編集</button>
  </template>
  <template id=edit-texts class=body-edit-template
      data-link-url-prompt=リンク先のURLを指定してください。
      data-link-wiki-name-prompt=リンク先のWiki名を指定してください。 />

  <gr-list-container type=$with id=index-list src=i/list.json key=index_list itemkey=index_id />
  <gr-list-container type=$with id=member-list src=members/list.json key=members itemkey=account_id accounts />

<template id=template-panel-image-list>
  <run-action name=installPrependNewObjects />

  <gr-list-container src=i/list.json?index_type=6&subtype=image
      key=index_list sortkey=updated
      loaded-actions=clickFirstButton>
    <template>
      <button type=button data-command=setListIndex data-value-template={index_id} data-field=title />
    </template>
    <list-main/>
    <list-is-empty hidden>
      このグループには<a href=/help#fileset-image target=help>アルバム</a>がありません。
    </list-is-empty>
    <gr-action-status hidden stage-load=読み込み中... />
  </gr-list-container>

  <panel-main hidden>
    <details>
      <summary>新しい画像</summary>
      <form action=javascript: method=post data-form-type=uploader data-context-template={index_id}>
        <gr-list-container>
          <template>
            <p><code data-data-field=file_name />
            (<unit-number data-data-field=file_size type=bytes />)
            <p><gr-action-status hidden
                    stage-create=作成中...
                    stage-upload=アップロード中...
                    stage-close=保存中...
                    stage-show=読み込み中...
                    ok=アップロード完了 />
          </template>
          <list-main/>
        </gr-list-container>
        <p class=operations>
          <input type=file name=file multiple hidden accept=image/*>
          <button type=button name=upload-button class=edit-button>アップロード...</button>
      </form>
    </details>

    <gr-list-container disabled
        data-src-template="o/get.json?index_id={index_id}&limit=9"
        key=objects sortkey=timestamp,created
        added-actions=editCommands>
      <template>
        <button type=button
            data-edit-command=insertImage
            data-value-template={GROUP}/o/{object_id}>
          <img src data-src-template={GROUP}/o/{object_id}/image>
        </button>
      </template>
      <list-main/>
      <gr-action-status hidden stage-load=読み込み中... />
      <p class="operations pager">
        <button type=button class=next-page-button hidden>もっと昔</button>
    </gr-list-container>
  </panel-main>

</template>

<template id=template-panel-file-list>
  <run-action name=installPrependNewObjects />

  <gr-list-container src=i/list.json?index_type=6&subtype=file
      key=index_list sortkey=updated
      loaded-actions=clickFirstButton>
    <template>
      <button type=button data-command=setListIndex data-value-template={index_id} data-field=title />
    </template>
    <list-main/>
    <list-is-empty hidden>
      このグループには<a href=/help#fileset-file target=help>ファイルアップローダー</a>がありません。
    </list-is-empty>
    <gr-action-status hidden stage-load=読み込み中... />
  </gr-list-container>

  <panel-main hidden>
    <details>
      <summary>新しいファイル</summary>
      <form action=javascript: method=post data-form-type=uploader data-context-template={index_id}>
        <gr-list-container>
          <template>
            <p><code data-data-field=file_name />
            (<unit-number data-data-field=file_size type=bytes />)
            <p><gr-action-status hidden
                    stage-create=作成中...
                    stage-upload=アップロード中...
                    stage-close=保存中...
                    stage-show=読み込み中...
                    ok=アップロード完了 />
          </template>
          <list-main/>
        </gr-list-container>
        <p class=operations>
          <input type=file name=file multiple hidden>
          <button type=button name=upload-button class=edit-button>アップロード...</button>
      </form>
    </details>

    <gr-list-container disabled
        data-src-template="o/get.json?index_id={index_id}&limit=10&with_data=1"
        key=objects sortkey=timestamp,created
        added-actions=editCommands>
      <template>
        <button type=button
            data-edit-command=insertFile
            data-value-template={GROUP}/o/{object_id}
            data-data-field=file_name>
        </button>
      </template>
      <list-main/>
      <gr-action-status hidden stage-load=読み込み中... />
      <p class="operations pager">
        <button type=button class=next-page-button hidden>もっと昔</button>
    </gr-list-container>
  </panel-main>

</template>
