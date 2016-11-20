<html t:params=$servers>

<h1>ログイン</>

<ul>
  <t:for as=$server x=$servers>
    <li>
      <form method=post action=/account/login>
        <input type=hidden name=server pl:value=$server>
        <button type=submit><t:text value=$server></button>
      </form>
  </t:for>
</ul>
