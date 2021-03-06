<html t:params="$group $app $title?">
<t:if x="defined $title">
  <title t:parse>
    <t:text value="$title">
    -
    <t:text value="$group->{data}->{title}">
  </title><!-- XXX -->
<t:else>
  <title t:parse>
    <t:content>
    -
    <t:text value="$group->{data}->{title}">
  </title><!-- XXX -->
</t:if>
<meta name=referrer content=no-referrer>
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name=theme-color content="green">
<link rel=stylesheet pl:href="'/css/common.css?r='.$app->rev">
<script pl:src="'/js/components.js?r='.$app->rev" async data-export="$fill $promised $getTemplateSet $paco" data-time-selector="time:not(.asis)" />
<script pl:src="'/js/framework.js?r='.$app->rev" />
<script pl:src="'/js/pages.js?r='.$app->rev" async />
<link rel=preload as=fetch pl:href="'/html/group.htt?r='.$app->rev" is=gr-html-import crossorigin>

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
