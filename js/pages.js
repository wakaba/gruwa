function $$ (n, s) {
  return Array.prototype.slice.call (n.querySelectorAll (s));
} // $$

function $$c (n, s) {
  return Array.prototype.filter.call (n.querySelectorAll (s), function (e) {
    var f = e.parentNode;
    while (f) {
      if (f === n) break;
      if (f.localName === 'list-container' ||
          f.localName === 'edit-container' ||
          f.localName === 'list-query' ||
          f.localName === 'list-control') {
        return false;
      }
      f = f.parentNode;
    }
    return true;
  });
} // $$c

function $$c2 (n, s) {
  return Array.prototype.filter.call (n.querySelectorAll (s), function (e) {
    var f = e.parentNode;
    while (f) {
      if (f === n) break;
      if (f.localName === 'list-container' ||
          f.localName === 'edit-container' ||
          f.localName === 'list-query' ||
          f.localName === 'list-control' ||
          f.localName === 'form') {
        return false;
      }
      f = f.parentNode;
    }
    return true;
  });
} // $$c2

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
  if (opts.asStage) opts.as.stageStart (opts.asStage);
  var body;
  if (opts.formData) {
    body = opts.formData;
  } else if (opts.form) {
    body = new FormData (opts.form);
  } else {
    body = opts.body;
  }
  return withFormDisabled (opts.form /* or null */, function () {
    var url = (
      /^\//.test (pathquery)
        ? pathquery
        : (document.documentElement.getAttribute ('data-group-url') || '') + '/' + pathquery
    );
    var method = opts.post ? 'POST' : 'GET';
    if (opts.asStage) {
      return new Promise (function (ok, ng) {
        var xhr = new XMLHttpRequest;
        xhr.open (method, url, true);
        xhr.onreadystatechange = function () {
          if (xhr.readyState === 4) {
            if (xhr.status === 200) {
              if (opts.asStage) opts.as.stageEnd (opts.asStage);
              ok (JSON.parse (xhr.responseText));
            } else {
              ng (xhr.status + ' ' + xhr.statusText);
            }
          }
        };
        if (opts.asStage) {
          xhr.upload.onprogress = function (ev) {
            opts.as.stageProgress (opts.asStage, ev.loaded, ev.total);
          };
        }
        var meta = document.createElement ('meta');
        meta.name = 'referrer';
        meta.content = 'origin';
        document.head.appendChild (meta);
        xhr.send (body || undefined);
        document.head.removeChild (meta);
      });
    } else {
      return fetch (url, {
        credentials: "same-origin",
        method: method,
        body: body,
        referrerPolicy: 'origin',
      }).then (function (res) {
        if (res.status !== 200) throw res;
        if (opts.asStage) opts.as.stageEnd (opts.asStage);
        return res.json ();
      });
    }
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
    if (!opts.focusTitle) {
      doc.body.setAttribute ('onload', 'document.body.focus ()');
    }
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

var FieldCommands = {};

FieldCommands.editJumpLabel = function () {
  var item = this.parentNode.parentNode;
  var label = item.querySelector ('[data-field=label]').textContent;
  var newLabel = prompt (this.getAttribute ('data-prompt'), label);
  if (newLabel == null || newLabel === label) return;
  var as = getActionStatus (item);
  as.start ({stages: ["fetch"]});
  as.stageStart ('fetch');
  var fd = new FormData;
  fd.append ('url', item.querySelector ('a[data-href-template]').href);
  fd.append ('label', newLabel);
  gFetch ('/jump/add.json', {post: true, formData: fd}).then (function () {
    $$ (item, '[data-field=label]').forEach (function (e) {
      e.textContent = newLabel;
    });
    as.stageEnd ('fetch');
    as.end ({ok: true});
  }, function (error) {
    as.end ({error: error});
  });
}; // editJumpLabel

FieldCommands.deleteJump = function () {
  var item = this.parentNode.parentNode;
  var as = getActionStatus (item);
  as.start ({stages: ["fetch"]});
  as.stageStart ('fetch');
  var fd = new FormData;
  fd.append ('url', item.querySelector ('a[data-href-template]').href);
  gFetch ('/jump/delete.json', {post: true, formData: fd}).then (function () {
    item.parentNode.removeChild (item);
    as.stageEnd ('fetch');
    as.end ({ok: true});
  }, function (error) {
    as.end ({error: error});
  });
}; // deleteJump

function fillFields (contextEl, rootEl, el, object) {
  if (object.account_id &&
      object.account_id === document.documentElement.getAttribute ('data-account')) {
    rootEl.classList.add ('account-is-self');
  }
  $$c (el, '[data-field]').forEach (function (field) {
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
  $$c (el, '[data-if-field]').forEach (function (field) {
    field.hidden = !object[field.getAttribute ('data-if-field')];
  });
  $$c (el, '[data-if-data-field]').forEach (function (field) {
    var value = object.data[field.getAttribute ('data-if-data-field')];
    var ifValue = field.getAttribute ('data-if-value');
    if (ifValue) {
      field.hidden = ifValue != value;
    } else {
      field.hidden = !value;
    }
  });
  $$c (el, '[data-if-data-non-empty-field]').forEach (function (field) {
    var value = object.data[field.getAttribute ('data-if-data-non-empty-field')];
    field.hidden = !(value && Object.keys (value).length);
  });
  $$c (el, '[data-checked-field]').forEach (function (field) {
    field.checked = object[field.getAttribute ('data-checked-field')];
  });
  $$c (el, '[data-href-template]').forEach (function (field) {
    var template = field.getAttribute ('data-' + contextEl.getAttribute ('data-context') + '-href-template') || field.getAttribute ('data-href-template');
    field.href = template.replace (/\{GROUP\}/g, function () {
      return document.documentElement.getAttribute ('data-group-url');
    }).replace (/\{INDEX_ID\}/, function () {
      return document.documentElement.getAttribute ('data-index');
    }).replace (/\{PARENT\}/, function () {
      return contextEl.getAttribute ('data-parent');
    }).replace (/\{URL\}/, function () {
      return object.url;
    }).replace (/\{([^{}]+)\}/g, function (_, k) {
      return encodeURIComponent (object[k]);
    });

    var pingTemplate = field.getAttribute ('data-ping-template');
    if (pingTemplate) {
      field.ping = pingTemplate.replace (/\{HREF\}/g, function () {
        return encodeURIComponent (field.href);
      }).replace (/\{([^{}]+)\}/g, function (_, k) {
        return encodeURIComponent (object[k]);
      });
    }
  });
  $$c (el, '[data-src-template]').forEach (function (field) {
    field.setAttribute ('src', field.getAttribute ('data-src-template').replace (/\{GROUP\}/g, function () {
      return document.documentElement.getAttribute ('data-group-url');
    }).replace (/\{([^{}]+)\}/g, function (_, k) {
      return encodeURIComponent (object[k]);
    }));
  });
  $$c (el, '[data-data-action-template]').forEach (function (field) {
    field.setAttribute ('data-action', field.getAttribute ('data-data-action-template').replace (/\{([^{}]+)\}/g, function (_, k) {
      return encodeURIComponent (object[k]);
    }));
    field.parentObject = object;
  });
  $$c (el, 'form[data-child-form]').forEach (function (field) {
    field.parentObject = object;
  });
  $$c (el, '[data-parent-template]').forEach (function (field) {
    field.setAttribute ('data-parent', field.getAttribute ('data-parent-template').replace (/\{([^{}]+)\}/g, function (_, k) {
      return encodeURIComponent (object[k]);
    }));
  });
  $$c (el, '[data-context-template]').forEach (function (field) {
    field.setAttribute ('data-context', field.getAttribute ('data-context-template').replace (/\{([^{}]+)\}/g, function (_, k) {
      return encodeURIComponent (object[k]);
    }));
  });
  $$c (el, '[data-color-field]').forEach (function (field) {
    var value = object[field.getAttribute ('data-color-field')];
    if (value) {
      var m = value.match (/#(..)(..)(..)/);
      var r = parseInt ("0x" + m[1]);
      var g = parseInt ("0x" + m[2]);
      var b = parseInt ("0x" + m[3]);
      var y = 0.299 * r + 0.587 * g + 0.114 * b;
      var c = y > 127 + 64 ? 0 : 255;
      field.style.backgroundColor = value;
      field.style.color = 'rgb('+c+','+c+','+c+')';
      field.classList.add ('colored');
    }
  });
  $$c (el, '[data-color-data-field]').forEach (function (field) {
    var value = object.data ? object.data[field.getAttribute ('data-color-data-field')] : null;
    if (value) {
      var m = value.match (/#(..)(..)(..)/);
      var r = parseInt ("0x" + m[1]);
      var g = parseInt ("0x" + m[2]);
      var b = parseInt ("0x" + m[3]);
      var y = 0.299 * r + 0.587 * g + 0.114 * b;
      var c = y > 127 + 64 ? 0 : 255;
      field.style.backgroundColor = value;
      field.style.color = 'rgb('+c+','+c+','+c+')';
      field.classList.add ('colored');
    }
  });
  $$c (el, '[data-data-field]').forEach (function (field) {
    var value = object.data ? object.data[field.getAttribute ('data-data-field')] : null;
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
    } else if (field.localName === 'index-list') {
      field.textContent = '';
      var template = document.querySelector ('#index-list-item-template');
      $with ('index-list').then (function (list) {
        var objects = Object.keys (value || {}).map (function (indexId) {
          return list[indexId] || {index_id: indexId, title: indexId};
        });
        objects = applyFilters (objects, field.getAttribute ('filters'));
        objects.forEach (function (object) {
          var item = document.createElement ('index-list-item');
          item.appendChild (template.content.cloneNode (true));
          fillFields (item, item, item, object);
          item.classList.toggle ('this-index', object.index_id == document.documentElement.getAttribute ('data-index'));
          field.appendChild (item);
        });
      });
    } else if (field.localName === 'account-list') {
      field.textContent = '';
      var template = document.querySelector ('#account-list-item-template');
      Object.keys (value || {}).forEach (function (accountId) {
        var item = document.createElement ('list-item');
        item.appendChild (template.content.cloneNode (true));
        fillFields (item, item, item, {account_id: accountId});
        field.appendChild (item);
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
    } else if (field.localName === 'todo-state') {
      if (value) {
        field.setAttribute ('value', value);
        value = field.getAttribute ('label-' + value);
      }
      if (value) {
        field.textContent = value;
        field.hidden = false;
      } else {
        field.hidden = true;
      }
    } else if (field.localName === 'progress') {
      field.setAttribute ('value', value);
      var maxKey = field.getAttribute ('data-max-data-field');
      if (maxKey) {
        var max = object.data ? object.data[maxKey] : null;
        if (max) field.setAttribute ('max', max);
      }
    } else if (field.localName === 'unit-number') {
      var unitType = field.getAttribute ('type');
      if (unitType === 'bytes') {
        var v = parseFloat (value);
        var u = 'B';
        field.title = v + u;
        if (v > 1000) {
          v = Math.round (v / 1024 * 10) / 10;
          u = 'KB';
          if (v > 1000) {
            v = Math.round (v / 1024 * 10) / 10;
            u = 'MB';
            if (v > 1000) {
              v = Math.round (v / 1024 * 10) / 10;
              u = 'GB';
            }
          }
        }
        field.innerHTML = '<number-value></number-value><number-unit></number-unit>';
        field.firstChild.textContent = v.toLocaleString ();
        field.lastChild.textContent = u;
      } else {
        field.textContent = parseFloat (value).toLocaleString ();
      }
    } else {
      field.textContent = value || field.getAttribute ('data-empty') || '';
    }
  });
  $$c (el, '[data-data-account-field]').forEach (function (field) {
    field.textContent = object && object.data && object.data.account ? object.data.account[field.getAttribute ('data-data-account-field')] : null;
  });
  $$c (el, '[data-title-data-field]').forEach (function (field) {
    field.title = object && object.data ? object.data[field.getAttribute ('data-title-data-field')] : null;
  });
  $$c (el, 'button[data-command]').forEach (function (e) {
    e.onclick = FieldCommands[e.getAttribute ('data-command')]
  });
  if (rootEl.startEdit) {
    $$c (el, '.edit-button').forEach (function (button) {
      button.onclick = function () { rootEl.startEdit () };
    });
    $$c (el, '.edit-by-dblclick').forEach (function (button) {
      button.ondblclick = function () { rootEl.startEdit () };
    });
  }
} // fillFields

function fillFormControls (form, object, opts) {
  var wait = [];

  $$c (form, 'iframe.control[data-name]').forEach (function (control) {
    var value = object.data[control.getAttribute ('data-name')];
    var valueWaitings = [];
    control.setAttribute ('sandbox', 'allow-scripts allow-popups');
    control.setAttribute ('srcdoc', createBodyHTML (value, {edit: true, focusTitle: opts.focusTitle}));
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
  $$c (form, 'button[data-action=execCommand]').forEach (function (b) {
    b.onclick = function () {
      var ed = form.querySelector ('iframe.control[data-name=body]');
      ed.sendExecCommand (this.getAttribute ('data-command'), this.getAttribute ('data-value'));
      ed.focus ();
    };
  });
  $$c (form, 'button[data-action=setBlock]').forEach (function (b) {
    b.onclick = function () {
      var ed = form.querySelector ('iframe.control[data-name=body]');
      ed.setBlock (this.getAttribute ('data-value'));
      ed.focus ();
    };
  });
  $$c (form, 'button[data-action=insertSection]').forEach (function (b) {
    b.onclick = function () {
      var ed = form.querySelector ('iframe.control[data-name=body]');
      ed.insertSection ();
      ed.focus ();
    };
  });
  $$c (form, 'button[data-action=indent], button[data-action=outdent], button[data-action=insertControl], button[data-action=link]').forEach (function (b) {
    b.onclick = function () {
      var ed = form.querySelector ('iframe.control[data-name=body]');
      ed.sendAction (b.getAttribute ('data-action'), b.getAttribute ('data-command'), b.getAttribute ('data-value'));
      ed.focus ();
    };
  });
  $$c (form, 'input[name]').forEach (function (control) {
    var value = object.data[control.name];
    if (control.type === 'date') {
      if (value != null) {
        control.valueAsNumber = value * 1000;
      }
    } else if (control.type === 'radio') {
      control.checked = control.value == value;
    } else if (control.type === 'text') {
      if (value) {
        control.value = value;
      }
    }
  });

  $$c (form, 'list-control[name]').forEach (function (control) {
    upgradeListControl (control);

    var dataKey = control.getAttribute ('key');
    control.setSelectedValues (Object.keys (object.data[dataKey] || {}));
  }); // list-control

  return Promise.all (wait);
} // fillFormControls

var TemplateSelectors = {};
TemplateSelectors.object = function (object, templates) {
  if (object.data.body_type == 3) {
    if (object.data.body_data.new.todo_state == 2) {
      return templates.close;
    } else if (object.data.body_data.new.todo_state == 1 &&
               object.data.body_data.old.todo_state == 2) {
      return templates.reopen;
    } else {
      return templates.changed;
    }
  }
  return null;
}; // object

function upgradeList (el) {
  if (el.upgraded) return;
  el.upgraded = true;

  var as = getActionStatus (el);
  var query;

  el.getListMain = function () {
    var type = this.getAttribute ('type');
    if (type === 'table') {
      return $$c (this, 'table > tbody')[0];
    } else if (type === '$with') {
      return {};
    } else {
      return $$c (this, 'list-main')[0];
    }
  }; // getListMain

  el.clearObjects = function () {
    var main = this.getListMain ();
    if (main) main.textContent = '';
  }; // clearObjects

  el.showObjects = function (objects, opts) {
    var templates = {};
    $$c (this, 'template').forEach (function (e) {
      var name = e.getAttribute ('data-name');
      if (name !== null) {
        templates[name] = e;
      } else {
        templates._ = e;
      }
    });
    var main = el.getListMain ();
    if (!main) return Promise.resolve ({items: []});
    if (main.localName && !templates._) return Promise.resolve ({items: []});
    if (!templates._) templates._ = document.createElement ('template');

    var listObjects = Object.values (objects);

    if (query) {
      listObjects = listObjects.filter (function (o) {
        if (!query.todo_states[o.data.todo_state]) return false;

        if (query.assigned) {
          if (!(o.data.assigned_account_ids || {})[query.assigned]) return;
        }

        var result = true;
        Object.keys (query.index_ids).forEach (function (a) {
          if ( ! ( (o.data.index_ids || {})[a] ) ) result = false;
        });

        return result;
      });
    }

    var prepend = opts.prepend;
    var appended = false;
    var wait = [];

    var itemType = el.getAttribute ('listitemtype');
    var elementType = {
      object: 'article',
    }[itemType] || {
      table: 'tr',
      list: 'li',
      $with: '$with',
    }[el.getAttribute ('type')] || 'list-item';

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
                $$ /* not $$c*/ (item, 'edit-container iframe.control[data-name=body]').forEach (function (e) {
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

    var getTemplate = TemplateSelectors[el.getAttribute ('template-selector')] || function () { return null };
    var result = {main: main, items: []};

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
          var template = getTemplate (object, templates) || templates._;
          item.className = template.className;
          item.appendChild (template.content.cloneNode (true));
          fill (item, object);
          section.appendChild (item);
          result.items.push (item);
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

      if (elementType === '$with') {
        var itemKey = el.getAttribute ('itemkey');
        var list = {};
        var mergeAccounts = el.hasAttribute ('accounts');
        var w = [];
        listObjects.forEach (function (object) {
          var key = object[itemKey];
          list[key] = object;
          if (mergeAccounts) {
            w.push ($with ('account', {accountId: key}).then (function (account) {
              object.account = account || {name: key};
            }));
          }
        });
        wait.push (Promise.all (w).then (function () {
          $with.register (el.id, function () { return list });
        }));
      } else {
        listObjects.forEach (function (object) {
          var item = document.createElement (elementType);
          var template = getTemplate (object, templates) || templates._;
          item.className = template.className;
          item.appendChild (template.content.cloneNode (true));
          fill (item, object);
          if (prepend) {
            main.insertBefore (item, main.firstChild);
          } else {
            main.appendChild (item);
          }
          result.items.push (item);
          appended = true;
        });
      }
    } // not grouped

    $$c (this, 'list-is-empty').forEach (function (e) {
      if (main.firstElementChild) {
        e.hidden = true;
      } else {
        e.hidden = false;
      }
    });

    $$c (this, '.next-page-button').forEach (function (button) {
      button.hidden = ! (opts.hasNext && appended);
    });

    return Promise.all (wait).then (function () { return result });
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
    return el.showObjects (json[key], {
      hasNext: hasNext,
      prepend: el.hasAttribute ('prepend'),
    }).then (function (result) {
      if (hasNext) {
        nextRef = json.next_ref;
      } else {
        nextRef = null;
      }
      return result.main; // or null
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
    var reloads = $$c (this, 'menu:not([hidden])');
    reloads.forEach (function (e) {
      e.hidden = true;
    });
    as.stageEnd ("prep");

    load ().then (function (json) {
      el.clearObjects ();
      return show (json);
    }).then (function (main) {
      as.end ({ok: true});
    }).catch (function (error) {
      as.end ({error: error});
    }).then (function () {
      reloads.forEach (function (e) {
        e.hidden = false;
      });
    });
  }; // load
  el.load ();

  $$c (el, '.next-page-button').forEach (function (button) {
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

  $$c (el, 'article.object.new').forEach (function (article) {
    $$c (article, '.edit-button').forEach (function (button) {
      button.onclick = function () {
        var data = {index_ids: {}, timestamp: (new Date).valueOf () / 1000};
        data.index_ids[el.getAttribute ('src-index_id')] = 1;
        var wikiName = el.getAttribute ('src-wiki_name');
        if (wikiName) data.title = wikiName;
        editObject (article, {data: data}, {open: true, focusTitle: button.hasAttribute ('data-focus-title')});
      };
    });
  });

  $$c (el, '.reload-button').forEach (function (e) {
    e.onclick = function () {
      el.clearObjects ();
      el.load ();
    };
  });

  if (el.hasAttribute ('query')) {
    if (!query) {
      var qp = {todo: [], assigned: [], index: []};
      location.search.replace (/^\?/, '').split (/&/).forEach (function (_) {
        _ = _.split (/=/, 2);
        _[0] = decodeURIComponent (_[0]);
        _[1] = decodeURIComponent (_[1]);
        qp[_[0]] = qp[_[0]] || [];
        qp[_[0]].push (_[1]);
      });
      query = {todo: qp.todo[0] || "open",
               assigned: qp.assigned[0],
               index_ids: {}};
      if (query.todo === 'all') {
        query.todo_states = {1: true, 2: true};
      } else if (query.todo === 'closed') {
        query.todo_states = {2: true};
      } else {
        query.todo_states = {1: true};
      }
      qp.index.forEach (function (i) { query.index_ids[i] = true });
    }
    $$c (el, 'list-query').forEach (function (e) {
      fillFormControls (e, {data: query}, {});
      e.onchange = function (ev) {
        if (ev.target.name === 'todo') {
          query.todo = ev.target.value;
          if (query.todo === 'all') {
            query.todo_states = {1: true, 2: true};
          } else if (query.todo === 'closed') {
            query.todo_states = {2: true};
          } else {
            query.todo_states = {1: true};
          }
        } else {
          var key = ev.target.getAttribute ('key');
          if (key === 'assigned_account_ids') {
            query.assigned = null;
            ev.target.getSelectedValues ().forEach (function (value) {
              query.assigned = value;
            });
          } else {
            query[key] = {};
            ev.target.getSelectedValues ().forEach (function (value) {
              query[key][value] = true;
            });
          }
        }
        el.clearObjects ();
        el.load ();

        var url = location.pathname;
        if (query.todo_states[1]) {
          if (query.todo_states[2]) {
            url += '?todo=all';
          }
        } else {
          if (query.todo_states[2]) {
            url += '?todo=closed';
          }
        }
        if (query.assigned) {
          url += /\?/.test (url) ? '&' : '?';
          url += 'assigned=' + encodeURIComponent (query.assigned);
        }
        Object.keys (query.index_ids).forEach (function (a) {
          url += /\?/.test (url) ? '&' : '?';
          url += 'index=' + encodeURIComponent (a);
        });
        history.replaceState (null, null, url);
      };
    });
  }

  $$c (el, '.search-form').forEach (function (form) {
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
  if (!container) {
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

    $$c (form, 'main .control, header input').forEach (function (control) {
      control.onfocus = function () {
        container.scrollIntoView ();
      };
    });

    wait.push (fillFormControls (form, object, {focusTitle: opts.focusTitle}));

  // XXX autosave

  $$c (form, '.cancel-button').forEach (function (button) {
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
    $$c (container, 'form > header, form > main > menu, form > footer').forEach (function (e) {
      h1 += e.offsetHeight;
    });
    var h = document.documentElement.clientHeight - h1;
    container.querySelector ('main > iframe.control').style.height = h + 'px';
  }; // resize
  addEventListener ('resize', resize);
  wait.push (Promise.resolve ().then (resize));

  } // !container

  if (opts.open) {
    container.hidden = false;
    article.classList.add ('editing');
    if (opts.focusTitle) {
      var title = container.querySelector ('input[name=title]');
      if (title) title.focus ();
    } else {
      var body = container.querySelector ('.control[data-name=body]');
      if (body) body.focus ();
    }
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
    control.getSelectedValues ().forEach (function (value) {
      fd.append (name, value);
      cc[value] = 1;
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

function initUploader (form) {
  var uploadFile = function (file) {
    var list = form.querySelector ('list-container');
    var data = {
      file_name: file.name,
      file_size: file.size,
      mime_type: file.type,
    };
    var as;
    return list.showObjects ([{data: data}], {}).then (function (r) {
      var item = r.items[0];
      as = getActionStatus (item);
      as.start ({stages: ["create", "upload", "close", "show"]});
      as.stageStart ("create");
      var fd1 = new FormData;
      fd1.append ('is_file', 1);
      return gFetch ('o/create.json', {post: true, formData: fd1});
    }).then (function (json) {
      data.object_id = json.object_id;
      as.stageEnd ("create");
      return gFetch ('o/' + data.object_id + '/upload.json?token=' + encodeURIComponent (json.upload_token), {post: true, body: file, as: as, asStage: "upload"});
    }).then (function () {
      var fd2 = new FormData;
      fd2.append ('edit_index_id', 1);
      fd2.append ('index_id', form.getAttribute ('data-index-id'));
      fd2.append ('file_name', data.file_name);
      fd2.append ('file_size', data.file_size);
      fd2.append ('mime_type', data.mime_type);
      fd2.append ('file_closed', 1);
      as.stageStart ("close");
      return gFetch ('o/' + data.object_id + '/edit.json', {post: true, formData: fd2});
    }).then (function () {
      as.stageEnd ("close");
      as.stageStart ("show");
      return gFetch ('o/get.json?with_data=1&object_id=' + data.object_id, {});
    }).then (function (json) {
      return document.querySelector ('list-container[src-index_id]')
          .showObjects (json.objects, {prepend: true});
    }).then (function () {
      as.end ({ok: true});
    }, function (error) {
      as.end ({ok: false, error: error});
    });
  }; // uploadFile

  form.elements["upload-button"].onclick = function () {
    form.elements.file.click ();
  };
  form.elements.file.onchange = function () {
    Array.prototype.forEach.call (form.elements.file.files, function (file) {
      uploadFile (file);
    });
    form.reset ();
  };
  var setDropEffect = function (dt) {
    var hasFile = false;
    var items = dt.items;
    for (var i = 0; i < items.length; i++) {
      if (items[i].kind === "file") {
        hasFile = true;
        break;
      }
    }
    if (hasFile) {
      dt.dropEffect = "copy";
      return false;
    } else {
      dt.dropEffect = "none";
      return true;
    }
  }; // setDropEffect
  var targetted = 0;
  form.ondragenter = function (ev) {
    targetted++;
    if (!setDropEffect (ev.dataTransfer)) {
      form.classList.add ('drop-target');
      return false;
    }
  };
  form.ondragover = function (ev) {
    return setDropEffect (ev.dataTransfer);
  };
  form.ondragleave = function (ev) {
    targetted--;
    if (targetted <= 0) {
      form.classList.remove ('drop-target');
    }
  };
  form.ondrop = function (ev) {
    form.classList.remove ('drop-target');
    targetted = 0;
    Array.prototype.forEach.call (ev.dataTransfer.files, function (file) {
      uploadFile (file);
    });
    return false;
  };
} // initUploader

function applyFilters (objects, filtersText) {
  if (filtersText) {
    var filters = JSON.parse (filtersText);
    objects = objects.filter (function (object) {
      for (var i = 0; i < filters.length; i++) {
        var filter = filters[i];
        if (filter.key) {
          var v = object;
          for (var k = 0; k < filter.key.length; k++) {
                v = v[filter.key[k]];
                if (!v) {
                  v = null;
                  break;
                }
              }
              if (filter.valueIn) {
                if (!filter.valueIn[v]) return false;
              } else {
                if (filter.value != v) return false;
              }
            }
          }
          return true;
        });
      }
  return objects;
} // applyFilters

function getActionStatus (container) {
  var as = new ActionStatus;
  as.elements = $$c2 (container, 'action-status');
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
      self.stages[s] = 0;
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

ActionStatus.prototype.stageProgress = function (stage, value, max) {
  if (Number.isFinite (value) && Number.isFinite (max)) {
    this.stages[stage] = value / (max || 1);
  } else {
    this.stages[stage] = 0;
  }
}; // stageProgress

ActionStatus.prototype.stageEnd = function (stage) {
  var self = this;
  this.stages[stage] = 1;
  this.elements.forEach (function (e) {
    $$ (e, 'progress').forEach (function (f) {
      var stages = Object.keys (self.stages);
      f.max = stages.length;
      var v = 0;
      stages.forEach (function (s) {
        v += self.stages[s];
      });
      f.value = v;
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

stageActions.resetForm = function (args) {
  args.form.reset ();
}; // resetForm
stageActions.resetForm.stages = [];

stageActions.editObject = function (args) {
  var fd = new FormData;
  var length = 0;
  var subform = args.submitButton.getAttribute ('data-subform');
  var dataUpdated = [];
  $$ (args.form, 'input[data-edit-object]:not([hidden]), textarea[data-edit-object]:not([hidden])').forEach (function (f) {
    if (f.getAttribute ('data-subform') != subform) return;
    fd.append (f.getAttribute ('data-name'), f.value);
    if (f.classList.contains ('data-field')) {
      dataUpdated.push ([f.getAttribute ('data-name'), f.value]);
    }
    length++;
  });
  if (length <= 1) return;
  args.as.stageStart ('editobject_fetch');
  return gFetch ('o/' + fd.get ('object_id') + '/edit.json', {post: true, formData: fd}).then (function (json) {
    args.as.stageEnd ('editobject_fetch');
    if (args.form.parentObject && dataUpdated.length) {
      dataUpdated.forEach (function (_) {
        args.form.parentObject.data[_[0]] = _[1];
      });
      args.form.dispatchEvent (new Event ('objectdataupdate', {bubbles: true}));
    }
  });
}; // editObject
stageActions.editObject.stages = ['editobject_fetch'];

stageActions.editCreatedObject = function (args) {
  args.as.stageStart ('editcreatedobject_fetch');
  var fd = new FormData;
  $$ (args.form, 'input[data-edit-created-object]:not([hidden]), textarea[data-edit-created-object]:not([hidden])').forEach (function (f) {
    fd.append (f.getAttribute ('data-name'), f.value);
  });
  return gFetch ('o/' + args.result.object_id + '/edit.json', {post: true, formData: fd}).then (function (json) {
    args.as.stageEnd ('editcreatedobject_fetch');
  });
}; // editCreatedObject
stageActions.editCreatedObject.stages = ['editcreatedobject_fetch'];

stageActions.showCreatedObjectInCommentList = function (args) {
  args.as.stageStart ('showcreatedobjectincommentlist');
  return gFetch ('o/get.json?with_data=1&object_id=' + args.result.object_id, {}).then (function (json) {
    var p = args.form;
    while (p.parentNode) {
      p = p.parentNode;
      if (p.localName === 'article-comments') break;
    }
    return $$ (p, 'list-container.comment-list')[0].showObjects (json.objects, {});
  }).then (function () {
    args.as.stageEnd ('showcreatedobjectincommentlist');
  });
}; // showCreatedObjectInCommentList
stageActions.showCreatedObjectInCommentList.stages = ['showcreatedobjectincommentlist'];

function upgradeForm (form) {
  var formType = form.getAttribute ('data-form-type');
  if (formType === 'uploader') {
    return initUploader (form);
  } else if (form.getAttribute ('action') === 'javascript' &&
             form.hasAttribute ('data-action')) {
    //
  } else {
    return;
  }

  var submitButton = null;
  $$ (form, '[type=submit]').forEach (function (e) {
    e.onclick = function () { submitButton = this };
  });
  form.onsubmit = function () {
    var submit = submitButton;
    submitButton = null;

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
    withFormDisabled (form, function () {
      as.stageEnd ("prep");
      as.stageStart ("fetch");
      return gFetch (form.getAttribute ('data-action'), {post: true, formData: fd}).then (function (json) {
        as.stageEnd ("fetch");
        var p = Promise.resolve ();
        addStages.forEach (function (stage) {
          p = p.then (function () {
            return stageActions[stage] ({result: json, fd: fd, as: as, form: form, submitButton: submit});
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
              $$ (form, '[name].data-field').forEach (function (e) {
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

function upgradeListControl (control) {
  control._selectedValues = [];

  control.setSelectedValues = function (values) {
    this._selectedValues = values;
    this._updateView ();
  }; // setSelectedValues

  control.getSelectedValues = function () {
    return this._selectedValues;
  }; // getSelectedValues

  control.getAvailObjects = function () {
    return this._availObjects;
  }; // getAvailObjects

  control._updateView = function () {
    var avail = this._availObjects;
    if (!avail) return;

    var templates = {};
    $$c (control, 'template').forEach (function (e) {
      templates[e.getAttribute ('data-name')] = e;
    });

    $$c (control, 'list-control-list').forEach (function (list) {
      var objects;
      if (list.hasAttribute ('editable')) {
        var hasValue = {};
        objects = control._selectedValues.map (function (value) {
          hasValue[value] = true;
          return {data: avail[value] || {}, selected: true};
        }).concat (Object.keys (avail).filter (function (value) {
          return ! hasValue[value];
        }).map (function (value) {
          return {data: avail[value]};
        }));

        list.onchange = function (ev) {
          if (ev.target.localName === 'input') {
            if (ev.target.checked) {
              var found = {};
              if (ev.target.type === 'radio') {
                $$ (list, 'input[type=radio]:not(:checked)').forEach (function (i) {
                  if (i.name === ev.target.name) {
                    found[i.value] = true;
                  }
                });
              }
              if (ev.target.value) control._selectedValues.push (ev.target.value);
              control._selectedValues = control._selectedValues.filter (function (x) {
                found[x] = found[x] || 0;
                return ! found[x]++;
              });
            } else {
              control._selectedValues = control._selectedValues.filter (function (v) { return v !== ev.target.value });
            }
            control._updateView ();
            control.dispatchEvent (new Event ('change', {bubbles: true}));
          }
          ev.stopPropagation ();
        }; // onchange
      } else {
        objects = control._selectedValues.map (function (value) {
          return {data: avail[value] || {}};
        });
      }
      objects = applyFilters (objects, list.getAttribute ('filters'));

      if (objects.length) {
        list.textContent = '';
      } else {
        list.textContent = list.getAttribute ('data-empty') || '';
      }

      var cTemplate = templates[list.getAttribute ('clear-template') || ''];
      if (cTemplate) {
        var item = document.createElement ('list-item');
        item.appendChild (cTemplate.content.cloneNode (true));
        list.appendChild (item);
      }
      var template = templates[list.getAttribute ('template')];
      objects.forEach (function (object) {
        var item = document.createElement ('list-item');
        item.appendChild (template.content.cloneNode (true));
        fillFields (list, item, item, object);
        list.appendChild (item);
      });
    });
  }; // _updateView

  $with (control.getAttribute ('list')).then (function (list) {
    control._availObjects = list;
    control._updateView ();
  });
} // upgradeListControl

function upgradePopupMenu (e) {
  var listeners = [];
  var toggle = function () {
    e.classList.toggle ('active');
    var isActive = e.classList.contains ('active');
    $$c (e, 'menu').forEach (function (m) {
      m.hidden = !isActive;
    });
    if (isActive) {
      var f = function (ev) {
        if (ev.targetPopupMenu === e) return;
        toggle ();
      };
      window.addEventListener ('click', f);
      listeners.push (f);
    } else {
      listeners.forEach (function (f) {
        window.removeEventListener ('click', f);
      });
      listeners = [];
    }
  }; // toggle
  Array.prototype.forEach.call (e.children, function (f) {
    if (f.localName === 'button') {
      f.onclick = function (ev) { ev.targetIsInteractive = true; toggle () };
    }
  });
  $$ (e, 'menu button, menu a, menu input').forEach (function (b) {
    b.addEventListener ('click', function (ev) { toggle () });
  });
  e.onclick = function (ev) {
    if (ev.targetIsInteractive) {
      ev.targetPopupMenu = e;
    } else {
      ev.stopPropagation ();
    }
  };
} // upgradePopupMenu

function upgradeCopyButton (e) {
  $$ (e, 'a').forEach (function (f) {
    f.onclick = function () {
      if (e.getAttribute ('type') === 'jump') {
        var fd = new FormData;
        if (f.title) fd.append ('label', f.title);
        fd.append ('url', f.href);
        gFetch ('/jump/add.json', {post: true, formData: fd}).then (function () {
          $$ (document, 'list-container[src="/jump/list.json"]').forEach (function (e) {
            e.clearObjects ();
            e.load ();
          });
        });
      } else {
        copyText (f.href);
      }
      return false;
    };
  });
} // upgradeCopyButton

function copyText (s) {
  var e = document.createElement ('temp-text');
  e.textContent = s;
  document.body.appendChild (e);
  var range = document.createRange ();
  range.selectNode (e);
  getSelection ().empty ();
  getSelection ().addRange (range);
  document.execCommand ('copy')
  e.parentNode.removeChild (e);
} // copyText

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
        upgradeForm (x);
      } else if (x.localName) {
        $$ (x, 'form').forEach (upgradeForm);
      }
      if (x.localName === 'popup-menu') {
        upgradePopupMenu (x);
      } else if (x.localName) {
        $$ (x, 'popup-menu').forEach (upgradePopupMenu);
      }
      if (x.localName === 'copy-button') {
        upgradeCopyButton (x);
      } else if (x.localName) {
        $$ (x, 'copy-button').forEach (upgradeCopyButton);
      }
    });
  });
})).observe (document.documentElement, {childList: true, subtree: true});
$$ (document, 'list-container').forEach (upgradeList);
$$ (document, 'form').forEach (upgradeForm);
$$ (document, 'account-name[account_id]').forEach (upgradeAccountName);
$$ (document, 'popup-menu').forEach (upgradePopupMenu);
$$ (document, 'copy-button').forEach (upgradeCopyButton);

/*

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

*/
