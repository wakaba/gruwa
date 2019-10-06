<html t:params=$app>
<title>Gruwa</title>
<t:if x="not $app->config->{is_live}">
  <meta name=referrer content=no-referrer>
  <meta name=robots content="NOINDEX,NOFOLLOW,NOARCHIVE">
</t:if>
<meta name="viewport" content="width=device-width,initial-scale=1">
<link rel=stylesheet pl:href="'/css/common.css?r='.$app->rev">
<link rel=icon href=/favicon.ico>

<header class=cover>
  <h1>Gruwa</h1>
</header>

<nav class=cover>
  <a href=/dashboard>ダッシュボード</a>
</nav>

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
