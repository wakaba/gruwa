<html t:params="$app $url $to_account?">
  <head>
    <title>Gruwa 登録メールアドレスの確認</title>
  <body>
    <p>Gruwa をご利用いただきありがとうございます。
    メールアドレスの確認を完了してください。</p>

    <div style="text-align:center;margin:2em;font-size:200%">
      <p><a pl:href=$url>メールアドレスの確認を完了する</a>
    </div>

    <ul class=notes style="font-size:90%;margin-top:1em">
      <li><a pl:href="$app->http->url->resolve_string ('/')->stringify">Gruwa</a> をご利用中の
      Web ブラウザーで開いてください。
      <li>このメールには有効期限があります。発行から時間が経っている場合は、
      <a pl:href="$app->http->url->resolve_string ('/dashboard/receive#emails')->stringify">もう一度メールアドレスを登録</a>しなおしてください。
      <li>心当たりがない場合は、このメールは無視して削除してください。
    </ul>
