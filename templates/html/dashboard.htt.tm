
<!-- also in group.htt.tm -->
<template-set name=mn-email>
  <template>
    <gr-mn-main>
      メールアドレスが登録されていません。
      <a href=/dashboard/receive#emails class=main-button>登録する</a>
    </gr-mn-main>
    <button type=button class=cancel-button title="今後このメッセージを表示しない">×</button>
  </template>
</template-set>

<!-- also in group.htt.tm -->
<template-set name=mn-push>
  <template>
    <gr-mn-main>
      通知の受信設定がありません。
      <a href=/dashboard/receive#notifications class=main-button>設定する</a>
    </gr-mn-main>
    <button type=button class=cancel-button title="今後このメッセージを表示しない">×</button>
  </template>
</template-set>

<!-- also in group.htt.tm -->
<template-set name=gr-navigate-external>
  <template>
    <p>外部 (<code data-field=origin></code>) に移動しようとしています。
    <p class=buttons>
      <a data-href-field=href target=_top rel="noreferrer" class=main-button>このまま移動する</a>
      <a data-href-field=href target=_blank rel="noreferrer noopener" class=main-button>別窓で開く</a>
      <a href=javascript: class="main-button">移動しない</a>
  </template>
</template-set>

<!-- also in group.htt.tm -->
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

<template-set name=gr-menu-dashboard>
  <template>
    <p><a data-href-template=/dashboard>トップ</a>
    <p><a href=/help#dashboard target=help>ヘルプ</a>
    <p><a href=/terms target=help>利用規約</a>
  </template>
</template-set>

<template-set name=page-dashboard>
  <template title=ダッシュボード>

    <ul class=main-menu-list>

      <li><a href=/dashboard/groups>グループ</a>
      <li><a href=/jump>ジャンプリスト</a>
      <li><a href=/dashboard/calls>記事通知</a>
      <li><a href=/dashboard/receive>受信設定</a>
      
    </ul>
  
  </template>
</template-set>

<template-set name=page-dashboard-groups>
  <template title=グループ class=is-subpage>

    <section>
      <header class=section>
        <h1>参加グループ</h1>
        <a href=/help#dashboard-groups target=help>ヘルプ</a>
      </header>

    <list-container loader=dashboardGroupListLoader type=table class="main-table dashboard-group-list">
      <template>
        <th>
          <a href data-href-template="/g/{group_id}/#t:{updated}">
            <img data-src-template=/g/{group_id}/icon alt class=icon>
            <span data-field=title data-empty=(未参加グループ) />
          </a>
        <td>
          <enum-value data-field=status
              label-owner=所有者として参加中
              label-member=参加中
              label-invited=招待されています
          />
        <td>
          <a href data-href-template="/g/{group_id}/i/{default_index_id}/" data-filled=hidden data-hidden-field=hidden-unless-has-default-index class=default-index-button>日記</a>
      </template>

      <table>
        <thead>
          <tr>
            <th>グループ
            <th>状態
            <th>
        <tbody>
      </table>
      <action-status hidden stage-loader=読込中... />
    </list-container>

      <p>他のグループに参加するには、
      グループの所有者から招待状を発行してもらってください。

      <details>
        <summary>グループの作成</summary>

        <p>新しいグループを作成します。
        (サーバー管理者が発行したキーが必要な場合があります。)

        <form is=save-data method=post action=/g/create.json
            data-next="createGroupInitials go:/g/{group_id}/config"
            data-prompt="グループを作成します。この操作は取り消せません。よろしいですか。"
            data-wikititle=Wiki
            data-iconsettitle=アイコン>
          
          <table class=config>
            <tbody>
              <tr>
                <th><label for=create-title>グループ名</label>
                <td><input name=title id=create-title required>
          </table>

          <p class=operations>
            <button type=submit class=save-button>作成する</button>
            <action-status hidden stage-saver=作成中... />
        </form>
      </details>

    </section>
    
  </template>
</template-set>

