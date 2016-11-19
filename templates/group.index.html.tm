<html t:params=$group>
<title t:parse>
  <t:text value="$group->{title}">
  - Gruwa
</>
<link rel=stylesheet href=/css/common.css>
<!-- XXX Referrer -->

<h1><t:text value="$group->{title}"></h1>

<form method=post action=i/create.json>
  <input name=title required>
</form>
