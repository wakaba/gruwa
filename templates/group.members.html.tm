<html t:params="$group $account $app $group_member"
    pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-account="$account->{account_id}"
    pl:data-group-member-type="$group_member->{member_type}"
    pl:data-theme="$group->{data}->{theme}">
<head>
  <t:include path=_group_head.html.tm m:group=$group m:account=$account m:app=$app>
    メンバー一覧
  </t:include>

<body>
  <t:include path=_group_header.html.tm m:group=$group m:account=$account m:group_member=$group_member m:app=$app />

  <section class=page>
    <header>
      <h1><a href=./><t:text value="$group->{data}->{title}"></a></h1>
      <m:group-menu m:group=$group />
    </header>

    <section>
      <h1>メンバー一覧</>

    <list-container type=table src=members/list.json key=members class=main-table>
      <template>
        <th>
          <account-name data-field=account_id />
          <input type=hidden name=account_id data-field=account_id>
        <td class=member_type>
          <enum-value data-field=member_type text-1=一般 text-2=所有者 />
          <select name=member_type data-field=member_type>
            <option value=1>一般
            <option value=2>所有者
          </select>
        <td class=user_status>
          <enum-value data-field=user_status text-1=参加中 text-2=招待中 />
          <select name=user_status data-field=user_status>
            <option value=1>参加中
            <option value=2>招待中
          </select>
        <td class=owner_status>
          <enum-value data-field=owner_status text-1=承認済 text-2=未承認 />
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
          <action-status hidden stage-save=保存中... ok=保存しました。 />
        <td>
          <a href data-href-template="i/{default_index_id}/" data-if-field=default_index_id>日記</a>
      </template>

        <table>
          <thead>
            <tr>
              <th>メンバー
              <th>種別
              <th>参加状態
              <th>参加承認
              <th>メモ
              <th>操作
              <th>
          <tbody>
        </table>
        <action-status hidden stage-load=読み込み中... />
      </list-container>
    </section>
  </section>

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
