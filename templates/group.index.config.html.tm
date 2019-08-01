<html t:params="$group $index $group_member $account $app"
    pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-theme="(defined $index->{options}->{theme})
                       ? $index->{options}->{theme}
                       : $group->{data}->{theme}"
    data-navigating>
<head>
  <t:include path=_group_head.html.tm m:group=$group m:app=$app />

<body>
  <header class=page>
    <h1><a href=./ data-href-field=url data-field=title><t:text value="$index->{title}"></a></h1>
    <gr-menu type=index pl:indexid="$index->{index_id}" />
  </header>
  <page-main/>
  <t:include path=_common.html.tm m:app=$app />
  <gr-navigate/>

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
