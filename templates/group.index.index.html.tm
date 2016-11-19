<html t:params="$group $index" pl:data-group-url="'/g/'.$group->{group_id}">
<title t:parse>
  <t:text value="$index->{title}">
  -
  <t:text value="$group->{title}">
  - Gruwa
</>
<link rel=stylesheet href=/css/common.css>
<!-- XXX Referrer -->
<script src=/js/pages.js async />
<!-- XXX beforeunload -->

<hgroup>
<h1><t:text value="$group->{title}"></h1>
<h2><t:text value="$index->{title}"></h2>
</>

<template id=edit-form-template>
  <form method=post action=javascript:>
    <header>
      <p class=control data-name=title data-placeholder=題名 contenteditable></p>
    </header>
    <main class=control data-name=body data-placeholder=本文 contenteditable></main>
    <footer>
      <p class=operations>
        <button type=submit class=save-button>保存する</button>
        <button type=button class=cancel-button>取り消し</button>
    </footer>
  </form>
</template>

<list-container pl:index="$index->{index_id}">
  <template>
    <article class=object>
      <header class=edit-by-dblclick>
        <h1 data-data-field=title data-empty=■></h1>
      </header>
      <main data-data-field=body></main>
      <footer>
        <p>
          <time data-field=created />
          (<time data-field=updated /> 編集)
          <button type=button class=edit-button>編集</button>
      </footer>
    </article>
  </template>

  <p class=operations><button type=button class=edit-button onclick="editObject (this, null)" data-article=#new-object data-list=list-container>新しい記事</button></p>

  <article class=object id=new-object hidden pl:data-index-list="$index->{index_id}" />

  <list-main></list-main>
</list-container>
