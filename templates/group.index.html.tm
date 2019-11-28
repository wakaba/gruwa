<html t:params="$app_env $app_rev $formatter_url_prefix"
    pl:data-env="$app_env"
    pl:data-formatter-url=$formatter_url_prefix
    data-theme=green>
<head>
  <title>Gruwa</title>
<meta name=referrer content=no-referrer>
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name=theme-color content="green">
<link rel=stylesheet pl:href="'/css/common.css?r='.$app_rev">
<script pl:src="'/js/components.js?r='.$app_rev" class=body-js async data-export="$fill $promised $getTemplateSet $paco" data-time-selector="time:not(.asis)" />
<script pl:src="'/js/framework.js?r='.$app_rev" class=body-js />
<script pl:src="'/js/pages.js?r='.$app_rev" async />
<link rel=preload as=fetch pl:href="'/html/group.htt?r='.$app_rev" is=gr-html-import crossorigin>
<link rel=preload as=style pl:href="'/css/body.css?r='.$app_rev" class=body-css>
<link rel=preload as=script pl:href="'/js/body.js?r='.$app_rev" class=body-js>

<body>
  <header class=page>
    <a href data-href-template=/g/{group.group_id}/ rel=top data-field=group.title data-empty=■>Gruwa</a>
    <h1><a href=./ data-href-field=url data-field=title data-empty=■>Gruwa</a></h1>
    <gr-menu type=group />
  </header>
  <header class=subpage hidden>
    <a href data-href-field=backURL title=親ページに戻る>←</a>
    <gr-subpage-title data-field=contentTitle>Gruwa</gr-subpage-title>
  </header>
  <page-main/>
  <t:include path=_common.html.tm />
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
