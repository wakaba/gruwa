function $$ (n, s) {
  return Array.prototype.slice.call (n.querySelectorAll (s));
} // $$

function gFetch (pathquery, opts) {
  return fetch (document.documentElement.getAttribute ('data-group-url') + '/' + pathquery, {
    credentials: "same-origin",
    method: opts.post ? 'POST' : 'GET',
    body: opts.formData, // or undefined
  }).then (function (res) {
    if (res.status !== 200) throw res;
    return res.json ();
  });
} // gFetch

function fillFields (el, object) {
  if (object.account_id &&
      object.account_id === document.documentElement.getAttribute ('data-account')) {
    el.classList.add ('account-is-self');
  }
  $$ (el, '[data-field]').forEach (function (field) {
    var value = object[field.getAttribute ('data-field')];
    if (field.localName === 'input' ||
        field.localName === 'select') {
      field.value = value;
    } else if (field.localName === 'time') {
      var date = new Date (parseFloat (value) * 1000);
      field.setAttribute ('datetime', date.toISOString ());
      field.textContent = date.toLocaleString ();
    } else if (field.localName === 'enum-value') {
      var v = field.getAttribute ('text-' + value);
      field.setAttribute ('value', value);
      if (v) {
        field.textContent = v;
      } else {
        field.textContent = value;
      }
    } else if (field.localName === 'account-name') {
      field.setAttribute ('account', value);
      field.textContent = value; // XXX
    } else {
      field.textContent = value;
    }
  });
  $$ (el, '[data-data-field]').forEach (function (field) {
            var value = object.data[field.getAttribute ('data-data-field')];
            var type = field.getAttribute ('data-field-type');
            if (type === 'html') {
              field.innerHTML = value; // XXX sandbox
            } else {
              field.textContent = value || field.getAttribute ('data-empty') || '';
            }
          });
} // fillFields

function upgradeList (el) {
  if (el.upgraded) return;
  el.upgraded = true;

  var fillObject = function (item, object) {
      $$ (item, '.edit-button').forEach (function (button) {
        button.onclick = function () {
          editObject (this, object);
        };
      });
      $$ (item, '.edit-by-dblclick').forEach (function (button) {
        button.ondblclick = function () {
          editObject (this, object);
        };
      });
      $$ (item, 'article').forEach (function (article) {
        article.id = 'object-' + object.object_id;
        article.setAttribute ('data-object', object.object_id);
        var ids = [];
        for (var n in object.data.index_ids) {
          ids.push (n);
        }
        article.setAttribute ('data-index-list', ids.join (' '));
        article.updateView = function () {
          fillFields (article, field);
        }; // updateView
        article.updateView ();
      });
  }; // fillObject

  el.clearObjects = function () {
    var main = $$ (this, 'list-main')[0];
    if (main) main.textContent = '';
  }; // clearObjects
  el.showObjects = function (objects) {
    var template = $$ (this, 'template')[0];
    var type = el.getAttribute ('type');
    var main;
    if (type === 'table') {
      main = $$ (this, 'table tbody')[0];
    } else {
      main = $$ (this, 'list-main')[0];
    }
    if (!template || !main) return;

    Object.values (objects).forEach (function (object) {
      var item = document.createElement (type === 'table' ? 'tr' : 'list-item');
      item.appendChild (template.content.cloneNode (true));
      if (type === 'table') {
        fillFields (item, object);
      } else {
        fillObject (item, object);
      }
      main.appendChild (item);
    });
  }; // showObjects

  return Promise.resolve ().then (function () {
    var url;
    var index = el.getAttribute ('index');
    var key;
    if (index) {
      url = 'o/get.json?index_id=' + index;
      key = 'objects';
    } else {
      url = el.getAttribute ('src');
      key = el.getAttribute ('key');
    }
    if (url) {
      return gFetch (url, {}).then (function (json) {
        el.clearObjects ();
        el.showObjects (json[key]);
      });
    } else {
      el.clearObjects ();
    }
  }).catch (function (error) {
    console.log (error); // XXX
  });
} // upgradeList

