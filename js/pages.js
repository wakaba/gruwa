function $$ (n, s) {
  return Array.prototype.slice.call (n.querySelectorAll (s));
} // $$

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

function gFetch (pathquery, opts) {
  var body;
  if (opts.formData) {
    body = opts.formData;
  } else if (opts.form) {
    body = new FormData (opts.form);
  }
  return withFormDisabled (opts.form /* or null */, function () {
    return fetch ((document.documentElement.getAttribute ('data-group-url') || '') + '/' + pathquery, {
      credentials: "same-origin",
      method: opts.post ? 'POST' : 'GET',
      body: body,
      referrerPolicy: 'origin',
    }).then (function (res) {
      if (res.status !== 200) throw res;
      return res.json ();
    });
  });
} // gFetch

function withFormDisabled (form, code) {
  var disabledControls = [];
  if (form) {
    disabledControls = $$ (form, 'input:enabled, select:enabled, textarea:enabled, button:enabled, iframe.control:not([data-disabled])');
    disabledControls.forEach (function (control) {
      control.disabled = true;
      control.setAttribute ('data-disabled', '');
    });
  }
  return Promise.resolve ().then (code).then (function (result) {
    disabledControls.forEach (function (control) {
      control.disabled = false;
      control.removeAttribute ('data-disabled');
    });
    return result;
  }, function (error) {
    disabledControls.forEach (function (control) {
      control.disabled = false;
      control.removeAttribute ('data-disabled');
    });
    throw error;
  });
} // withFormDisabled

function createBodyHTML (value, opts) {
  var doc = (new DOMParser).parseFromString ("", "text/html");

  doc.documentElement.setAttribute ('data-group-url', document.documentElement.getAttribute ('data-group-url'));

  doc.head.innerHTML = '<base target=_top>';
  $$ (document.head, 'link.body-css').forEach (function (e) {
    var link = document.createElement ('link');
    link.rel = 'stylesheet';
    link.href = e.href;
    doc.head.appendChild (link);
  });
  $$ (document.head, 'link.body-js').forEach (function (e) {
    var script = document.createElement ('script');
    script.async = true;
    script.src = e.href;
    doc.head.appendChild (script);
  });

  $$ (document, 'template.body-edit-template').forEach (function (e) {
    doc.head.appendChild (e.cloneNode (true));
  });

  doc.documentElement.setAttribute ('data-theme', document.documentElement.getAttribute ('data-theme'));

  if (opts.edit) {
    doc.body.setAttribute ('contenteditable', '');
    doc.body.setAttribute ('onload', 'document.body.focus ()');
  }
  doc.body.innerHTML = value || '';

  if (opts.edit) {
    $$ (doc.body, 'section').forEach (function (e) {
      e.setAttribute ('contenteditable', 'false');
    });
    $$ (doc.body, 'section > h1, section > main').forEach (function (e) {
      e.setAttribute ('contenteditable', 'true');
    });
  }

  return doc.documentElement.outerHTML;
} // createBodyHTML

