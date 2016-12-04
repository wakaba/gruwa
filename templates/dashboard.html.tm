<html t:params="$account $app">
<title>Gruwa</title>
<t:if x="not $app->config->{is_production}">
  <meta name=referrer content=no-referrer>
<t:else>
  <meta name=referrer content=origin>
</t:if>
<link rel=stylesheet href=/css/common.css>
<script src=/js/pages.js async />

<header class=common>
  <header-area>
    <hgroup>
      <h1><a href=/ rel=top>Gruwa</h1>
    </>
  </header-area>
  <header-area>
    <account-name><t:text value="$account->{name}"></account-name>
    <a href=/dashboard>ダッシュボード</>
  </header-area>
</header>

  <section>
    <h1>参加グループ</>

    <list-container type=table src=my/groups.json key=groups sortkey=updated>
      <template>
        <th>
          <a href data-href-template="/g/{group_id}/">
            <span data-field=title data-empty=(未参加グループ) />
          </a>
        <td class=member_type>
          <enum-value data-field=member_type text-1=一般 text-2=所有者 text-0=未参加 />
        <td class=user_status>
          <enum-value data-field=user_status text-1=参加中 text-2=招待中 />
        <td class=owner_status>
          <enum-value data-field=owner_status text-1=承認済 text-2=未承認 />
        <td>
          <a href data-href-template="g/{group_id}/i/{default_index_id}/" data-if-field=default_index_id>日記</a>
      </template>

      <table>
        <thead>
          <tr>
            <th>グループ
            <th>種別
            <th>参加状態
            <th>参加承認
            <th>
        <tbody>
      </table>
      <action-status hidden stage-load=読み込み中... />
    </list-container>

    <details>
      <summary>グループの作成</summary>

      <form method=post action=javascript: data-action=g/create.json
          data-href-template=/g/{group_id}/config>
        <table class=config>
          <tbody>
            <tr>
              <th><label for=create-title>グループ名</>
              <td><input name=title id=create-title required>
        </table>

        <p class=operations>
          <button type=submit class=save-button>作成する</>
          <action-status hidden stage-fetch=作成中... stage-next=移動します... />
      </form>
    </details>
  </section>
