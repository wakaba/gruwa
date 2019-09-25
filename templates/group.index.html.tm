<html t:params="$group $app"
    pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-theme="$group->{data}->{theme}">
<head>
  <t:include path=_group_head.html.tm m:group=$group m:app=$app />

<body>
  <header class=page>
    <a href data-href-template=/g/{group.group_id}/ rel=top data-field=group.title data-empty=■>
      <t:text value="$group->{data}->{title}">
    </a>
    <h1><a href=./ data-href-field=url data-field=title data-empty=■><t:text value="$group->{data}->{title}"></a></h1>
    <gr-menu type=group />
  </header>
  <header class=subpage hidden>
    <a href data-href-field=backURL title=親ページに戻る>←</a>
    <gr-subpage-title data-field=contentTitle>Gruwa</gr-subpage-title>
  </header>
  <page-main/>
  <t:include path=_common.html.tm m:app=$app />
  <gr-navigate partition=group />

<!--

Copyright 2016-2019 Wakaba <wakaba@suikawiki.org>.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You does not have received a copy of the GNU Affero General Public
License along with this program, see <https://www.gnu.org/licenses/>.

-->
