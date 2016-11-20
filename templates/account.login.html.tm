<html t:params="$app $servers">

<h1>ログイン</>

<form method=post action=/account/login>
  <t:my as=$next x="$app->text_param ('next')">
  <t:if x="defined $next">
    <input type=hidden name=next pl:value=$next>
  </t:if>
  <ul>
    <t:for as=$server x=$servers>
      <li>
        <button type=submit name=server pl:value=$server>
          <t:text value=$server>
        </button>
    </t:for>
  </ul>
</form>
