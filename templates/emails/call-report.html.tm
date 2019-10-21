<html t:params="$app $to_account? $start_time $end_time" class=call-report
    pl:data-starttime=$start_time pl:data-endtime=$end_time>
  <head>
    <title>Gruwa で呼ばれました</title>
  <body>
    <p>Gruwa で参加中のグループ内で呼ばれました。</p>


    <div style="text-align:center;margin:2em;font-size:200%">
      <p><a pl:href="$app->config->{origin}.'/dashboard/calls'">記事通知一覧を開く</a>
    </div>

    <ul class=notes style="font-size:90%;margin-top:1em">
      <li>このレポートは、
      <a pl:href="$app->config->{origin}">Gruwa</a>
      でご参加中のグループで、
      あなたに記事通知が送信されたときにお届けしています。
      <li>送信先は<a pl:href="$app->config->{origin} . '/dashboard/receive#emails'">メールアドレス設定</a>から変更できます。
    </ul>