function fillFields (contextEl, rootEl, el, object) {
  if (object.account_id &&
      object.account_id === document.documentElement.getAttribute ('data-account')) {
    rootEl.classList.add ('account-is-self');
  }
  $$ (el, '[data-field]').forEach (function (field) {
    var value = object[field.getAttribute ('data-field')];
    if (field.localName === 'input' ||
        field.localName === 'select') {
      field.value = value;
    } else if (field.localName === 'time') {
      var date = new Date (parseFloat (value) * 1000);
      try {
        field.setAttribute ('datetime', date.toISOString ());
        field.textContent = date.toLocaleString ();
      } catch (e) {
        console.log (e); // XXX
      }
    } else if (field.localName === 'enum-value') {
      var v = field.getAttribute ('text-' + value);
      field.setAttribute ('value', value);
      if (v) {
        field.textContent = v;
      } else {
        field.textContent = value;
      }
      if (field.parentNode.localName === 'td') {
        field.parentNode.setAttribute ('data-value', value);
      }
    } else if (field.localName === 'account-name') {
      field.setAttribute ('account_id', value);
      field.textContent = value;
    } else {
      field.textContent = value || field.getAttribute ('data-empty');
    }
  });
  $$ (el, '[data-if-field]').forEach (function (field) {
    field.hidden = !object[field.getAttribute ('data-if-field')];
  });
  $$ (el, '[data-if-data-field]').forEach (function (field) {
    var value = object.data[field.getAttribute ('data-if-data-field')];
    var ifValue = field.getAttribute ('data-if-value');
    if (ifValue) {
      field.hidden = ifValue != value;
    } else {
      field.hidden = !value;
    }
  });
  $$ (el, '[data-if-data-non-empty-field]').forEach (function (field) {
    var value = object.data[field.getAttribute ('data-if-data-non-empty-field')];
    field.hidden = !(value && Object.keys (value).length);
  });
  $$ (el, '[data-checked-field]').forEach (function (field) {
    field.checked = object[field.getAttribute ('data-checked-field')];
  });
  $$ (el, '[data-href-template]').forEach (function (field) {
    var template = field.getAttribute ('data-' + contextEl.getAttribute ('data-context') + '-href-template') || field.getAttribute ('data-href-template');
    field.href = template.replace (/\{GROUP\}/g, function () {
      return document.documentElement.getAttribute ('data-group-url');
    }).replace (/\{INDEX_ID\}/, function () {
      return document.documentElement.getAttribute ('data-index');
    }).replace (/\{PARENT\}/, function () {
      return contextEl.getAttribute ('data-parent');
    }).replace (/\{([^{}]+)\}/g, function (_, k) {
      return encodeURIComponent (object[k]);
    });
  });
  $$ (el, '[data-src-template]').forEach (function (field) {
    field.setAttribute ('src', field.getAttribute ('data-src-template').replace (/\{([^{}]+)\}/g, function (_, k) {
      return object[k];
    }));
  });
  $$ (el, '[data-data-action-template]').forEach (function (field) {
    field.setAttribute ('data-action', field.getAttribute ('data-data-action-template').replace (/\{([^{}]+)\}/g, function (_, k) {
      return object[k];
    }));
    field.parentObject = object;
  });
  $$ (el, '[data-parent-template]').forEach (function (field) {
    field.setAttribute ('data-parent', field.getAttribute ('data-parent-template').replace (/\{([^{}]+)\}/g, function (_, k) {
      return encodeURIComponent (object[k]);
    }));
  });
  $$ (el, '[data-context-template]').forEach (function (field) {
    field.setAttribute ('data-context', field.getAttribute ('data-context-template').replace (/\{([^{}]+)\}/g, function (_, k) {
      return encodeURIComponent (object[k]);
    }));
  });
  $$ (el, '[data-data-field]').forEach (function (field) {
    var value = object.data[field.getAttribute ('data-data-field')];
    if (field.localName === 'time') {
      var date = new Date (parseFloat (value) * 1000);
      try {
        field.setAttribute ('datetime', date.toISOString ());
        field.textContent = date.toLocaleString ();
      } catch (e) {
        console.log (e); // XXX
      }
    } else if (field.localName === 'index-list') {
      field.textContent = '';
      Object.keys (value || {}).forEach (function (indexId) {
        var a = document.createElement ('a');
        a.href = document.documentElement.getAttribute ('data-group-url') + '/i/' + encodeURIComponent (indexId) + '/';
        a.textContent = indexId;
        $with ('index-list').then (function (datalist) {
          if (!datalist.indexIdToLabel) {
            var list = {};
            $$ (datalist, 'option').forEach (function (option) {
              list[option.value] = option.label;
            });
            datalist.indexIdToLabel = list;
          }
          a.textContent = datalist.indexIdToLabel[indexId] || indexId;
          a.classList.toggle ('this-index', indexId == document.documentElement.getAttribute ('data-index'));
        });
        field.appendChild (a);
      });
    } else if (field.localName === 'account-list') {
      field.textContent = '';
      Object.keys (value || {}).forEach (function (accountId) {
        var a = document.createElement ('account-name');
        a.setAttribute ('account_id', accountId);
        a.textContent = accountId;
        field.appendChild (a);
      });
    } else if (field.localName === 'iframe') {
      field.setAttribute ('sandbox', 'allow-scripts allow-top-navigation');
      field.setAttribute ('srcdoc', createBodyHTML (value, {}));
      field.onload = function () {
        var mc = new MessageChannel;
        this.contentWindow.postMessage ({type: "getHeight"}, '*', [mc.port1]);
        mc.port2.onmessage = function (ev) {
          if (ev.data.type === 'height') {
            field.style.height = ev.data.value + 'px';
          } else if (ev.data.type === 'changed') {
            var v = new Event ('editablecontrolchange', {bubbles: true});
            v.data = ev.data;
            field.dispatchEvent (v);
          }
        };
        field.onload = null;
      };
    } else {
      field.textContent = value || field.getAttribute ('data-empty') || '';
    }
  });
  if (rootEl.startEdit) {
    $$ (el, '.edit-button').forEach (function (button) {
      button.onclick = function () { rootEl.startEdit () };
    });
    $$ (el, '.edit-by-dblclick').forEach (function (button) {
      button.ondblclick = function () { rootEl.startEdit () };
    });
  }
} // fillFields

