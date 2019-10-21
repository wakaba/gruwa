<html t:params="$app $to_account? $start_time $end_time
                $group_memberships" class=daily-report
    pl:data-starttime=$start_time pl:data-endtime=$end_time>
  <head>
    <title>Gruwa 活動レポート</title>
  <body>
    <p>Gruwa をご利用いただきありがとうございます。
    参加中のグループの最近の活動をお知らせします。</p>

    <t:for as=$gm x=$group_memberships>
      <section>
        <h1><a pl:href="$app->config->{origin}.'/g/'.$gm->{group_id}.'/'"><t:text value="$gm->{group_data}->{title}"></a></h1>

        <t:if x="@{$gm->{indexes}}">
          <ul>
            <t:for as=$index x="$gm->{indexes}">
              <li><a pl:href="$app->config->{origin}.'/g/'.$gm->{group_id}.'/i/'.$index->{index_id}.'/'"><t:text value="$index->{title}"></a>
            </t:for>
          </ul>
        </t:if>
      </section>
    </t:for>

    <div style="text-align:center;margin:2em;font-size:200%">
      <p><a pl:href="$app->config->{origin}.'/dashboard/groups'">グループ一覧を開く</a>
    </div>

    <ul class=notes style="font-size:90%;margin-top:1em">
      <li>このレポートは、
      <a pl:href="$app->config->{origin}">Gruwa</a>
      でご参加中のグループで更新があったときにお届けしています。
      <li>送信先は<a pl:href="$app->config->{origin} . '/dashboard/receive#emails'">メールアドレス設定</a>から変更できます。
    </ul>
