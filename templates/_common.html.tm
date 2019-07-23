<html t:params="$app $account $group $group_member">
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
        document.querySelector ('gr-nav-panel :-webkit-any(a, input, summary)').focus ();
      ">三</button>
    </gr-nav-button>
    
    <gr-nav-panel>
      <details open>
        <summary><account-name><t:text value="$account->{name}"></account-name></summary>
        <p><a href=/dashboard>ダッシュボード</a></p>
        <hr>
        <list-container src=/jump/list.json key=items type=list>
          <template>
            <p><a href data-href-template={URL} data-ping-template=/jump/ping.json?url={HREF} data-field=label></a>
          </template>
          <list-main/>
        </list-container>
        <p><a href=/jump>ジャンプリストの編集</></li>
      </details>
      <details open>
        <summary><t:text value="$group->{data}->{title}"></summary>
        <p><a pl:href="'/g/'.$group->{group_id}.'/'">トップ</a></p>
        <t:if x="$group_member->{data}->{default_index_id}">
          <p><a pl:href="'/g/'.$group->{group_id}.'/i/'.$group_member->{data}->{default_index_id}.'/'">自分の日記</a>
        </t:if>
        <form method=get pl:action="'/g/'.$group->{group_id}.'/search'" class=search-form>
          <input type=search name=q required placeholder=グループ内検索>
          <button type=submit>検索</button>
        </form>
      </details>
      <details>
        <summary>Gruwa</summary>
        <p><a href=/>トップ</a>
        <p><a href=/help>ヘルプ</a>
      </details>
    </gr-nav-panel>

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
          参加者
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
      </li>
      <t:if x="$index->{index_type} == 6 # fileset">
        <li><a href=/help#filesets>ヘルプ</a>
      </t:if>
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