function upgradeList (el) {
  if (el.upgraded) return;
  el.upgraded = true;

  var as = getActionStatus (el);

  el.clearObjects = function () {
    var main = $$ (this, 'list-main')[0];
    if (main) main.textContent = '';
  }; // clearObjects

  el.showObjects = function (objects, opts) {
    var template = $$ (this, 'template')[0];
    var type = el.getAttribute ('type');
    var main;
    if (type === 'table') {
      main = $$ (this, 'table tbody')[0];
    } else if (type === 'datalist') {
      main = $$ (this, 'datalist')[0];
    } else {
      main = $$ (this, 'list-main')[0];
    }
    if (!template || !main) return Promise.resolve (null);

    var listObjects = Object.values (objects);
    var appended = false;
    var wait = [];

    var itemType = el.getAttribute ('listitemtype');
    var elementType = {
      object: 'article',
    }[itemType] || {
      table: 'tr',
      datalist: 'option',
    }[type] || 'list-item';

    var fill = function (item, object) {
          if (itemType === 'object') {
            item.setAttribute ('data-object', object.object_id);
            item.startEdit = function () {
              editObject (item, object, {open: true});
            }; // startEdit
            item.updateView = function () {
              Array.prototype.forEach.call (item.children, function (f) {
                if (f.localName !== 'edit-container') {
                  fillFields (el, item, f, object);
                }
              });
            }; // updateView
            item.addEventListener ('objectdataupdate', function (ev) {
              this.updateView ();
            });
            item.addEventListener ('editablecontrolchange', function (ev) {
              var as = getActionStatus (item);
              as.start ({stages: ["formdata", "create", "edit", "update"]});
              var open = false; // XXX true if edit-container is modified but not saved
              editObject (item, object, {open: open}).then (function () {
                $$ (item, 'edit-container iframe.control[data-name=body]').forEach (function (e) {
                  e.sendChange (ev.data);
                });
                return item.save ({actionStatus: as});
              }).then (function () {
                as.end ({ok: true});
              }, function (error) {
                as.end ({error: error});
              });
            });

        item.updateView ();
      } else {
        fillFields (el, item, item, object);
      }
    }; // fill

    if (el.hasAttribute ('grouped')) {
      var grouped = {};
      listObjects.forEach (function (object) {
        var date = new Date ((object.data.timestamp || 0) * 1000);
        var key = date.getUTCFullYear () + '-' + date.getUTCMonth () + '-' + date.getUTCDate ();
        grouped[key] = grouped[key] || [];
        grouped[key].push (object);
      });

      Object.keys (grouped).sort (function (a, b) {
        return (grouped[b][0].data.timestamp || 0) -
               (grouped[a][0].data.timestamp || 0);
      }).forEach (function (key) {
        grouped[key] = grouped[key].sort (function (a, b) {
          return b.created - a.created;
        });

        var section = document.createElement ('section');
        var h = document.createElement ('h1');
        var t = document.createElement ('time');
        var date = new Date ((grouped[key][0].data.timestamp || 0) * 1000);
        try {
          t.setAttribute ('datetime', date.toISOString ());
        } catch (e) {
          console.log (e); // XXX
        }
        t.textContent = date.getUTCFullYear () + '/' + (date.getUTCMonth () + 1) + '/' + date.getUTCDate (); // XXX
        h.appendChild (t);
        section.appendChild (h);

        grouped[key].forEach (function (object) {
          var item = document.createElement (elementType);
          item.className = template.className;
          item.appendChild (template.content.cloneNode (true));
          fill (item, object);
          section.appendChild (item);
        });
        if (opts.prepend) {
          main.insertBefore (section, main.firstChild);
        } else {
          main.appendChild (section);
        }
        appended = true;
      });
    } else { // not grouped
      var sorter;
      var sortKey = el.getAttribute ('sortkey');
      if (sortKey === 'updated') {
        sorter = function (a, b) { return b.updated - a.updated };
      } else if (sortKey === 'created') {
        sorter = function (a, b) { return b.created - a.created };
      } else if (sortKey === 'timestamp,created') {
        sorter = function (a, b) { return b.timestamp - a.timestamp || b.created - a.created };
      }
      if (sorter) listObjects = listObjects.sort (sorter);

      if (elementType === 'option') {
        listObjects.forEach (function (object) {
          var item = document.createElement (elementType);
          item.className = template.className;
          var key = template.getAttribute ('data-label');
          if (key) item.setAttribute ('label', object[key]);
          var aKey = template.getAttribute ('data-account-label');
          if (aKey) {
            wait.push ($with ('account', {accountId: object.account_id}).then (function (account) {
              item.setAttribute ('label', account[aKey]);
            }));
          }
          var key = template.getAttribute ('data-value');
          if (key) item.setAttribute ('value', object[key]);
          main.appendChild (item);
          appended = true;
        });
      } else {
        listObjects.forEach (function (object) {
          var item = document.createElement (elementType);
          item.className = template.className;
          item.appendChild (template.content.cloneNode (true));
          fill (item, object);
          main.appendChild (item);
          appended = true;
        });
      }
    } // not grouped

    $$ (this, 'list-is-empty').forEach (function (e) {
      if (main.firstElementChild) {
        e.hidden = true;
      } else {
        e.hidden = false;
      }
    });

    $$ (this, '.next-page-button').forEach (function (button) {
      button.hidden = ! (opts.hasNext && appended);
    });

    return Promise.all (wait).then (function () { return main });
  }; // showObjects

  var nextRef = null;
  var load = function () {
    var url = el.getAttribute ('src') || 'o/get.json?with_data=1';
    [
      'src-object_id', 'src-index_id', 'src-wiki_name',
      'src-limit',
    ].forEach (function (attr) {
      var value = el.getAttribute (attr);
      if (value) {
        url += /\?/.test (url) ? '&' : '?';
        url += attr.replace (/^src-/, '') + '=' + encodeURIComponent (value);
      }
    });
    if (url) {
      var q = el.getAttribute ('param-q');
      if (q) {
        url += (/\?/.test (url) ? '&' : '?') + 'q=' + encodeURIComponent (q);
      }
      if (nextRef) {
        url += (/\?/.test (url) ? '&' : '?') + 'ref=' + encodeURIComponent (nextRef);
      }
      as.stageStart ("load");
      return gFetch (url, {}).then (function (json) {
        as.stageEnd ("load");
        return json;
      });
    } else {
      return Promise.resolve ({});
    }
  }; // load

  var show = function (json) {
    var key = el.getAttribute ('key');
    var hasNext = json.next_ref && nextRef !== json.next_ref;
    return el.showObjects (json[key], {hasNext: hasNext}).then (function (main) {
      if (hasNext) {
        nextRef = json.next_ref;
      } else {
        nextRef = null;
      }
      return main; // or null
    });
  }; // show

  el.load = function () {
    as.start ({stages: ["prep", "load", "show"]});
    nextRef = null;
    $$ (el, '.search-wiki_name-link').forEach (function (e) {
      var q = el.getAttribute ('param-q');
      e.hidden = ! /^\s*\S+\s*$/.test (q);
      fillFields (el, e, e, {name: q.replace (/^\s+/, '').replace (/\s+$/, '')});
    });
    as.stageEnd ("prep");
    load ().then (function (json) {
      el.clearObjects ();
      return show (json);
    }).then (function (main) {
      if (main && main.id) {
        $with.register (main.id, function () {
          return main;
        });
      }
      as.end ({ok: true});
    }).catch (function (error) {
      as.end ({error: error});
    });
  }; // load
  el.load ();

  $$ (el, '.next-page-button').forEach (function (button) {
    button.onclick = function () {
      button.disabled = true;
      as.start ({stages: ["prep", "load", "show"]});
      as.stageEnd ("prep");
      load ().then (show).then (function () {
        button.disabled = false;
        as.end ({ok: true});
      }, function (error) {
        button.disabled = false;
        as.end ({error: error});
      });
    };
  });

  $$ (el, 'article.object.new').forEach (function (article) {
    $$ (article, '.edit-button').forEach (function (button) {
      button.onclick = function () {
        var data = {index_ids: {}, timestamp: (new Date).valueOf () / 1000};
        data.index_ids[el.getAttribute ('src-index_id')] = 1;
        var wikiName = el.getAttribute ('src-wiki_name');
        if (wikiName) data.title = wikiName;
        editObject (article, {data: data}, {open: true});
      };
    });
  });

  $$ (el, '.search-form').forEach (function (form) {
    form.onsubmit = function () {
      Array.prototype.forEach.call (form.elements, function (e) {
        if (e.name) el.setAttribute ('param-' + e.name, e.value);
      });
      el.clearObjects ();
      el.load ();
      var url = form.getAttribute ('data-pjax');
      if (url) {
        history.replaceState (null, null, url.replace (/\{([A-Za-z0-9]+)\}/g, function (_, n) {
          return form.elements[n].value;
        }));
      }
      return false;
    };
  });
} // upgradeList

