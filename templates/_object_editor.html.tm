
<template id=edit-form-template>
  <form method=post action=javascript:>
    <header>
      <p><input name=title placeholder=題名>
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

        <button type=button data-action=link data-command=url title="Web サイトにリンク">://</button
        ><button type=button data-action=link data-command=wiki-name title="Wiki ページにリンク">[[]]</button>

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
                <popup-menu>
                  <button type=button title=変更>...</button>
                  <menu hidden>
                    <list-control-list editable template=edit />
                  </menu>
                </popup-menu>
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
              <th>里程標
              <td>
                <list-control-list template=view filters='[{"key": ["data", "index_type"], "value": "5"}]' data-empty=(なし) />
                <popup-menu>
                  <button type=button title=変更>...</button>
                  <menu hidden>
                    <list-control-list editable template=edit-milestone clear-template=edit-milestone-clear filters='[{"key": ["data", "index_type"], "value": "5"}]' />
                  </menu>
                </popup-menu>
            <tr>
              <th>ラベル
              <td>
                <list-control-list template=view filters='[{"key": ["data", "index_type"], "value": "4"}]' data-empty=(なし) />
                <popup-menu>
                  <button type=button title=変更>...</button>
                  <menu hidden>
                    <list-control-list editable template=edit filters='[{"key": ["data", "index_type"], "value": "4"}]' />
                  </menu>
                </popup-menu>
            <tr>
              <th>日記、Wiki、TODOリスト
              <td>
                <list-control-list template=view filters='[{"key": ["data", "index_type"], "valueIn": {"1": true, "2": true, "3": true}}]' data-empty=(なし) />
                <popup-menu>
                  <button type=button title=変更>...</button>
                  <menu hidden>
                    <list-control-list editable template=edit filters='[{"key": ["data", "index_type"], "valueIn": {"1": true, "2": true, "3": true}}]' />
                  </menu>
                </popup-menu>
        </table>
      </list-control>
    </details>
  </form>
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

  <list-container type=$with id=index-list src=i/list.json key=index_list itemkey=index_id />
  <list-container type=$with id=member-list src=members.json key=members itemkey=account_id accounts />
