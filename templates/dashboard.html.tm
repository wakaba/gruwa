<html t:params="$app_env $push_key $app_rev"
    data-theme=green
    pl:data-env="$app_env"
    pl:data-push-server-key="$push_key">
<head>
  <title>Gruwa</title>
  <meta name=referrer content=no-referrer>
  <meta name=robots content="NOINDEX,NOFOLLOW,NOARCHIVE">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name=theme-color content="green">
  <link rel=stylesheet pl:href="'/css/common.css?r='.$app_rev">
  <link rel=icon href=/favicon.ico>
  <script pl:src="'/js/components.js?r='.$app_rev" class=body-js async data-export="$fill $promised $getTemplateSet $paco" data-time-selector="time:not(.asis)" />
  <script pl:src="'/js/framework.js?r='.$app_rev" class=body-js />
  <script pl:src="'/js/pages.js?r='.$app_rev" async />
  <link rel=preload as=fetch pl:href="'/html/dashboard.htt?r='.$app_rev" is=gr-html-import crossorigin>

<body>
  <header class=page>
    <a href=/ rel=top>Gruwa</a>
    <h1><a href=/dashboard>ダッシュボード</a></h1>
    <gr-menu type=dashboard />
  </header>
  <header class=subpage hidden>
    <a href data-href-field=backURL title=親ページに戻る>←</a>
    <gr-subpage-title data-field=contentTitle>ダッシュボード</gr-subpage-title>
  </header>
  <page-main/>

  <gr-navigate-status>
    <action-status stage-loading=読込中... />
    <p class=operations><button type=button class=reload-button>再読込</button>
  </gr-navigate-status>

  <gr-navigate partition=dashboard />
  <!-- XXX -->
  <gr-account self hidden />

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

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
<https://www.gnu.org/licenses/>.

-->