function editObject (article, object, opts) {
  var wait = [];
  var template = document.querySelector ('#edit-form-template');

  var container = article.querySelector ('edit-container');
  if (container) {
    if (opts.open) {
      container.hidden = false;
      article.classList.add ('editing');
      var body = container.querySelector ('.control[data-name=body]');
      if (body) body.focus ();
    }
    return Promise.all (wait);
  }

  container = document.createElement ('edit-container');
  container.hidden = true;
  container.appendChild (template.content.cloneNode (true));
  article.appendChild (container);
  var form = container.querySelector ('form');

  article.save = function (opts) {
    return withFormDisabled (form, function () {
      return saveObject (article, form, object, opts);
    });
  }; // save

  $$ (form, 'main .control, header input').forEach (function (control) {
    control.onfocus = function () {
      container.scrollIntoView ();
    };
  });

  $$ (form, 'iframe.control[data-name]').forEach (function (control) {
    var value = object.data[control.getAttribute ('data-name')];
    var valueWaitings = [];
    control.setAttribute ('sandbox', 'allow-scripts allow-popups');
    control.setAttribute ('srcdoc', createBodyHTML (value, {edit: true}));
    var mc = new MessageChannel;
    control.onload = function () {
      this.contentWindow.postMessage ({type: "getHeight"}, '*', [mc.port1]);
      mc.port2.onmessage = function (ev) {
        if (ev.data.type === 'focus') {
          control.dispatchEvent (new Event ("focus", {bubbles: true}));
        } else if (ev.data.type === 'currentValue') {
          valueWaitings.forEach (function (f) {
            f (ev.data.value);
          });
          valueWaitings = [];
        } else if (ev.data.type === 'currentState') {
          $$ (form, 'button[data-action=execCommand]').forEach (function (b) {
            var value = ev.data.value[b.getAttribute ('data-command')];
            if (value === undefined) return;
            b.classList.toggle ('active', value);
          });
        } else if (ev.data.type === 'prompt') {
          var args = ev.data.value;
          var result = prompt (args.prompt, args.default);
          ev.ports[0].postMessage ({result: result});
        }
      };
      control.onload = null;
    };
    control.sendExecCommand = function (name, value) {
      mc.port2.postMessage ({type: "execCommand", command: name, value: value});
    };
    control.setBlock = function (value) {
      mc.port2.postMessage ({type: "setBlock", value: value});
    };
    control.insertSection = function () {
      mc.port2.postMessage ({type: "insertSection"});
    };
    control.sendAction = function (type, command, value) {
      mc.port2.postMessage ({type: type, command: command, value: value});
    };
    control.getCurrentValue = function () {
      mc.port2.postMessage ({type: "getCurrentValue"});
      return new Promise (function (ok) { valueWaitings.push (ok) });
    };
    control.sendChange = function (data) {
      mc.port2.postMessage ({type: "change", value: data});
    };
  });
  $$ (form, 'button[data-action=execCommand]').forEach (function (b) {
    b.onclick = function () {
      var ed = form.querySelector ('iframe.control[data-name=body]');
      ed.sendExecCommand (this.getAttribute ('data-command'), this.getAttribute ('data-value'));
      ed.focus ();
    };
  });
  $$ (form, 'button[data-action=setBlock]').forEach (function (b) {
    b.onclick = function () {
      var ed = form.querySelector ('iframe.control[data-name=body]');
      ed.setBlock (this.getAttribute ('data-value'));
      ed.focus ();
    };
  });
  $$ (form, 'button[data-action=insertSection]').forEach (function (b) {
    b.onclick = function () {
      var ed = form.querySelector ('iframe.control[data-name=body]');
      ed.insertSection ();
      ed.focus ();
    };
  });
  $$ (form, 'button[data-action=indent], button[data-action=outdent], button[data-action=insertControl], button[data-action=link]').forEach (function (b) {
    b.onclick = function () {
      var ed = form.querySelector ('iframe.control[data-name=body]');
      ed.sendAction (b.getAttribute ('data-action'), b.getAttribute ('data-command'), b.getAttribute ('data-value'));
      ed.focus ();
    };
  });
  $$ (form, 'input[name]:not([type])').forEach (function (control) {
    var value = object.data[control.name]
    if (value) {
      control.value = value;
    }
  });
  $$ (form, 'input[name][type=date]').forEach (function (control) {
    var value = object.data[control.name];
    if (value != null) {
      control.valueAsNumber = value * 1000;
    }
  });

  $$ (form, 'list-control[name]').forEach (function (control) {
    control.clearItems = function () {
      control.items = [];
      var main = control.querySelector ('list-control-main');
      main.textContent = '';
    };
    control.addItems = function (newItems) {
      control.items = control.items.concat (newItems);
      var template = control.querySelector ('template');
      var main = control.querySelector ('list-control-main');
      $with (control.getAttribute ('list')).then (function (datalist) {
        var valueToLabel = {};
        $$ (datalist, 'option').forEach (function (option) {
          valueToLabel[option.value] = option.label;
        });
        newItems.forEach (function (item) {
          var itemEl = document.createElement ('list-item');
          itemEl.appendChild (template.content.cloneNode (true));
          item.label = valueToLabel[item.value];
          fillFields (main, itemEl, itemEl, item);
          main.appendChild (itemEl);
        });
      });
    };

    wait.push ($with (control.getAttribute ('list')).then (function (datalist) {
      $$ (control, '.edit-button').forEach (function (el) {
        el.onclick = function () {
          if (!control.editor) {
            var template = document.querySelector ('#list-control-editor');
            if (!template) return;
            control.editor = control.querySelector ('list-dropdown');
            control.editor.appendChild (template.content.cloneNode (true));
            control.editor.hidden = true;

            var eTemplate = control.editor.querySelector ('template');
            var valueToSelected = {};
            var valueListed = {};
            control.items.forEach (function (item) {
              valueToSelected[item.value] = true;
            });
            var listEl = control.editor.querySelector ('list-editor-main');
            var addItem = function (option) {
              var itemEl = document.createElement ('list-item');
              itemEl.appendChild (eTemplate.content.cloneNode (true));
              itemEl.setAttribute ('value', option.value);
              fillFields (listEl, itemEl, itemEl, option);
              listEl.appendChild (itemEl);
            }; // addItem
            $$ (datalist, 'option').forEach (function (option) {
              addItem ({
                label: option.label,
                value: option.value,
                selected: valueToSelected[option.value],
              });
              valueListed[option.value] = true;
            });
            control.items.forEach (function (item) {
              if (!valueListed[item.value]) {
                addItem ({
                  label: item.value,
                  value: item.value,
                  selected: true,
                });
              }
            });
            listEl.onchange = function () {
              var items = $$ (listEl, 'list-item').filter (function (itemEl) {
                return itemEl.querySelector ('input[type=checkbox]:checked');
              }).map (function (el) {
                return {value: el.getAttribute ('value')};
              });
              control.clearItems ();
              control.addItems (items);
            };

            var allowAdd = control.hasAttribute ('allowadd');
            $$ (control.editor, '.add-form').forEach (function (e) {
              e.hidden = !allowAdd;
              if (!allowAdd) return;
              $$ (e, '.add-button').forEach (function (b) {
                b.onclick = function () {
                  var input = e.querySelector ('input');
                  var v = input.value;
                  if (!v) return;
                  addItem ({label: v, value: v, selected: true});
                  listEl.dispatchEvent (new Event ('change'));
                  input.value = '';
                };
              });
            });
          }
          control.editor.hidden = !control.editor.hidden;
          el.classList.toggle ('active', !control.editor.hidden);
        };
      });

      var dataKey = control.getAttribute ('key');
      control.addItems (Object.keys (object.data[dataKey] || {}).map (function (v) {
        return {value: v};
      }));
    })); // $with
    control.clearItems ();
  }); // list-control

    // XXX autosave

    $$ (form, '.cancel-button').forEach (function (button) {
      button.onclick = function () {
        container.hidden = true;
        article.classList.remove ('editing');
      };
    });

  form.onsubmit = function () {
    var as = getActionStatus (form);
    as.start ({stages: ["dataset", "create", "edit", "update"]});
    article.save ({actionStatus: as}).then (function (objectId) {
      as.stageStart ("update");
      if (object.object_id) {
        article.updateView ();
        //as.stageEnd ("update");
        container.hidden = true;
        article.classList.remove ('editing');
        as.end ({ok: true});
      } else { // new object
        return gFetch ('o/get.json?with_data=1&object_id=' + objectId, {}).then (function (json) {
          return document.querySelector ('list-container[src-index_id]')
              .showObjects (json.objects, {prepend: true});
        }).then (function () {
          //as.stageEnd ("update");
          as.end ({ok: true});
        }, function (error) {
          as.end ({ok: false, error: error});
          // XXX open the permalink page?
        }).then (function () {
          container.remove ();
          article.classList.remove ('editing');
        });
      }
    }).catch (function (error) {
      as.end ({ok: false, error: error});
    });;
  }; // onsubmit

  var resize = function () {
    var h1 = 0;
    $$ (container, 'form > header, form > main > menu, form > footer').forEach (function (e) {
      h1 += e.offsetHeight;
    });
    var h = document.documentElement.clientHeight - h1;
    container.querySelector ('main > iframe.control').style.height = h + 'px';
  }; // resize
  addEventListener ('resize', resize);
  wait.push (Promise.resolve ().then (resize));

  if (opts.open) {
    container.hidden = false;
    article.classList.add ('editing');
    var body = container.querySelector ('.control[data-name=body]');
    if (body) body.focus ();
  }

  return Promise.all (wait);
} // editObject

