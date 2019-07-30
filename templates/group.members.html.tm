<html t:params="$group $account $app $group_member"
    pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-account="$account->{account_id}"
    pl:data-group-member-type="$group_member->{member_type}"
    pl:data-theme="$group->{data}->{theme}"
    data-navigate=members data-navigating>
<head>
  <t:include path=_group_head.html.tm m:group=$group m:account=$account m:app=$app />

<body>
  <header class=page>
    <h1><a href=./ data-href-field=url data-field=title><t:text value="$group->{data}->{title}"></a></h1>
    <gr-menu type=group />
  </header>
  <page-main/>

<template-set name=page-members>
  <template title=参加者>

    <section id=members>
      <h1>参加者一覧</>

    <gr-list-container type=table src=members/list.json key=members class=main-table>
      <template>
        <th>
          <account-name data-field=account_id />
          <input type=hidden name=account_id data-field=account_id>
        <td class=member_type>
          <gr-enum-value data-field=member_type text-1=一般 text-2=所有者 />
          <select name=member_type data-field=member_type>
            <option value=1>一般
            <option value=2>所有者
          </select>
        <td class=user_status>
          <gr-enum-value data-field=user_status text-1=参加中 text-2=招待中 />
          <select name=user_status data-field=user_status>
            <option value=1>参加中
            <option value=2>招待中
          </select>
        <td class=owner_status>
          <gr-enum-value data-field=owner_status text-1=承認済 text-2=未承認 />
          <select name=owner_status data-field=owner_status>
            <option value=1>承認済
            <option value=2>未承認
          </select>
        <td class=desc>
          <span data-field=desc />
          <input name=desc data-field=desc>
        <td>
          <button type=button class=edit-button onclick="
            parentNode.parentNode.classList.add ('editing');
          ">編集</>
          <button type=button class=save-button onclick="
            var as = getActionStatus (parentNode.parentNode);
            as.start ({stages: ['formdata', 'save']});
            var saveButton = this;
            saveButton.disabled = true;
            var container = parentNode.parentNode;
            var fd = new FormData;
            $$ (container, 'input, select').forEach (function (e) {
              fd.append (e.name, e.value);
            });
            as.stageEnd ('formdata');
            as.stageStart ('save');
            gFetch ('members/status.json', {post: true, formData: fd}).then (function () {
              saveButton.disabled = false;
              as.end ({ok: true});
            }, function (error) {
              saveButton.disabled = false;
              as.end ({error: error});
            });
          ">保存</>
          <gr-action-status hidden stage-save=保存中... ok=保存しました。 />
        <td>
          <a href data-href-template="i/{default_index_id}/" data-if-field=default_index_id>日記</a>
      </template>

        <table>
          <thead>
            <tr>
              <th>名前
              <th>種別
              <th>参加状態
              <th>参加承認
              <th>メモ
              <th>操作
              <th>
          <tbody>
        </table>
        <gr-action-status hidden stage-load=読み込み中... />
      </gr-list-container>
    </section>

    <section id=invite>
      <h1>参加者の追加</h1>

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
                  <option value=1 selected>一般
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
      <h1>発行済招待状</h1>

      <gr-list-container type=table src=members/invitations/list.json key=invitations sortkey=created class=main-table id=invitations-list data-gr-if-group-owner>
          <template>
            <td><a data-href-field=invitation_url><time data-field=created /></a>
            <td><account-name data-field=author_account_id />
            <td><gr-enum-value data-field=invitation_data.member_type text-1=一般 text-2=所有者 />
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
  
  <t:include path=_common.html.tm m:app=$app />

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
