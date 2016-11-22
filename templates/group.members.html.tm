<html t:params="$group $account $app" pl:data-group-url="'/g/'.$group->{group_id}">
<head>
  <t:include path=_group_head.html.tm m:group=$group m:account=$account m:app=$app>
    メンバー一覧
  </t:include>

<body>
  <t:include path=_group_header.html.tm m:group=$group m:account=$account m:app=$app />

  <section>
    <h1>メンバー一覧</>

    <list-container type=table src=members.json key=members>
      <template>
        <th>
          <account-name data-field=account_id />
          <input type=hidden name=account_id data-field=account_id>
        <td>
          <enum-value data-field=member_type text-1=一般 text-2=所有者 />
          <select name=member_type data-field=member_type>
            <option value=1>一般
            <option value=2>所有者
          </select>
        <td>
          <enum-value data-field=user_status text-1=参加中 text-2=招待中 />
          <select name=user_status data-field=user_status>
            <option value=1>参加中
            <option value=2>招待中
          </select>
        <td>
          <enum-value data-field=owner_status text-1=参加中 text-2=未承認 />
          <select name=owner_status data-field=owner_status>
            <option value=1>参加中
            <option value=2>未承認
          </select>
        <td>
          <span data-field=desc />
          <input name=desc data-field=desc>
        <td>
          <button type=button class=edit-button>編集</>
          <button type=button class=save-button>保存</>
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
        <tbody>
      </table>
    </list-container>
  </section>

<!--

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

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