function saveObject (article, form, object, opts) {
  // XXX if not modified
  var fd = new FormData;
  var c = [];
  var ps = [];
  $$ (form, '.control[data-name]').forEach (function (control) {
    var name = control.getAttribute ('data-name');
    ps.push (control.getCurrentValue ().then (function (value) {
      fd.append (name, value);
      c.push (function () { object.data[name] = value });
    }));
  });
  $$ (form, 'input[name]:not([type]), input[name][type=hidden]').forEach (function (control) {
    var name = control.name;
    var value = control.value;
    fd.append (name, value);
    c.push (function () { object.data[name] = value });
  });
  $$ (form, 'input[name][type=date]').forEach (function (control) {
    var name = control.name;
    var value = control.valueAsNumber / 1000;
    fd.append (name, value);
    c.push (function () { object.data[name] = value });
  });
  $$ (form, 'list-control[name]').forEach (function (control) {
    var name = control.getAttribute ('name');
    var cc = {};
    control.items.forEach (function (item) {
      fd.append (name, item.value);
      cc[item.value] = 1;
    });
    c.push (function () { object.data[control.getAttribute ('key')] = cc });
  });
  return Promise.all (ps).then (function () {
    opts.actionStatus.stageEnd ("dataset");
    opts.actionStatus.stageStart ("create");
    var objectId = article.getAttribute ('data-object');
    if (objectId) {
      return objectId;
    } else {
      return gFetch ('o/create.json', {post: true}).then (function (json) {
        return json.object_id;
      });
    }
  }).then (function (objectId) {
    opts.actionStatus.stageEnd ("create");
    opts.actionStatus.stageStart ("edit");
    return gFetch ('o/' + objectId + '/edit.json', {post: true, formData: fd}).then (function () {
      c.forEach (function (_) { _ () });
      object.updated = (new Date).valueOf () / 1000;
      opts.actionStatus.stageEnd ("edit");
      return objectId;
    });
  });
} // saveObject

