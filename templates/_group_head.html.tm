<html t:params="$group $account $app">
<title t:parse>
  <t:content>
  -
  <t:text value="$group->{data}->{title}">
</>
<t:if x="not $app->config->{is_production}">
  <meta name=referrer content=no-referrer>
<t:else>
  <meta name=referrer content=origin>
</t:if>
<link rel=stylesheet href=/css/common.css>
<script src=/js/framework.js async class=body-js />
<script src=/js/pages.js async />
<link rel=preload as=style href=/css/body.css class=body-css>
<link rel=preload as=script href=/js/body.js class=body-js>

<!--

Copyright 2016-2017 Wakaba <wakaba@suikawiki.org>.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You does not have received a copy of the GNU Affero General Public
License along with this program, see <http://www.gnu.org/licenses/>.

-->
