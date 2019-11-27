<html t:params="$app $public? $needreferrer?"
    data-theme=green>
<title t:parse>
  <t:content> - Gruwa
</>
<t:if x="$app->config->{is_live} and $public">
  <meta name=referrer content=origin>
<t:else>
  <t:if x=$needreferrer>
    <!-- XXX until browsers support <form referrerpolicy=""> -->
    <meta name=referrer content=origin>
  <t:else>
    <meta name=referrer content=no-referrer>
  </t:if>
  <meta name=robots content="NOINDEX,NOFOLLOW,NOARCHIVE">
</t:if>
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name=theme-color content="green">
<link rel=stylesheet pl:href="'/css/common.css?r='.$app->rev">
<link rel=icon href=/favicon.ico>
<script pl:src="'/js/components.js?r='.$app->rev" class=body-js async data-export="$fill $promised $getTemplateSet $paco" data-time-selector="time:not(.asis)" />
<script pl:src="'/js/framework.js?r='.$app->rev" class=body-js />
<script pl:src="'/js/pages.js?r='.$app->rev" async />

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
