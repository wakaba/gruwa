<html t:params="$group $account">
<title t:parse>
  <t:text value="$group->{title}">
  - Gruwa
</>
<link rel=stylesheet href=/css/common.css>
<!-- XXX Referrer -->

<header>
<h1><t:text value="$group->{title}"></h1>

  <account-name><t:text value="$account->{name}"></account-name>
</header>

<form method=post action=i/create.json>
  <input name=title required>
</form>
