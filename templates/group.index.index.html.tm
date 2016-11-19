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

<hgroup>
<h1><t:text value="$group->{title}"></h1>
<h2><t:text value="$index->{title}"></h2>
</>

<template id=edit-form-template>
  <form method=post action=javascript:>
    <p class=control data-name=title data-placeholder=題名 contenteditable></p>
    <main class=control data-name=body data-placeholder=本文 contenteditable></main>
    <footer>
      <button type=submit>保存</button>
    </footer>
  </form>
</template>

<article id=new-object hidden pl:data-index-list="$index->{index_id}" />

<p><button type=button onclick="editObject (this, null)" data-article=#new-object data-list=list-container data-template=#edit-form-template>新しい記事</button></p>

<list-container pl:index="$index->{index_id}">
  <template>
    <article>
      <h1 data-data-field=title data-empty=■></h1>
      <p><button type=button class=edit-button data-template=#edit-form-template>編集</button></p>
      <main data-data-field=body></main>
    </article>
  </template>
  <list-main></list-main>
</list-container>
