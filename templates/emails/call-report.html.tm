<html t:params="$app $to_account? $start_time $end_time
                $group_calls" class=call-report
    pl:data-starttime=$start_time pl:data-endtime=$end_time>
  <head>
    <title>グループで呼ばれました</title>
  <body>
    <p>Gruwa で参加中のグループ内で呼ばれました。</p>

    <t:for as=$gc x=$group_calls>
      <section>
        <h1 style="font-size:100%"><a pl:href="$app->config->{origin}.'/g/'.$gc->{group_id}.'/'"><t:text value="$gc->{group_title}"></a></h1>

        <ul>
          <t:for as=$call x="$gc->{calls}">
            <li><a pl:href="$app->config->{origin}.'/g/'.$gc->{group_id}.'/o/'.$call->{object_id}.'/'" style="font-size:120%"><t:text value="length $call->{computed_title} ? $call->{computed_title} : '■'"></a>
          </t:for>
        </ul>
      </section>
    </t:for>

    <div style="text-align:center;margin:1em;font-size:200%">
      <p><a pl:href="$app->config->{origin}.'/dashboard/calls'">記事通知一覧を開く</a>
    </div>

    <ul class=notes style="font-size:90%;margin-top:1em">
      <li>このレポートは、
      <a pl:href="$app->config->{origin}">Gruwa</a>
      でご参加中のグループで、
      あなたに記事通知が送信されたときにお届けしています。
      <li>送信先は<a pl:href="$app->config->{origin} . '/dashboard/receive#emails'">メールアドレス設定</a>から変更できます。
    </ul>
