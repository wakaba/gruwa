<html t:params=$account>
<title>Gruwa</title>
<link rel=stylesheet href=/css/common.css>

<header>
  <h1>Gruwa</h1>
  <account-name><t:text value="$account->{name}"></account-name>
</header>

<form method=post action=/g/create.json>
  <input name=title required>
</form>
