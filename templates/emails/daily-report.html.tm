<html t:params="$app $to_account? $start_time $end_time" class=daily-report
    pl:data-starttime=$start_time pl:data-endtime=$end_time>
  <head>
    <title>Gruwa 活動レポート</title>
  <body>
    <p>Gruwa をご利用いただきありがとうございます。
    参加中のグループの最近の活動をお知らせします。</p>


    <ul class=notes style="font-size:90%;margin-top:1em">
      <li>このレポートは、
      <a pl:href="$app->config->{origin}">Gruwa</a>
      でご参加中のグループで更新があったときにお届けしています。
      <li>送信先は<a pl:href="$app->config->{origin} . '/dashboard/receive#emails'">メールアドレス設定</a>から変更できます。
    </ul>