<template-set name=page-dashboard-calls>
  <template title=記事通知 class=is-subpage>

  <section>
    <header class=section>
      <h1>記事通知</h1>
      <a href=/help#dashboard-calls target=help>ヘルプ</a>
    </header>

    <list-container type=table src=/my/calls.json key=items class="main-table dashboard-call-list">
      <template data-class-template=object-read-{read}>
        <td>
          <p class=dashboard-call-timestamp>
            <time data-field=timestamp data-format=ambtime />
          <p class=dashboard-call-account>
            <gr-dashboard-item type=account data-filled="groupid value" data-groupid-field=group_id data-value-field=from_account_id>
              <a href data-href-template="/g/{group_id}/account/{account_id}/">
                <img data-src-template=/g/{group_id}/account/{account_id}/icon alt class=icon>
                <gr-account-name data-field=name data-empty=■ />
              </a>
            </gr-dashboard-item>
        <td>
          <p class=dashboard-call-group>
            <gr-dashboard-item type=group data-filled=value data-value-field=group_id>
              <a href data-href-template="/g/{group_id}/">
                <img data-src-template=/g/{group_id}/icon alt class=icon>
                <bdi data-field=title data-empty=■ />
              </a>
            </gr-dashboard-item>
          <p class=dashboard-call-object>
            <gr-dashboard-item type=object data-filled="groupid value" data-groupid-field=group_id data-value-field=object_id>
              <a href data-href-template="/g/{group_id}/o/{object_id}/">
                <cite data-field=title data-empty=■ />
              </a>
            </gr-dashboard-item>
          <p class=dashboard-call-snippet>
            <gr-dashboard-item type=object data-filled="groupid value" data-groupid-field=group_id data-value-field=object_id>
              <gr-search-snippet data-field=snippet></gr-search-snippet>
            </gr-dashboard-item>
          <p class=dashboard-call-thread>
            <gr-dashboard-item type=object data-filled="groupid value" data-groupid-field=group_id data-value-field=thread_id>
              <a href data-href-template="/g/{group_id}/o/{object_id}/">
                <cite data-field=title data-empty=■ />
              </a>
            </gr-dashboard-item>
        <!-- reason -->
      </template>

      <table>
        <thead>
          <tr>
            <th>送信
            <th>記事
        <tbody>
      </table>
      <action-status hidden stage-fetch=読込中... />
      <p class=operations>
        <button type=button class=list-next>もっと昔</button>
    </list-container>

      <p><a href=/dashboard/receive>受信設定</a>
    </section>
  </template>
</template-set>

