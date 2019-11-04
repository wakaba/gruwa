<html t:params="$app">
  <body>

    <gr-nav-button>
      <button type=button title=メニュー>
        <button-label>メニュー</button-label>
      </button>
    </gr-nav-button>
    
    <gr-nav-panel tabindex=0>
      <details open>
        <summary>
          <gr-account self>
            <img data-src-template=/g/{group_id}/account/{account_id}/icon class=icon alt>
            <gr-account-name data-field=name data-filling>アカウント</>
          </gr-account>
        </summary>
        <p><a href=/dashboard>ダッシュボード</a></p>
        <list-container src=/jump/list.json key=items class=jump-list filter=jumpListFilter>
          <template>
            <p><a href data-href-template={url} data-ping-template=/jump/ping.json?url={url:absoluteURL} data-field=label data-empty=■ data-filled=ping></a>
          </template>
          <list-main/>
        </list-container>
      </details>
      <details open>
        <summary>
          <gr-group>
            <img data-src-template=/g/{group_id}/icon class=icon alt>
            <gr-group-name data-field=title data-filling>グループ</>
          </gr-group>
        </summary>
        <gr-group>
          <p><a data-href-template=/g/{group_id}/>トップ</a>
          <p class=if-has-default-index><a data-href-template=/g/{group_id}/i/{member.default_index_id}/>自分の日記</a>
          <form is=gr-search method=get action=search>
            <input type=search name=q required placeholder=グループ内検索>
            <button type=submit class=search-button>検索</button>
          </form>
        </gr-group>
      </details>
      <details>
        <summary>Gruwa</summary>
        <p><a href=/help target=help>ヘルプ</a>
        <p><a href=/news target=help class=news-link>お知らせ</a>
        <p><a href=/terms target=help>利用規約</a>
      </details>
    </gr-nav-panel>

    <gr-navigate-status>
      <action-status stage-loading=読込中... />
      <gr-error message="The group has no default wiki" hidden>
        <a href=/help#default-wiki-index target=help>グループの Wiki</a>
        が設定されていません。
      </gr-error>
      <p class=operations><button type=button class=reload-button>再読込</button>
    </gr-navigate-status>

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