function getActionStatus (container) {
  var as = new ActionStatus;
  as.elements = $$ (container, 'action-status');
  as.elements.forEach (function (e) {
    if (e.hasChildNodes ()) return;
    e.hidden = true;
    e.innerHTML = '<action-status-message></action-status-message> <progress></progress>';
  });
  return as;
} // getActionStatus

function ActionStatus () {
  this.stages = {};
}

ActionStatus.prototype.start = function (opts) {
  var self = this;
  if (opts.stages) {
    opts.stages.forEach (function (s) {
      self.stages[s] = false;
    });
  }
  this.elements.forEach (function (e) {
    $$ (e, 'action-status-message').forEach (function (f) {
      f.hidden = true;
    });
    $$ (e, 'progress').forEach (function (f) {
      f.hidden = false;
      var l = Object.keys (self.stages).length;
      if (l) {
        f.max = l;
        f.value = 0;
      } else {
        f.removeAttribute ('max');
        f.removeAttribute ('value');
      }
    });
    e.hidden = false;
    e.removeAttribute ('status');
  });
}; // start

ActionStatus.prototype.stageStart = function (stage) {
  this.elements.forEach (function (e) {
    var label = e.getAttribute ('stage-' + stage);
    $$ (e, 'action-status-message').forEach (function (f) {
      if (label) {
        f.textContent = label;
        f.hidden = false;
      } else {
        f.hidden = true;
      }
    });
  });
};