function editObject (optEl, object) {
  var template = document.querySelector ('#edit-form-template');

  var article;
  if (optEl.hasAttribute ('data-article')) {
    article = $$ (document, optEl.getAttribute ('data-article'))[0];
    article.hidden = false;
  } else {
    while (optEl) {
      if (optEl.localName === 'article' || optEl.localName === 'body') {
        article = optEl;
        break;
      } else {
        optEl = optEl.parentNode;
      }
    }
    if (!optEl) throw "Bad /optEl/";
  }

  var container = article.querySelector ('edit-container');
  if (container) {
    container.hidden = false;
    article.classList.add ('editing');
    var body = container.querySelector ('.control[data-name=body]');
    if (body) body.focus ();
    return;
  }

  container = document.createElement ('edit-container');
  container.hidden = false;
  article.classList.add ('editing');
  container.appendChild (template.content.cloneNode (true));
  article.appendChild (container);

  $$ (container, 'form').forEach (function (form) {
    article.getAttribute ('data-index-list').split (/ /).forEach (function (indexId) {
      if (!indexId) return;
      var input = document.createElement ('input');
      input.type = 'hidden';
      input.name = 'index_id';
      input.value = indexId;
      form.appendChild (input);
    });

    if (object) {
      $$ (form, '.control[data-name]').forEach (function (control) {
        // XXX sandbox
        control.innerHTML = object.data[control.getAttribute ('data-name')];
      });
      $$ (form, 'input[name]:not([type])').forEach (function (control) {
        control.value = object.data[control.name];
      });
    }

    // XXX autosave

    $$ (form, '.cancel-button').forEach (function (button) {
      button.onclick = function () {
        container.hidden = true;
        article.classList.remove ('editing');
      };
    });

    form.onsubmit = function () {
      $$ (container, '[type=submit], .cancel-button').forEach (function (button) {
        button.disabled = true;
// XXX disable controls
      });

// XXX progress
      saveObject (article, form, object).then (function (objectId) {
        $$ (container, '[type=submit], .cancel-button').forEach (function (button) {
          button.disabled = false;
        });
        container.hidden = true;
        article.classList.remove ('editing');
        if (object) {
          article.updateView ();
        } else {
          container.remove ();
          return gFetch ('o/get.json?object_id=' + objectId, {}).then (function (json) {
            var list = $$ (document, optEl.getAttribute ('data-list'))[0];
            list.showObjects (json.objects);
          });
        }
      }, function (error) {
        $$ (container, '[type=submit]').forEach (function (button) {
          button.disabled = false;
        });
        console.log (error); // XXX
      });
    };
  });

  var body = container.querySelector ('.control[data-name=body]');
  if (body) body.focus ();
} // editObject

function saveObject (article, form, object) {
  // XXX if not modified
  var fd = new FormData (form);
  var c = [];
  $$ (form, '.control[data-name]').forEach (function (control) {
    var name = control.getAttribute ('data-name');
    var value = control.innerHTML; // XXX
    fd.append (name, value);
    if (object) c.push (function () { object.data[name] = value });
  });
  $$ (form, 'input[name]:not([type])').forEach (function (control) {
    var name = control.name;
    var value = control.value;
    //fd.append (name, value);
    if (object) c.push (function () { object.data[name] = value });
  });
  return Promise.resolve ().then (function () {
    var objectId = article.getAttribute ('data-object');
    if (objectId) {
      return objectId;
    } else {
      return gFetch ('o/create.json', {post: true}).then (function (json) {
        return json.object_id;
      });
    }
  }).then (function (objectId) {
    return gFetch ('o/' + objectId + '/edit.json', {post: true, formData: fd}).then (function () {
      c.forEach (function (_) { _ () });
      if (object) object.updated = (new Date).valueOf () / 1000;
      return objectId;
    });
  });
} // saveObject

(new MutationObserver (function (mutations) {
  mutations.forEach (function (m) {
    Array.prototype.forEach.call (m.addedNodes, function (x) {
      if (x.localName === 'list-container') {
        upgradeList (x);
      }
    });
  });
})).observe (document.documentElement, {childList: true, subtree: true});
$$ (document, 'list-container').forEach (upgradeList);
