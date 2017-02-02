<html t:params="$group $account $group_member">

<header class=group>
  <header-area>
    <hgroup>
      <h1><a href=/>Gruwa</a></h1>
      <h2><a pl:href="'/g/'.$group->{group_id}.'/'" rel=top><t:text value="$group->{data}->{title}"></a></h2>
    </hgroup>
    <form method=get pl:action="'/g/'.$group->{group_id}.'/search'" class=search-form>
      <input type=search name=q>
      <button type=submit>検索</button>
    </form>
  </header-area>
  <header-area>
    <popup-menu>
      <button><account-name><t:text value="$account->{name}"></account-name></button>
      <menu hidden>
        <li><a href=/dashboard>ダッシュボード</></li>
        <t:if x="$group_member->{data}->{default_index_id}">
          <li><a pl:href="'/g/'.$group->{group_id}.'/i/'.$group_member->{data}->{default_index_id}.'/'">グループ日記</a>
        </t:if>
        <hr>
        <list-container src=/jump/list.json key=items type=list>
          <template>
            <a href data-href-template={URL} data-ping-template=/jump/ping.json?url={HREF} data-field=label></a>
          </template>
          <list-main/>
        </list-container>
      </menu>
    </popup-menu>
    <a href=/help rel=help>ヘルプ</a>
  </header-area>
</header>

<t:macro name=group-menu t:params=$group>
  <popup-menu>
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
          メンバー
        </a>
      <li>
        <a pl:href="'/g/'.$group->{group_id}.'/config'">
          設定
        </a>
    </menu>
  </popup-menu>
</t:macro>

<t:macro name=index-menu t:params="$group $index">
  <popup-menu>
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
    </menu>
  </popup-menu>
</t:macro>

<t:macro name=wiki-menu t:params="$wiki_name">
  <popup-menu>
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
  </popup-menu>
</t:macro>

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