ActionStatus.prototype.stageEnd = function (stage) {
  var self = this;
  this.stages[stage] = true;
  this.elements.forEach (function (e) {
    $$ (e, 'progress').forEach (function (f) {
      var stages = Object.keys (self.stages);
      f.max = stages.length;
      f.value = stages.filter (function (n) { return self.stages[n] }).length;
    });
  });
}; // stageEnd

ActionStatus.prototype.end = function (opts) {
  this.elements.forEach (function (e) {
    var shown = false;
    $$ (e, 'action-status-message').forEach (function (f) {
      var msg;
      var status;
      if (opts.ok) {
        msg = e.getAttribute ('ok');
      } else { // not ok
        if (opts.error) {
          if (opts.error instanceof Response) {
            msg = opts.error.status + ' ' + opts.error.statusText;
            console.log (opts.error); // for debugging
          } else {
            msg = opts.error;
            console.log (opts.error.stack); // for debugging
          }
        } else {
          msg = e.getAttribute ('ng') || 'Failed';
        }
      }
      if (msg) {
        f.textContent = msg;
        f.hidden = false;
        shown = true;
      } else {
        f.hidden = true;
      }
      // XXX set timer to clear ok message
    });
    $$ (e, 'progress').forEach (function (f) {
      f.hidden = true;
    });
    e.hidden = !shown;
    e.setAttribute ('status', opts.ok ? 'ok' : 'ng');
  });
}; // end


var stageActions = [];

