
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

              <button type=button data-action=insertCheckbox title=チェック項目>☑</button
              ><button type=button data-action=panel data-value=image-list title=画像>&#x1F5BC;</button
              ><button type=button data-action=panel data-value=file-list title=ファイル>&#x1F4C4;</button>
            </menu>
            <gr-html-viewer mode=editor
                prompt-link-url=リンク先のURLを指定してください。
                prompt-link-wiki-name=リンク先のWiki名を指定してください。
            />
          </body-control-tab>
          <body-control-tab name=textarea hidden>
            <textarea />
          </body-control-tab>
          <body-control-tab name=preview hidden>
            <gr-html-viewer mode=preview />
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
                      <option value=4>平文
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

      <p>
        <gr-group>
          <img data-src-template=/g/{group_id}/icon class=icon alt>
          <gr-group-name data-field=title data-filling>グループ</>
        </gr-group>

        <span>
          通知送信先:
          <gr-called-editor template=gr-called-editor />
        </span>
    </form>
    <aside hidden/>
  </with-sidebar>
</template>

<template-set name=gr-called-editor>
  <template>
    <gr-called-editor-selected placeholder=なし />
    <popup-menu>
      <button type=button>
        <button-label>変更</button-label>
      </button>
      <menu-main>
        <p data-called-type=if-in-thread hidden>
          <label title="親記事を書いた人やコメントを書いた人など">
            <input type=checkbox checked data-called-type=category value=thread>
            <img src=/images/person.svg class=icon alt>
            スレッドの購読者 (<data data-called-type=thread-notified-count>?</data>)
          </label>
          <!-- XXX
          (<button type=button class=expand-button data-called-type=thread-notified-expand>展開する</button>)
          -->
        </p>
        <gr-called-editor-menu-items/>
      </menu-main>
    </popup-menu>
  </template>
</template-set>

<template-set name=gr-called-editor-menu-item>
  <template>
    <p>
    <label>
          <input type=checkbox data-called-type=account_id data-field=account_id>
          <gr-account data-field=account_id>
            <img data-src-template=/g/{group_id}/account/{account_id}/icon class=icon alt>
            <gr-account-name data-field=name data-filling>アカウント</gr-account-name>
          </gr-account>
    </label>
    <small class=if-sent>
      <time data-field=last_sent />に送信済
    </small>
  </template>
</template-set>

<template-set name=gr-called-editor-selected-item>
  <template>
    <gr-account data-field=account_id>
      <img data-src-template=/g/{group_id}/account/{account_id}/icon class=icon alt data-title-field=name>
    </gr-account>
  </template>
</template-set>

<template-set name=gr-called-editor-selected-category-thread>
  <template>
    <img src=/images/person.svg class=icon alt=購読者 title="スレッドの購読者">
  </template>
</template-set>

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

  <gr-list-container type=$with id=index-list src=i/list.json key=index_list itemkey=index_id />
  <gr-list-container type=$with id=member-list src=members/list.json key=members itemkey=account_id accounts />

<template id=template-panel-image-list data-selectobject-command=insertImage>
  <gr-select-index type=image empty=アルバムがありません。 title=アルバム />
  <gr-index-viewer type=image selectselector=gr-select-index selectancestor=section />
</template>

<template id=template-panel-file-list data-selectobject-command=insertFile>
  <gr-select-index type=file empty=ファイルフォルダーがありません。 title=ファイルフォルダー />
  <gr-index-viewer type=file selectselector=gr-select-index selectancestor=section />
</template>
