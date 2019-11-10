<html t:params="$app $to_account? $start_time $end_time
                $group_memberships" class=daily-report
    pl:data-starttime=$start_time pl:data-endtime=$end_time>
  <head>
    <title>Gruwa 活動レポート</title>
  <body>
    <p>参加中のグループの最近の活動をお知らせします。</p>

    <t:for as=$gm x=$group_memberships>
      <section>
        <h1 style="font-size:100%"><a pl:href="$app->config->{origin}.'/g/'.$gm->{group_id}.'/'"><t:text value="$gm->{group_data}->{title}"></a></h1>
        
        <t:if x="@{$gm->{indexes}}">
          <p>更新がありました。</p>
          
          <ul>
            <t:for as=$index x="$gm->{indexes}">
              <li><a pl:href="$app->config->{origin}.'/g/'.$gm->{group_id}.'/i/'.$index->{index_id}.'/'"><t:text value="$index->{title}"></a>
            </t:for>
          </ul>
        </t:if>
        
        <t:if x="@{$gm->{stars}}">
          <p>記事に&#x2B50;がつきました。
          
          <ul>
            <t:for as=$star x="$gm->{stars}">
              <li>
                <bdi><a pl:href="$app->config->{origin}.'/g/'.$gm->{group_id}.'/o/'.$star->{object_id}.'/'"><t:text value="length $star->{title} ? $star->{title} : '■'"></a></bdi>

                <t:if x="$star->{count} > 10">
                  &#x2B50;<data><t:text value="$star->{count}"></data>
                <t:else>
                  <t:text value="'&#x2B50;' x $star->{count}">
                </t:if>
            </t:for>
          </ul>
        </t:if>
      </section>
    </t:for>

    <div style="text-align:center;margin:1em;font-size:200%">
      <p><a pl:href="$app->config->{origin}.'/dashboard/groups'">グループ一覧を開く</a>
    </div>

    <ul class=notes style="font-size:90%;margin-top:1em">
      <li>このレポートは、
      <a pl:href="$app->config->{origin}">Gruwa</a>
      でご参加中のグループで更新があったときにお届けしています。
      <li>送信先は<a pl:href="$app->config->{origin} . '/dashboard/receive#emails'">メールアドレス設定</a>から変更できます。
    </ul>
