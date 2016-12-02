<html t:params="$group $account $app">
<title t:parse>
  <t:content>
  -
  <t:text value="$group->{title}">
</>
<t:if x="not $app->config->{is_production}">
  <meta name=referrer content=no-referrer>
<t:else>
  <meta name=referrer content=origin>
</t:if>
<link rel=stylesheet href=/css/common.css>
<script src=/js/pages.js async />