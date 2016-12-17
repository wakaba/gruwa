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

  var head = '<base target=_top><link rel=stylesheet href><script src=/js/body.js />';
  doc.head.innerHTML = head;

  $$ (document, 'template.body-edit-template').forEach (function (e) {
    doc.head.appendChild (e.cloneNode (true));
  });

  doc.querySelector ('link[rel=stylesheet]').href = document.documentElement.getAttribute ('data-body-css-href');
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

function fillFields (rootEl, el, object) {
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
      field.setAttribute ('account', value);
      field.textContent = value; // XXX
    } else {
      field.textContent = value || field.getAttribute ('data-empty');
    }
  });
  $$ (el, '[data-if-field]').forEach (function (field) {
    field.hidden = !object[field.getAttribute ('data-if-field')];
  });
  $$ (el, '[data-checked-field]').forEach (function (field) {
    field.checked = object[field.getAttribute ('data-checked-field')];
  });
  $$ (el, '[data-href-template]').forEach (function (field) {
    field.href = field.getAttribute ('data-href-template').replace (/\{GROUP\}/g, function () {
      return document.documentElement.getAttribute ('data-group-url');
    }).replace (/\{([^{}]+)\}/g, function (_, k) {
      return object[k];
    });
  });
  $$ (el, '[data-src-template]').forEach (function (field) {
    field.setAttribute ('src', field.getAttribute ('data-src-template').replace (/\{([^{}]+)\}/g, function (_, k) {
      return object[k];
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
    } else if (field.localName === 'tag-list') {
      field.textContent = '';
      Object.keys (value || {}).forEach (function (tag) {
        var a = document.createElement ('a');
        a.href = document.documentElement.getAttribute ('data-group-url') + '/t/' + encodeURIComponent (tag);
        a.textContent = tag;
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
    if (!template || !main) return null;

    var listObjects = Object.values (objects);
    var appended = false;

    var itemType = el.getAttribute ('listitemtype');
    var elementType = {
      object: 'article',
    }[itemType] || {
      table: 'tr',
      datalist: 'option',
    }[type] || 'list-item';

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
          if (itemType === 'object') {
            item.setAttribute ('data-object', object.object_id);
            item.startEdit = function () {
              editObject (item, object, {open: true});
            }; // startEdit
            item.updateView = function () {
              Array.prototype.forEach.call (item.children, function (el) {
                if (el.localName !== 'edit-container') {
                  fillFields (item, el, object);
                }
              });
            }; // updateView
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
            fillFields (item, item, object);
          }
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
          fillFields (item, item, object);
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

    return main;
  }; // showObjects

  var nextRef = null;
  var load = function () {
    var url;
    var index = el.getAttribute ('index');
    if (index) {
      url = 'o/get.json?with_data=1&index_id=' + index;
    } else {
      var object = el.getAttribute ('object');
      if (object) {
        url = 'o/get.json?with_data=1&object_id=' + object;
      } else {
        url = el.getAttribute ('src');
      }
    }
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
    var main = el.showObjects (json[key], {hasNext: hasNext});
    if (hasNext) {
      nextRef = json.next_ref;
    } else {
      nextRef = null;
    }
    return main; // or null
  }; // show

  el.load = function () {
    as.start ({stages: ["prep", "load", "show"]});
    as.stageEnd ("prep");
    nextRef = null;
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
        data.index_ids[el.getAttribute ('index')] = 1;
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
    control.sendAction = function (command, value) {
      mc.port2.postMessage ({type: command, value: value});
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
  $$ (form, 'button[data-action=indent], button[data-action=outdent]').forEach (function (b) {
    b.onclick = function () {
      var ed = form.querySelector ('iframe.control[data-name=body]');
      ed.sendAction (b.getAttribute ('data-action'));
      ed.focus ();
    };
  });
  $$ (form, 'button[data-action=insertControl]').forEach (function (b) {
    b.onclick = function () {
      var ed = form.querySelector ('iframe.control[data-name=body]');
      ed.sendAction (b.getAttribute ('data-action'), b.getAttribute ('data-value'));
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
          fillFields (itemEl, itemEl, item);
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
              fillFields (itemEl, itemEl, option);
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
      control.clearItems ();
      control.addItems (Object.keys (object.data[dataKey] || {}).map (function (v) {
        return {value: v};
      }));
    })); // $with
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
          document.querySelector ('list-container[index]')
              .showObjects (json.objects, {prepend: true});
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

function upgradeForm (form) {
  form.onsubmit = function () {
    var nextURL = form.getAttribute ('data-href-template');
    var as = getActionStatus (form);
    as.start ({stages: ["prep", "fetch", "next"]});
    var fd = new FormData (form); // this must be done before withFormDisabled
    withFormDisabled (nextURL ? form : null, function () {
      as.stageEnd ("prep");
      as.stageStart ("fetch");
      return gFetch (form.getAttribute ('data-action'), {post: true, formData: fd}).then (function (json) {
        as.stageEnd ("fetch");
        if (nextURL) {
          as.stageStart ("next");
          location.href = nextURL.replace (/\{(\w+)\}/g, function (_, key) {
            return json[key];
          });
          return new Promise (function () { }); // keep form disabled
        }
      });
    }).then (function () {
      as.end ({ok: true});
    }, function (error) {
      as.end ({error: error});
    });
  };
} // upgradeForm

(new MutationObserver (function (mutations) {
  mutations.forEach (function (m) {
    Array.prototype.forEach.call (m.addedNodes, function (x) {
      if (x.localName === 'list-container') {
        upgradeList (x);
      } else if (x.localName) {
        $$ (x, 'list-container').forEach (upgradeList);
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
