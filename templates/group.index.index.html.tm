<html t:params="$group $index $account $group_member $app" pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-theme="$index->{options}->{theme}">
<head>
  <t:include path=_group_head.html.tm m:group=$group m:account=$account m:app=$app>
    <t:text value="$index->{title}">
  </t:include>

<body>
  <!-- XXX beforeunload -->
  <t:include path=_group_header.html.tm m:group=$group m:account=$account m:group_member=$group_member m:app=$app />

  <section class=page>
    <header>
      <h1><a href=./><t:text value="$index->{title}"></a></h1>
      <nav>
        <a href=./ class=active>トップ</a>
        / <a href=config>設定</a>
      </nav>
    </header>

<template id=edit-form-template>
  <form method=post action=javascript:>
    <header>
      <p><input name=title placeholder=題名>
    </header>
    <main class=control data-name=body data-placeholder=本文 contenteditable></main>
    <footer>
      <p class=operations>
        <button type=submit class=save-button>保存する</button>
        <button type=button class=cancel-button>取り消し</button>
    </footer>
  </form>
</template>

<list-container pl:index="$index->{index_id}" listitemtype=object>
  <template>
    <article class=object>
      <header class=edit-by-dblclick>
        <h1 data-data-field=title data-empty=■></h1>
      </header>
      <main data-data-field=body data-field-type=html></main>
      <footer>
        <p>
          <time data-field=created class=ambtime />
          (<time data-field=updated class=ambtime /> 編集)
          <button type=button class=edit-button>編集</button>
      </footer>
    </article>
  </template>

  <p class=operations><button type=button class=edit-button onclick="editObject (this, null)" data-article=#new-object data-list=list-container>新しい記事</button></p>

  <article class=object id=new-object hidden pl:data-index-list="$index->{index_id}" />

  <list-main></list-main>
</list-container>


  </section>

<!--

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

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
