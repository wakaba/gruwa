(function () {
  var handlers = {};
  var promises = {};
  var ok = {};

  window.$with = function (key, opts) {
    if (handlers[key]) {
      return Promise.resolve ().then (function () { return handlers[key] (opts || {}) });
    } else {
      promises[key] = promises[key] || new Promise (function (o) { ok[key] = o });
      return promises[key].then (function () { return handlers[key] (opts || {}) });
    }
  }; // $with

  window.$with.register = function (key, code) {
    handlers[key] = code;
    if (ok[key]) ok[key] ();
    delete ok[key];
    delete promises[key];
  }; // register
}) ();

function $$ (n, s) {
  return Array.prototype.slice.call (n.querySelectorAll (s));
} // $$

function $grfill (e, o) {
  $$ (e, '[data-field]').forEach (function (f) {
    var name = f.getAttribute ('data-field').split (/\./);
    var value = o;
    for (var i = 0; i < name.length; i++) {
      value = value[name[i]];
      if (value == null) break;
    }

    if (f.localName === 'input' ||
        f.localName === 'select') {
      f.value = value;
    } else if (f.localName === 'time') {
      var date = new Date (parseFloat (value) * 1000);
      try {
        f.setAttribute ('datetime', date.toISOString ());
        f.textContent = date.toLocaleString ();
      } catch (e) {
        console.log (e); // XXX
      }
    } else if (f.localName === 'gr-enum-value') {
      f.setAttribute ('value', value);
      if (value == null) {
        f.hidden = true;
      } else {
        f.hidden = false;
        var v = f.getAttribute ('text-' + value);
        if (v) {
          f.textContent = v;
        } else {
          f.textContent = value;
        }
        if (f.parentNode.localName === 'td') {
          f.parentNode.setAttribute ('data-value', value);
        }
      }
    } else if (f.localName === 'only-if') {
      var matched = true;
      var cond = f.getAttribute ('cond');
      if (cond === '==0') {
        if (value != 0) matched = false;
      } else if (cond === '!=0') {
        if (value == 0) matched = false;
      }
      f.hidden = ! matched;
    } else {
      f.textContent = value || f.getAttribute ('data-empty');
    }
  });
  ['href', 'src', 'title', 'alt', 'class'].forEach (function (attr) {
    $$ (e, '[data-'+attr+'-template]').forEach (function (f) {
      var value = f.getAttribute ('data-'+attr+'-template').replace (/\{([^{}]+)\}/g, function (_, n) {
        var name = n.split (/\./);
        var value = o;
        for (var i = 0; i < name.length; i++) {
          value = value[name[i]];
          if (value == null) break;
        }
        return value;
      });
      f.setAttribute (attr, value);
    });
  });
} // $grfill

/*

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

*/
