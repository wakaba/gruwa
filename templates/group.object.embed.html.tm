<html t:params="$group $object $account $group_member $app"
    pl:data-group-url="'/g/'.$group->{group_id}"
    pl:data-theme="$group->{data}->{theme}">
<head>
  <t:include path=_group_head.html.tm m:group=$group m:account=$account m:app=$app>
    <t:text value="
      my $title = $object->{data}->{title};
      length $title ? $title : '■';
    ">
  </t:include>

<body class=embedded>
  <t:if x="$object->{data}->{body_type} == 4 # file">
    <a pl:href="
      '/g/'.$group->{group_id}.'/o/'.$object->{object_id}.'/file'
    " download>
      <t:text value="
          my $title = $object->{data}->{title};
          length $title ? $title : '■';
      ">
      <code><t:text value="$object->{data}->{file_name}"></code>
      <t:if x="$object->{data}->{file_size}">
        <span class=note>(<unit-number type=bytes pl:value="$object->{data}->{file_size}"/>)</span>
      </t:if>
    </a>
  <t:else>
    <a pl:href="
      '/g/'.$group->{group_id}.'/o/'.$object->{object_id}.'/'
    " target=_top>
      <t:text value="
          my $title = $object->{data}->{title};
          length $title ? $title : '■';
      ">
    </a>
  </t:if>

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
