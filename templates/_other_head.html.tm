<html t:params="$app $public? $needreferrer?">
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
<link rel=stylesheet pl:href="'/css/common.css?r='.$app->rev">
<script pl:src="'/js/components.js?r='.$app->rev" class=body-js async data-export="$fill $promised" data-time-selector="time:not(.asis)" />
<script pl:src="'/js/framework.js?r='.$app->rev" class=body-js />
<script pl:src="'/js/pages.js?r='.$app->rev" async />
