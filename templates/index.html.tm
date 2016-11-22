<html t:params=$app>
<title>Gruwa</title>
<t:if x="not $app->config->{is_production}">
  <meta name=referrer content=no-referrer>
</t:if>
<link rel=stylesheet href=/css/common.css>
<meta name="viewport" content="width=device-width,initial-scale=1">

<header class=cover>
  <h1>Gruwa</h1>
</header>

<nav class=cover>
  <a href=/dashboard>ダッシュボード</a>
</nav>