<template-set name=page-dashboard-receive>
  <template title=受信設定 class=is-subpage>
  
    <section id=push-notifications>
      <header class=section>
        <h1>デスクトップ/スマートフォン通知</h1>
        <a href=/help#notifications target=help>ヘルプ</a>
      </header>

      <p><a href=/dashboard/calls>記事通知</a>を受信した時、
      デスクトップ/スマートフォン通知を受け取ることができます。</p>

      <list-container src=/account/push/list.json filter=uaLabelFilter key=items type=table class="main-table push-list">
        <table>
          <thead>
            <tr>
              <th>Web ブラウザー
              <th>登録日時
              <th>有効期限
              <th>操作
          <tbody>
        </table>
        <template>
          <td><span data-field=uaLabel data-title-field=ua />
          <td><time data-format=datetime data-field=created />
          <td><time data-format=datetime data-field=expires />
          <td>
            <!--XXX <button type=button>テスト送信する</button>-->
            <form method=post action=/account/push/delete.json is=save-data data-confirm=削除します data-next="reloadPushList resetConfig:hidePushMN">
              <input type=hidden name=url_sha data-field=url_sha />
              <button type=submit class=delete-button>削除する</button>
              <action-status />
            </form>
        </template>
        <list-is-empty>
          受信設定はありません。
        </list-is-empty>
        <action-status stage-loader=読込中... />
      </list-container>

      <gr-push-config>
        現在お使いの Web ブラウザーは:
        <gr-has-push>
          <gr-has-push-sub>
            登録されています。

            <form method=post action is=save-data data-saver=addPush data-next=reloadPushList>
              <button type=submit class=save-button>再登録する</button>
              <action-status stage-saver=登録中... ok=登録しました。 />
            </form>
            <form method=post action is=save-data data-saver=removePush data-next=reloadPushList>
              <button type=submit class=cancel-button>解除する</button>
              <action-status stage-saver=解除中... ok=解除しました。 />
            </form>
          </gr-has-push-sub>
          <gr-no-push-sub>
            登録されていません。

            <form method=post action is=save-data data-saver=addPush data-next=reloadPushList>
              <button type=submit class=save-button>登録する</button>
              <action-status stage-saver=登録中... ok=登録しました。 />
            </form>
          </gr-no-push-sub>
        </gr-has-push>
        <gr-no-push>
          通知に対応していません。
        </gr-no-push>
      </gr-push-config>
    </section>
  
    <section id=emails>
      <header class=section>
        <h1>インターネットメール</h1>
        <a href=/help#emails target=help>ヘルプ</a>
      </header>

      <p><a href=/dashboard/calls>記事通知</a>やグループの更新のレポートメールを受け取ることができます。</p>

      <list-container src=/account/email/list.json key=items type=table class="email-list main-table">
        <table>
          <thead>
            <tr>
              <th>メールアドレス
              <th>操作
          <tbody/>
          <template>
            <td><code data-field=addr />
            <td>
              <form method=post action=/account/unlink.json is=save-data data-confirm=削除します。 data-next="reloadList:.email-list resetConfig:hideEmailMN" class=transparent>
                <input type=hidden name=server value=email>
                <input type=hidden name=account_link_id data-field=account_link_id />
                <button type=submit class=delete-button>削除する</button>
                <action-status />
              </form>
          </template>
        </table>
        <action-status stage-loader=読込中... />
        <list-is-empty>
          メールアドレスが登録されていません。
        </list-is-empty>
      </list-container>

      <details>
        <summary>メールアドレスの追加</summary>
        
        <form method=post action=/account/email/add.json is=save-data>
          <table class=config>
            <tbody>
              <tr>
                <th><label for=email-add-addr>メールアドレス</label>
                <td><input type=email name=addr value required id=email-add-addr>
          </table>
          <p class=operations>
            <button type=submit class=save-button>追加する</button>
            <action-status ok=確認メールを送信しました。 />
        </form>
        
        <ul class=notes>
          <li>確認メールを送信します。数十分経っても届かない場合、
          メールアドレスが正しいか、
          迷惑メール判定されていないかご確認ください。
          <li>確認メールには完了のためのリンクが含まれています。
          この Web ブラウザーで開いてください。
          <li>確認メールには有効期限があります。
          発行から時間が経っている場合は、
          もう一度追加してください。
        </ul>
      </details>

      <ul class=notes>
        <li>登録されたメールアドレスは、
        レポートメール送信のほか、
        サービス運営者からのお知らせのため使用することがあります。
        (<a href=/help#privacy target=help>プライバシーについて</a>)
      </ul>
    </section>
  
  </template>
</template-set>

<template-set name=page-jump>
  <template title=ジャンプリスト class=is-subpage>
    <section>
      <header class=section>
        <h1>ジャンプリスト</>
        <a href=/help#jump target=help>ヘルプ</a>
      </header>

    <gr-list-container type=table src=/jump/list.json key=items class=main-table>
      <template>
        <th>
          <a href data-href-template={URL} data-field=label />
        <td class=operations>
          <button type=button class=edit-button data-command=editJumpLabel data-prompt=ラベルを指定してください>編集</button>
          <button type=button class=edit-button data-command=deleteJump>削除</button>
          <gr-action-status hidden stage-fetch=... />
      </template>

      <table>
        <thead>
          <tr>
            <th>ページ
            <th>編集
        <tbody>
      </table>
      <gr-action-status hidden stage-load=読込中... />
    </gr-list-container>

      <p>新しいジャンプメニューを追加するには、追加したい項目のメニューから
      「ジャンプリストに追加」を選んでください。
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