stageActions.createGroupWiki = function (args) {
  args.as.stageStart ('creategroupwiki_1');
  var fd = new FormData;
  fd.append ('title', 'Wiki');
  fd.append ('index_type', 2);
  return gFetch ("g/" + args.result.group_id + '/i/create.json', {post: true, formData: fd}).then (function (json) {
    args.as.stageEnd ('creategroupwiki_1');
    args.as.stageStart ('creategroupwiki_2');
    var fd2 = new FormData;
    fd2.append ('default_wiki_index_id', json.index_id);
    return gFetch ("g/" + args.result.group_id + '/edit.json', {post: true, formData: fd2});
  }).then (function () {
    args.as.stageEnd ('creategroupwiki_2');
  });
}; // createGroupWiki
stageActions.createGroupWiki.stages = ["creategroupwiki_1", "creategroupwiki_2"];

function upgradeForm (form) {
  form.onsubmit = function () {
    var pt = form.getAttribute ('data-prompt');
    if (pt && !confirm (pt)) return;

    var addStages = (form.getAttribute ('data-additional-stages') || '').split (/\s+/).filter (function (x) { return x });
    var stages = ["prep", "fetch"];
    addStages.forEach (function (stage) {
      stages = stages.concat (stageActions[stage].stages);
    });
    stages = stages.concat (["next"]);
    var nextURL = form.getAttribute ('data-href-template');
    var as = getActionStatus (form);
    as.start ({stages: stages});
    var fd = new FormData (form); // this must be done before withFormDisabled
    withFormDisabled (nextURL ? form : null, function () {
      as.stageEnd ("prep");
      as.stageStart ("fetch");
      return gFetch (form.getAttribute ('data-action'), {post: true, formData: fd}).then (function (json) {
        as.stageEnd ("fetch");
        var p = Promise.resolve ();
        addStages.forEach (function (stage) {
          p = p.then (function () {
            return stageActions[stage] ({result: json, fd: fd, as: as});
          });
        });
        return p.then (function () {
          if (nextURL) {
            as.stageStart ("next");
            location.href = nextURL.replace (/\{(\w+)\}/g, function (_, key) {
              return json[key];
            });
            return new Promise (function () { }); // keep form disabled
          } else {
            if (form.parentObject) {
              var updated = false;
              $$ (form, '.data-field').forEach (function (e) {
                form.parentObject.data[e.name] = e.value;
                updated = true;
              });
              if (updated) {
                form.dispatchEvent (new Event ('objectdataupdate', {bubbles: true}));
              }
            }
          }
        });
      });
    }).then (function () {
      as.end ({ok: true});
    }, function (error) {
      as.end ({error: error});
    });
  };
} // upgradeForm

(function () {
  var accountData = {};
  var waiting = {};
  var timer = null;

  $with.register ('account', function (opts) {
    var id = opts.accountId;
    var entry = accountData[id];
    if (!entry) {
      entry = accountData[id] = new Promise (function (x, y) { waiting[id] = [x, y] });

      clearTimeout (timer);
      timer = setTimeout (function () {
        var ids = waiting;
        waiting = {};
        var fd = new FormData;
        Object.keys (ids).forEach (function (id) {
          fd.append ('account_id', id);
        });
        fetch ('/u/info.json', {method: 'POST', body: fd}).then (function (res) {
          if (res.status !== 200) throw res;
          return res.json ();
        }).then (function (json) {
          Object.keys (ids).forEach (function (id) {
            ids[id][0] (json.accounts[id]); // or undefined
          });
        }, function (error) {
          Object.values (ids).forEach (function (_) { _[1] (error) });
        });
      }, 500);
    }
    return entry;
  }); // $with ('account')
}) ();

function upgradeAccountName (e) {
  e.setAttribute ('loading', '');
  $with ('account', {accountId: e.getAttribute ('account_id')}).then (function (account) {
    e.textContent = account.name;
    e.removeAttribute ('loading');
  }, function (error) {
    console.log (error); // XXX
  });
} // upgradeAccountName

(new MutationObserver (function (mutations) {
  mutations.forEach (function (m) {
    Array.prototype.forEach.call (m.addedNodes, function (x) {
      if (x.localName === 'list-container') {
        upgradeList (x);
      } else if (x.localName) {
        $$ (x, 'list-container').forEach (upgradeList);
      }
      if (x.localName === 'account-name' &&
          x.hasAttribute ('account_id')) {
        upgradeAccountName (x);
      } else if (x.localName) {
        $$ (x, 'account-name[account_id]').forEach (upgradeAccountName);
      }
      if (x.localName === 'form') {
        if (x.getAttribute ('action') === 'javascript' &&
            x.hasAttribute ('data-action')) {
          upgradeForm (x);
        }
      } else if (x.localName) {
        $$ (x, 'form[action="javascript:"][data-action]').forEach (upgradeForm);
      }
    });
  });
})).observe (document.documentElement, {childList: true, subtree: true});
$$ (document, 'list-container').forEach (upgradeList);
$$ (document, 'form[action="javascript:"][data-action]').forEach (upgradeForm);
$$ (document, 'account-name[account_id]').forEach (upgradeAccountName);
