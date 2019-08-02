var defineElement = function (def) {
  var e = document.createElementNS ('data:,pc', 'element');
  e.pcDef = def;
  document.head.appendChild (e);

  if (def.fill) {
    var e = document.createElementNS ('data:,pc', 'filltype');
    e.setAttribute ('name', def.name);
    e.setAttribute ('content', def.fill);
    document.head.appendChild (e);
    delete def.fill;
  }
}; // defineElement

window.GR = {};

// XXX
$with.register ('GR', () => window.GR);

GR.theme = {};

GR.theme.list = function () {
  return fetch ('/theme/list.json').then (res => {
    if (res.status !== 200) throw res;
    return res.json ();
  });
}; // GR.theme.list

GR.theme.getDefault = function () {
  return this.list ().then (json => {
    var list = json.default_names;
    return list[Math.floor (Math.random () * list.length)];
  });
}; // GR.theme.getDefault

GR.theme.set = function (theme) {
  document.documentElement.setAttribute ('data-theme', theme);
  return Promise.resolve ().then (() => {
    var meta = document.querySelector ('meta[name=theme-color]');
    meta.content = getComputedStyle (document.documentElement).getPropertyValue ("--dark-background-color");
  });
}; // GR.theme.set

defineElement ({
  name: 'gr-select-theme',
  fill: 'contentattribute',
  props: {
    pcInit: function () {
      this.setAttribute ('formcontrol', '');

      this.ready = GR.theme.list ().then (info => {
        this.querySelectorAll ('select').forEach (select => {
          select.textContent = '';
          info.names.forEach (theme => {
            var def = info.themes[theme];
            var option = document.createElement ('option');
            option.value = theme;
            option.label = def.label;
            def.name = theme;
            select.appendChild (option);
          });

          select.onchange = () => {
            var theme = select.value;
            GR.theme.set (theme);
            this.value = theme;
            $fill (this.querySelector ('gr-theme-info'), info.themes[theme] || {});
          };
        });

        var setValue = () => {
          var theme = this.getAttribute ('value');
          this.querySelectorAll ('select').forEach (_ => _.value = theme);
          this.value = theme;
          $fill (this.querySelector ('gr-theme-info'), info.themes[theme] || {});
        };
        var mo = new MutationObserver (setValue);
        mo.observe (this, {attributes: true, attributeFilter: ['value']});
        setValue ();
      });
    }, // pcInit
    pcModifyFormData: function (fd) {
      var name = this.getAttribute ('name');
      if (!name) return;
      return this.ready.then (() => fd.append (name, this.value));
    }, // pcModifyFormData
  },
}); // <gr-select-theme>

defineElement ({
  name: 'gr-input-hidden-random-theme',
  props: {
    pcInit: function () {
      this.setAttribute ('formcontrol', '');
    }, // pcInit
    pcModifyFormData: function (fd) {
      var name = this.getAttribute ('name');
      if (!name) return;
      return GR.theme.getDefault ().then (theme => {
        fd.append (name, theme);
      });
    }, // pcModifyFormData
  },
});

GR._state = {};

GR._updateMyInfo = function () {
  return GR._state.updateMyInfo = gFetch ('myinfo.json', {}).then (json => {
    var oldAccount = GR._state.account || {};
    GR._state.account = json.account;
    GR._state.group = json.group;
    GR._state.group.member = json.group_member;

    if (oldAccount.account_id !== json.account) {
      // XXX
    }
  });
  // XXX if 403
}; // GR._updateMyInfo
// XXX auto _updateMyInfo

GR._myinfo = function () {
  return GR._state.updateMyInfo || GR._updateMyInfo ();
}; // GR._myinfo

GR.page = {};

GR.page.setTitle = function (title) {
  GR._state.title = title;
  GR.page._title ();
}; // GR.page.setTitle

GR.page.setSearch = function (args) {
  if (!args) {
    GR._state.isSearchPage = false;
    GR._state.searchWord = null;
  } else {
    if (GR._state.searchWord === args.q) return;
    GR._state.isSearchPage = true;
    GR._state.searchWord = args.q;
  }
  GR.page._title ();
}; // GR.page._setSearch

GR.page._title = function () {
  if (GR._state.searchWord) {
    document.title = GR._state.searchWord + ' - ' + GR._state.title;
  } else {
    document.title = GR._state.title;
  }
}; // GR.page._title

GR.account = {};

GR.account.info = function () {
  return GR._myinfo ().then (_ => {
    return GR._state.account;
  });
}; // GR.account.info

GR.group = {};

GR.group.info = function () {
  return GR._myinfo ().then (_ => {
    return GR._state.group;
  });
}; // GR.group.info

GR.index = {};

GR.index.info = function (indexId) {
  // XXX cache
  return gFetch ('i/'+indexId+'/info.json', {});
}; // GR.group.info

defineElement ({
  name: 'gr-account',
  fill: 'contentattribute',
  props: {
    pcInit: function () {
      if (this.hasAttribute ('self')) {
        return GR.account.info ().then (account => {
          $fill (this, account);
        });
      } else if (this.hasAttribute ('value')) {
        return $with ('account', {accountId: this.getAttribute ('value')}).then ((account) => {
          $fill (this, account);
        });
      }
    }, // pcInit
  },
}); // <gr-account>

defineElement ({
  name: 'gr-group',
  props: {
    pcInit: function () {
      return GR.group.info ().then (group => {
        $fill (this, group);
        this.querySelectorAll ('.if-has-default-index').forEach (_ => {
          _.hidden = ! group.member.default_index_id;
        });
      });
    }, // pcInit
  },
}); // <gr-group>

defineElement ({
  name: 'gr-menu',
  props: {
    pcInit: function () {
      new MutationObserver (() => this.grUpdate ()).observe
          (this, {attributes: true, attributeFilter: ['type', 'indexid', 'wikiname']});
      Promise.resolve ().then (() => this.grUpdate ());
    }, // pcInit
    grUpdate: function () {
      if (this.grUpdateRunning) return;
      this.grUpdateRunning = true;
      var obj = {};
      return $getTemplateSet ('gr-menu').then (ts => {
        var type = this.getAttribute ('type');
        if (type === 'group') {
          return Promise.all ([
            ts,
            $getTemplateSet ('gr-menu-group'),
            GR.group.info ().then (_ => obj.group = _),
          ]);
        } else if (type === 'index') {
          var indexId = this.getAttribute ('indexid');
          return Promise.all ([
            ts,
            $getTemplateSet ('gr-menu-index'),
            GR.group.info ().then (_ => obj.group = _),
            GR.index.info (indexId).then (_ => obj.index = _),
          ]);
        } else if (type === 'wiki') {
          var indexId = this.getAttribute ('indexid');
          var wikiName = this.getAttribute ('wikiname');
          obj.wiki = {name: wikiName};
          return Promise.all ([
            ts,
            $getTemplateSet ('gr-menu-wiki'),
            GR.group.info ().then (_ => obj.group = _),
            GR.index.info (indexId).then (_ => obj.index = _),
          ]);
        } else {
          throw new Error ("Unknown <gr-menu type> value |"+type+"|");
        }
      }).then (([ts1, ts2]) => {
        this.textContent = '';
        ts1.pcCreateTemplateList ();
        ts2.pcCreateTemplateList ();
        var e = ts1.createFromTemplate ('div', {});
        e.querySelectorAll ('menu-main').forEach (_ => {
          var f = ts2.createFromTemplate ('div', obj);
          while (f.firstChild) _.appendChild (f.firstChild);
        });
        if (obj.index) {
          e.querySelectorAll ('[data-gr-if-index-type]:not([data-gr-if-index-type~="'+obj.index.index_type+'"])').forEach (_ => {
            _.remove ();
          });
        }
        while (e.firstChild) this.appendChild (e.firstChild);
      }).finally (_ => this.grUpdateRunning = false);
    }, // grUpdate
  },
}); // <gr-menu>

function $$c (n, s) {
  return Array.prototype.filter.call (n.querySelectorAll (s), function (e) {
    var f = e.parentNode;
    while (f) {
      if (f === n) break;
      if (f.localName === 'gr-list-container' ||
          f.localName === 'edit-container' ||
          f.localName === 'list-query' ||
          f.localName === 'list-control' ||
          f.localName === 'object-ref' ||
          f.localName === 'body-control') {
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
      if (f.localName === 'gr-list-container' ||
          f.localName === 'edit-container' ||
          f.localName === 'list-query' ||
          f.localName === 'list-control' ||
          f.localName === 'object-ref' ||
          f.localName === 'body-control' ||
          f.localName === 'form') {
        return false;
      }
      f = f.parentNode;
    }
    return true;
  });
} // $$c2

function $$ancestor (e, name) {
  while (e) {
    e = e.parentNode;
    if (e.localName === name) {
      return e;
    }
  }
  return null;
} // $$ancestor

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
    disabledControls = $$ (form, 'input:enabled, select:enabled, textarea:enabled, button:enabled, body-control:not([disabled])');
    disabledControls.forEach (function (control) {
      control.disabled = true;
    });
  }
  return Promise.resolve ().then (code).then (function (result) {
    disabledControls.forEach (function (control) {
      control.disabled = false;
    });
    return result;
  }, function (error) {
    disabledControls.forEach (function (control) {
      control.disabled = false;
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
  $$ (document.head, 'link.body-js, script.body-js').forEach (function (e) {
    var script = document.createElement ('script');
    script.async = e.async;
    script.src = e.href || e.src;
    doc.head.appendChild (script);
  });

  if (opts.edit) {
    $$ (document, 'template.body-edit-template').forEach (function (e) {
      doc.head.appendChild (e.cloneNode (true));
    });
  }
  $$ (document, 'template.body-template').forEach (function (e) {
    doc.head.appendChild (e.cloneNode (true));
  });

  doc.documentElement.setAttribute ('data-theme', document.documentElement.getAttribute ('data-theme'));

  if (opts.edit) {
    doc.body.setAttribute ('contenteditable', '');
    if (opts.focusBody) {
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

FieldCommands.setListIndex = function () {
  var object = {index_id: this.getAttribute ('value')};
  var panel = $$ancestor (this, 'section');
  $$c (panel, 'panel-main').forEach (function (s) {
    fillFields (s, s, s, object, {});
    $$c (s, 'gr-list-container[data-src-template]').forEach (function (list) {
      list.removeAttribute ('disabled');
      list.clearObjects ();
      list.load ();
    });
    $$c (s, 'form[data-form-type=uploader] gr-list-container').forEach (function (list) {
      list.clearObjects ();
    });
    s.hidden = false;
  });
  $$c (panel.querySelector ('gr-list-container[key=index_list]'), 'button[data-command=setListIndex]').forEach (function (b) {
    b.classList.toggle ('active', b.value === object.index_id);
  });
}; // setListIndex

function fillFields (contextEl, rootEl, el, object, opts) {
  $$c (el, '[data-field]').forEach (function (field) {
    var name = field.getAttribute ('data-field').split (/\./);
    var value = object;
    for (var i = 0; i < name.length; i++) {
      value = value[name[i]];
      if (value == null) break;
    }

    if (field.localName === 'input' ||
        field.localName === 'select') {
      field.value = value;
    } else if (field.localName === 'time') {
      try {
        var dt = new Date (parseFloat (value) * 1000);
        field.setAttribute ('datetime', dt.toISOString ());
      } catch (e) {
        field.removeAttribute ('datetime');
        field.textContent = e;
      }
    } else if (field.localName === 'gr-enum-value') {
      field.setAttribute ('value', value);
      if (value == null) {
        field.hidden = true;
      } else {
        field.hidden = false;
        var v = field.getAttribute ('text-' + value);
        if (v) {
          field.textContent = v;
        } else {
          field.textContent = value;
        }
        if (field.parentNode.localName === 'td') {
          field.parentNode.setAttribute ('data-value', value);
        }
      }
    } else if (field.localName === 'account-name') {
      field.setAttribute ('account_id', value);
      field.textContent = value;
    } else if (field.localName === 'object-ref') {
      field.setAttribute ('value', value);
      field.hidden = false;
      upgradeObjectRef (field);

    } else if (field.localName === 'only-if') {
      var matched = true;
      var cond = field.getAttribute ('cond');
      if (cond === '==0') {
        if (value != 0) matched = false;
      } else if (cond === '!=0') {
        if (value == 0) matched = false;
      }
      field.hidden = ! matched;

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
      var name = k.split (/\./);
      var value = object;
      for (var i = 0; i < name.length; i++) {
        value = value[name[i]];
        if (value == null) break;
      }
      return encodeURIComponent (value);
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
    }).replace (/\{(?:(data)\.|)([^{}.:]+)(?:|:([0-9]+))\}/g, function (_, p, k, n) {
      if (p) {
        if (n) {
          return encodeURIComponent ((object[p][k] || "").substring (0, parseFloat (n)));
        } else {
          return encodeURIComponent (object[p][k]);
        }
      } else {
        if (n) {
          return encodeURIComponent ((object[k] || "").substring (0, parseFloat (n)));
        } else {
          return encodeURIComponent (object[k]);
        }
      }
    }));
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
  $$c (el, '[data-data-action-template]').forEach (function (field) {
    field.setAttribute ('data-action', field.getAttribute ('data-data-action-template').replace (/\{([^{}]+)\}/g, function (_, k) {
      return encodeURIComponent (object[k]);
    }));
  });
  $$c (el, '[data-value-template]').forEach (function (field) {
    field.setAttribute ('value', field.getAttribute ('data-value-template').replace (/\{GROUP\}/g, function () {
      return document.documentElement.getAttribute ('data-group-url');
    }).replace (/\{([^{}]+)\}/g, function (_, k) {
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
          fillFields (item, item, item, object, {});
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
        fillFields (item, item, item, {account_id: accountId}, {});
        field.appendChild (item);
      });
    } else if (field.localName === 'iframe') {
      field.setAttribute ('sandbox', 'allow-scripts allow-top-navigation');
      field.setAttribute ('srcdoc', createBodyHTML ('', {}));
      var mc = new MessageChannel;
      field.onload = function () {
        this.contentWindow.postMessage ({type: "getHeight"}, '*', [mc.port1]);
        mc.port2.onmessage = function (ev) {
          if (ev.data.type === 'height') {
            field.style.height = ev.data.value + 'px';
          } else if (ev.data.type === 'changed') {
            var v = new Event ('editablecontrolchange', {bubbles: true});
            v.data = ev.data;
            field.dispatchEvent (v);
          } else if (ev.data.type === 'getObjectWithSearchData') {
            getObjectWithSearchData (ev.data.value).then (function (object) {
              ev.ports[0].postMessage (object);
            });
          } else if (ev.data.type === 'linkSelected') {
            if (ev.data.url) {
              showURLTooltip (ev.data.url, {
                top: field.offsetTop + ev.data.top + ev.data.height,
                left: field.offsetLeft + ev.data.left,
              });
            } else {
              showTooltip (null, {});
            }
          }
        };
        field.onload = null;
      };
      mc.port2.postMessage ({type: "setCurrentValue",
                             valueSourceType: (object.data ? object.data.body_source_type : null),
                             importedSites: opts.importedSites,
                             value: value});
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
      field.setAttribute ('value', value);
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
    e.onclick = FieldCommands[e.getAttribute ('data-command')];
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

  form.getBodyControl = function () {
    return $$c (this, 'body-control')[0]; // or null
  }; // getBodyControl
  $$c (form, 'body-control').forEach (function (e) {
    upgradeBodyControl (e, object, {
      focusBody: !opts.focusTitle,
      form: form,
      importedSites: opts.importedSites,
    });
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

function upgradeBodyControl (e, object, opts) {
  var data = {
    body: object.data.body,
    body_type: object.data.body_type,
    body_source: object.data.body_source,
    body_source_type: object.data.body_source_type || 0,
    hasSource: object.data.body_source != null,
  };
  if (data.body_type == 2) { // compat
    data.body_type = 1;
    var div = document.createElement ('div');
    div.textContent = data.body;
    data.body = div.innerHTML;
  }

  var currentMode = null;
  var loader = {};
  var saver = {};
  var changeMode = function (newMode, as) {
    if (currentMode === newMode) return Promise.resolve ();
    var oldDisabled = e.disabled;
    if (!oldDisabled) e.disabled = true;
    return Promise.resolve ().then (function () {
      as.stageStart ("saver");
      if (currentMode) return saver[currentMode] ();
    }).then (function () {
      as.stageEnd ("saver");
      as.stageStart ("loader");
      if (newMode) return loader[newMode] ();
    }).then (function () {
      as.stageEnd ("loader");
      if (newMode) currentMode = newMode;
      if (!oldDisabled) e.disabled = false;
    });
  }; // changeMode

  var showTab = function (name) {
    $$c (e, '.tab-buttons a').forEach (function (b) {
      b.classList.toggle ('active', b.getAttribute ('data-name') === name);
    });
    $$c (e, 'body-control-tab').forEach (function (f) {
      f.hidden = f.getAttribute ('name') !== name;
    });
    var as = getActionStatus (opts.form);
    as.start ({stages: ["saver", "loader"]});
    changeMode (name, as).then (function () {
      as.end ({ok: true});
    }, function (error) {
      as.end ({error: error});
    });
  }; // showTab
  $$c (e, '.tab-buttons a').forEach (function (b) {
    b.onclick = function () {
      if (!e.disabled) showTab (this.getAttribute ('data-name'));
    };
  });

  var changeSourceType = function (newType, opts) {
    if (data.body_source_type == newType && ! opts.force) return;
    data.body_source_type = newType;
    if (data.body_source_type == 0) { // WYSIWYG
      $$c (e, '.tab-buttons a').forEach (function (b) {
        var name = b.getAttribute ('data-name');
        b.hidden = (name !== 'textarea' && name !== 'iframe' && name !== 'config');
      });
      if (opts.show) showTab ('iframe');
    } else if (data.body_source_type == 3) { // hatena
      $$c (e, '.tab-buttons a').forEach (function (b) {
        var name = b.getAttribute ('data-name');
        b.hidden = (name !== 'textarea' && name !== 'preview' && name !== 'config');
      });
      if (opts.show) showTab ('textarea');
    } else {
      $$c (e, '.tab-buttons a').forEach (function (b) {
        var name = b.getAttribute ('data-name');
        b.hidden = (name !== 'textarea' && name !== 'config');
      });
      if (opts.show) showTab ('textarea');
    }
  }; // changeSourceType

  Object.defineProperty (e, 'disabled', {
    get: function () {
      return this.hasAttribute ('disabled');
    },
    set: function (v) {
      var current = this.hasAttribute ('disabled');
      if (v) {
        if (!current) {
          this.setAttribute ('disabled', '');
          $$c (this, 'textarea, button').forEach (function (b) {
            b.disabled = true;
          });
        }
      } else {
        if (current) {
          this.removeAttribute ('disabled');
          $$c (this, 'textarea, button').forEach (function (b) {
            b.disabled = false;
          });
        }
      }
    },
  });

  e.setHeight = function (h) {
    $$c (e, 'body-control-tab').forEach (function (f) {
      var h2 = h;
      $$c (f, 'menu').forEach (function (g) {
        h2 -= g.offsetHeight;
      });
      $$c (f, 'iframe, textarea').forEach (function (g) {
        g.style.height = h2 + 'px';
      });
    });
  };

  var iframe = e.querySelector ('body-control-tab[name=iframe] iframe');
  iframe.setAttribute ('sandbox', 'allow-scripts allow-popups');
  iframe.setAttribute ('srcdoc', createBodyHTML ('', {edit: true, focusBody: opts.focusBody}));
  var valueWaitings = [];
  var mc = new MessageChannel;
  iframe.onload = function () {
    this.contentWindow.postMessage ({type: "getHeight"}, '*', [mc.port1]);
    mc.port2.onmessage = function (ev) {
      if (ev.data.type === 'focus') {
        iframe.dispatchEvent (new Event ("focus", {bubbles: true}));
      } else if (ev.data.type === 'currentValue') {
        valueWaitings.forEach (function (f) {
          f (ev.data.value);
        });
        valueWaitings = [];
      } else if (ev.data.type === 'currentState') {
        $$ (e, 'button[data-action=execCommand]').forEach (function (b) {
          var value = ev.data.value[b.getAttribute ('data-command')];
          if (value === undefined) return;
          b.classList.toggle ('active', value);
        });
      } else if (ev.data.type === 'prompt') {
        var args = ev.data.value;
        var result = prompt (args.prompt, args.default);
        ev.ports[0].postMessage ({result: result});
      } else if (ev.data.type === 'getObjectWithSearchData') {
        getObjectWithSearchData (ev.data.value).then (function (object) {
          ev.ports[0].postMessage (object);
        });
      }
    }; // onmessage
    e.onload = null;
  }; // onload
    e.sendCommand = function (data) {
      mc.port2.postMessage (data);
    };
    e.sendExecCommand = function (name, value) {
      mc.port2.postMessage ({type: "execCommand", command: name, value: value});
    };
    e.setBlock = function (value) {
      mc.port2.postMessage ({type: "setBlock", value: value});
    };
    e.insertSection = function () {
      mc.port2.postMessage ({type: "insertSection"});
    };
    e.sendAction = function (type, command, value) {
      mc.port2.postMessage ({type: type, command: command, value: value});
    };
    e.sendChange = function (data) {
      mc.port2.postMessage ({type: "change", value: data});
    };
    e.focus = function () {
      iframe.focus ();
      var ev = new UIEvent ('focus', {});
      e.dispatchEvent (ev);
    };
  saver.iframe = function () {
    mc.port2.postMessage ({type: "getCurrentValue"});
    return new Promise (function (ok) { valueWaitings.push (ok) }).then (function (_) {
      data.body = _;
    });
  }; // saver.iframe
  loader.iframe = function () {
    mc.port2.postMessage ({
      type: "setCurrentValue",
      value: data.body,
      valueSourceType: data.body_source_type,
      importedSites: opts.importedSites,
    });
  }; // loader.iframe

  $$c (e, 'button[data-action=execCommand]').forEach (function (b) {
    b.onclick = function () {
      e.sendExecCommand (this.getAttribute ('data-command'), this.getAttribute ('data-value'));
      e.focus ();
    };
  });
  $$c (e, 'button[data-action=setBlock]').forEach (function (b) {
    b.onclick = function () {
      e.setBlock (this.getAttribute ('data-value'));
      e.focus ();
    };
  });
  $$c (e, 'button[data-action=insertSection]').forEach (function (b) {
    b.onclick = function () {
      e.insertSection ();
      e.focus ();
    };
  });
  $$c (e, 'button[data-action=indent], button[data-action=outdent], button[data-action=insertControl], button[data-action=link]').forEach (function (b) {
    b.onclick = function () {
      e.sendAction (b.getAttribute ('data-action'), b.getAttribute ('data-command'), b.getAttribute ('data-value'));
      e.focus ();
    };
  });
  $$c (e, 'button[data-action=panel]').forEach (function (b) {
    b.onclick = function () {
      var ev = new Event ('gruwatogglepanel', {bubbles: true});
      ev.panelName = this.getAttribute ('data-value');
      e.dispatchEvent (ev);
    };
  });

  var textarea = e.querySelector ('body-control-tab[name=textarea] textarea');
  loader.textarea = function () {
    if (data.body_source_type == 0) { // WYSIWYG
      textarea.value = data.body;
    } else {
      textarea.value = data.body_source != null ? data.body_source : data.body;
    }
  }; // loader.textarea
  saver.textarea = function () {
    if (data.body_source_type == 0) { // WYSIWYG
      data.body = textarea.value;
    } else {
      if (data.body_source !== textarea.value) {
        data.body_source = textarea.value;
        if (data.body_source_type == 3) { // hatena
          return Formatter.hatena (data.body_source).then (function (body) {
            data.body = '<hatena-html>' + body + '</hatena-html>';
          });
        } else {
          data.body = data.body_source;
        }
      }
    }
  }; // saver.textarea

  loader.preview = function () {
    var field = e.querySelector ('body-control-tab[name=preview] iframe');
    field.setAttribute ('sandbox', 'allow-scripts');
    field.setAttribute ('srcdoc', createBodyHTML ('', {}));
    var mc = new MessageChannel;
    field.onload = function () {
      this.contentWindow.postMessage ({type: "getHeight"}, '*', [mc.port1]);
      field.onload = null;
    };
    mc.port2.postMessage ({
      type: "setCurrentValue",
      valueSourceType: data.body_source_type,
      value: data.body,
      importedSites: opts.importedSites,
    });
    mc.port2.onmessage = function (ev) {
      if (ev.data.type === 'focus') {
        field.dispatchEvent (new Event ("focus", {bubbles: true}));
      } else if (ev.data.type === 'getObjectWithSearchData') {
        getObjectWithSearchData (ev.data.value).then (function (object) {
          ev.ports[0].postMessage (object);
        });
      }
    }; // onmessage
  }; // loader.preview
  saver.preview = function () {
    //
  }; // saver.preview

  var config = e.querySelector ('body-control-tab[name=config]');
  var prefix = Math.random () + '-';
  $$c (config, '[data-bc-name]').forEach (function (f) {
    var name = f.getAttribute ('data-bc-name');
    f.id = prefix + name;
    if (name === 'body_source_type') {
      f.value = data.body_source_type;
      f.onchange = function () {
        changeSourceType (this.value, {});
      };
    }
  });
  $$c (config, '[data-bc-for]').forEach (function (f) {
    f.for = prefix + f.getAttribute ('data-bc-for');
  });
  loader.config = saver.config = function () { };

  e.getCurrentValues = function (opts) {
    return changeMode (null, opts.actionStatus).then (function () {
      if (data.body_type == 1) {
        if (data.hasSource || data.body_source_type != 0) {
          return [
            ['body_type', data.body_type],
            ['body', data.body],
            ['body_source_type', data.body_source_type],
            ['body_source', data.body_source],
          ];
        } else {
          return [
            ['body_type', data.body_type],
            ['body', data.body],
          ];
        }
      } else {
        return [];
      }
    });
  }; // getCurrentValues

  if (data.body_type == 1) {
    changeSourceType (data.body_source_type, {show: true, force: true});
  } else {
    e.disabled = true;
    e.hidden = true;
  }
} // upgradeBodyControl

var TemplateSelectors = {};
TemplateSelectors.object = function (object, templates) {
  if (object.data.body_type == 3) {
    if (object.data.body_data.hatena_star) {
      return null;
    }
    if (object.data.body_data.new) {
      if (object.data.body_data.new.todo_state == 2) {
        return templates.close;
      } else if (object.data.body_data.new.todo_state == 1 &&
                 object.data.body_data.old.todo_state == 2) {
        return templates.reopen;
      } else {
        return templates.changed;
      }
    }
    if (object.data.body_data.trackback) {
      return templates.trackback;
    }
  }
  return undefined;
}; // object

(function () {
  var loaders = {
    define: function (name, code) {
      $with.register ('Loaders:' + name, code);
    }, // define
  };
  $with.register ('Loaders', function () {
    return loaders;
  });
}) ();

var LoadedActions = {};

LoadedActions.clickFirstButton = function () {
  var button = this.querySelector ('button');
  if (button) button.click ();
}; // clickFirstButton

var AddedActions = {};

AddedActions.editCommands = function () {
  var self = this;
  $$ (self, '[data-edit-command]').forEach (function (e) {
    e.onclick = function () {
      var ev = new Event ('gruwaeditcommand', {bubbles: true});
      ev.data = {type: this.getAttribute ('data-edit-command'),
                 value: this.value};
      self.dispatchEvent (ev);
    };
  });
}; // editCommands

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

    var listObjects = Object.values (objects || []);

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
          editObject (item, object, {
            open: true,
            importedSites: opts.importedSites,
          });
        }; // startEdit
        item.updateView = function () {
          Array.prototype.forEach.call (item.children, function (f) {
            if (f.localName !== 'edit-container') {
              fillFields (el, item, f, object, {
                importedSites: opts.importedSites,
              });
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
          editObject (item, object, {
            open: open,
            importedSites: opts.importedSites,
          }).then (function () {
            $$ /* not $$c*/ (item, 'edit-container body-control').forEach (function (e) {
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
        fillFields (el, item, item, object, {});
      }
    }; // fill

    var getTemplate = TemplateSelectors[el.getAttribute ('template-selector')] || function () { return undefined };
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
        t.setAttribute ('data-format', 'date');
        h.appendChild (t);
        section.appendChild (h);

        grouped[key].forEach (function (object) {
          var template = getTemplate (object, templates);
          if (template === undefined) template = templates._;
          if (template === null) return;
          var item = document.createElement (elementType);
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
          var template = getTemplate (object, templates);
          if (template === undefined) template = templates._;
          if (template === null) return;
          var item = document.createElement (elementType);
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

    return Promise.all (wait).then (function () {
      (el.getAttribute ('added-actions') || '').split (/\s+/).filter (function (_) { return _.length }).forEach (function (n) {
        AddedActions[n].call (el);
      });
      return result;
    });
  }; // showObjects

  var nextRef = null;
  var load = function () {
    if (el.hasAttribute ('noautoload')) {
      el.removeAttribute ('noautoload');
      return Promise.resolve ({});
    }

    var loader = el.getAttribute ('loader');
    if (loader) {
      as.stageStart ('load');
      return $with ('Loaders:' + loader).then (function (_) {
        as.stageEnd ('load');
        return _;
      });
    }
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
    if (url && url !== "o/get.json?with_data=1") {
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
      importedSites: json.imported_sites,
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
    if (el.hasAttribute ('disabled')) return;
    as.start ({stages: ["prep", "load", "show"]});
    nextRef = null;
    $$ (el, '.search-wiki_name-link').forEach (function (e) {
      var q = el.getAttribute ('param-q');
      e.hidden = ! /^\s*\S+\s*$/.test (q);
      fillFields (el, e, e, {name: q.replace (/^\s+/, '').replace (/\s+$/, '')}, {});
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
      (el.getAttribute ('loaded-actions') || '').split (/\s+/).filter (function (_) { return _.length }).forEach (function (n) {
        LoadedActions[n].call (el);
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
        var data = {index_ids: {}, timestamp: (new Date).valueOf () / 1000,
                    body_type: 1, body: ""};
        data.index_ids[el.getAttribute ('src-index_id')] = 1;
        var wikiName = el.getAttribute ('src-wiki_name');
        if (wikiName) data.title = wikiName;
        editObject (article, {data: data}, {open: true, focusTitle: button.hasAttribute ('data-focus-title')});
      };
    });
  });

  el.reload = function () {
    el.clearObjects ();
    el.load ();
  }; // reload

  $$c (el, '.reload-button').forEach (function (e) {
    e.onclick = function () {
      el.reload ();
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

    $$c (form, 'body-control, header input').forEach (function (control) {
      control.onfocus = function () {
        container.scrollIntoView ();
      };
    });

    wait.push (fillFormControls (form, object, {
      focusTitle: opts.focusTitle,
      importedSites: opts.importedSites,
    }));

    container.addEventListener ('gruwaeditcommand', function (ev) {
      form.getBodyControl ().sendCommand (ev.data);
    });

  // XXX autosave

  $$c (form, '.cancel-button').forEach (function (button) {
    button.onclick = function () {
      container.hidden = true;
      article.classList.remove ('editing');
    };
  });

  form.onsubmit = function () {
    var as = getActionStatus (form);
    as.start ({stages: ["saver", "dataset", "create", "edit", "update"]});
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
          return document.querySelector ('gr-list-container[src-index_id]')
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
      $$c (container, 'form header, form footer').forEach (function (e) {
        h1 += e.offsetHeight;
      });
      var h = document.documentElement.clientHeight - h1;
      container.querySelector ('form body-control').setHeight (h);
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
      var body = container.querySelector ('body-control');
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
  $$c (form, 'body-control').forEach (function (control) {
    ps.push (control.getCurrentValues ({actionStatus: opts.actionStatus}).then (function (nvs) {
      nvs.forEach (function (_) {
        if (_[1] != null) {
          fd.append (_[0], _[1]);
          c.push (function () { object.data[_[0]] = _[1] });
        }
      });
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

function upgradeWithSidebar (e) {
  e.addEventListener ('gruwatogglepanel', function (ev) {
    var sidebar = null;
    for (var i = 0; i < e.children.length; i++) {
      if (e.children[i].localName === 'aside') {
        sidebar = e.children[i];
        break;
      }
    }
    togglePanel (ev.panelName, sidebar);
  });
} // upgradeWithSidebar

function togglePanel (name, container) {
  container.panels = container.panels || {};
  if (!container.panels[name]) {
    var section = document.createElement ('section');
    section.hidden = true;
    section.className = 'panel ' + name;
    var template = document.getElementById ('template-panel-' + name);
    section.appendChild (template.content.cloneNode (true));
    container.panels[name] = section;
    container.appendChild (section);
  }
  var hideContainer = false;
  for (var n in container.panels) {
    if (n === name) {
      if (container.panels[n].hidden) {
        container.panels[n].hidden = false;
      } else {
        hideContainer = !container.hidden;
      }
    } else {
      container.panels[n].hidden = true;
    }
  }
  container.hidden = hideContainer;
} // togglePanel

function uploadFile (file, data, as) {
  as.stageStart ("create");
  var fd1 = new FormData;
  fd1.append ('is_file', 1);
  if (data.sourceSite) fd1.append ('source_site', data.sourceSite);
  if (data.sourcePage) fd1.append ('source_page', data.sourcePage);
  return gFetch ('o/create.json', {post: true, formData: fd1}).then (function (json) {
    data.object_id = json.object_id;
    as.stageEnd ("create");
    return gFetch ('o/' + data.object_id + '/upload.json?token=' + encodeURIComponent (json.upload_token), {post: true, body: file, as: as, asStage: "upload"});
  }).then (function () {
    var fd2 = new FormData;
    if (data.index_id) {
      fd2.append ('edit_index_id', 1);
      fd2.append ('index_id', data.index_id);
    }
    if (data.file_name != null) fd2.append ('file_name', data.file_name);
    if (data.file_size != null) fd2.append ('file_size', data.file_size);
    if (data.mime_type) fd2.append ('mime_type', data.mime_type);
    if (data.timestamp) fd2.append ('timestamp', data.timestamp);
    if (data.sourceTimestamp) fd2.append ('source_timestamp', data.sourceTimestamp);
    fd2.append ('file_closed', 1);
    as.stageStart ("close");
    return gFetch ('o/' + data.object_id + '/edit.json', {post: true, formData: fd2});
  }).then (function () {
    as.stageEnd ("close");
  });
} // uploadFile

function initUploader (form) {
  var upload = function (file) {
    var list = form.querySelector ('gr-list-container');
    var data = {
      file_name: file.name,
      file_size: file.size,
      mime_type: file.type,
      timestamp: file.lastModified / 1000,
      index_id: form.getAttribute ('data-context'),
    };
    var as;
    return list.showObjects ([{data: data}], {}).then (function (r) {
      var item = r.items[0];
      as = getActionStatus (item);
      as.start ({stages: ["create", "upload", "close", "show"]});
      return uploadFile (file, data, as);
    }).then (function () {
      as.stageStart ("show");
      return gFetch ('o/get.json?with_data=1&object_id=' + data.object_id, {});
    }).then (function (json) {
      var ev = new Event ('gruwaobjectsadded', {bubbles: true});
      ev.objects = json.objects;
      var promise = new Promise (function (a, b) { ev.wait = a });
      form.dispatchEvent (ev);
      ev.wait (null);
      return promise;
    }).then (function () {
      as.end ({ok: true});
    }, function (error) {
      as.end ({ok: false, error: error});
    });
  }; // upload

  form.elements["upload-button"].onclick = function () {
    form.elements.file.click ();
  };
  form.elements.file.onchange = function () {
    Array.prototype.forEach.call (form.elements.file.files, function (file) {
      upload (file);
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
      upload (file);
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
  if (container) {
    as.elements = $$c2 (container, 'gr-action-status');
    as.elements.forEach (function (e) {
      if (e.hasChildNodes ()) return;
      e.hidden = true;
      e.innerHTML = '<gr-action-status-message></gr-action-status-message> <progress></progress>';
    });
  } else {
    as.elements = [];
  }
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
    $$ (e, 'gr-action-status-message').forEach (function (f) {
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
    $$ (e, 'gr-action-status-message').forEach (function (f) {
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
  var self = this;
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
    $$ (e, 'gr-action-status-message').forEach (function (f) {
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
    return $$ (p, 'gr-list-container.comment-list')[0].showObjects (json.objects, {});
  }).then (function () {
    args.as.stageEnd ('showcreatedobjectincommentlist');
  });
}; // showCreatedObjectInCommentList
stageActions.showCreatedObjectInCommentList.stages = ['showcreatedobjectincommentlist'];

stageActions.fill = function (args) {
  var e = document.getElementById (args.arg);
  $grfill (e, args.result);
  e.hidden = false;
}; // fill

stageActions.reloadList = function (args) {
  var list = document.getElementById (args.arg);
  list.reload ();
}; // reloadList

stageActions.go = function (args) {
  args.as.stageStart ("next");
  location.href = args.arg.replace (/\{(\w+)\}/g, function (_, key) {
    return args.result[key];
  });
  return new Promise (function () { }); // keep form disabled
}; // go
stageActions.go.stages = ['next'];

stageActions.updateParent = function (args) {
  if (!args.form.parentObject) throw "No |parentObject|";

  var updated = false;
  $$ (args.form, '[name].data-field').forEach (function (e) {
    args.form.parentObject.data[e.name] = e.value;
    updated = true;
  });
  if (updated) {
    args.form.dispatchEvent (new Event ('objectdataupdate', {bubbles: true}));
  }
}; // updateParent

function upgradeForm (form) {
  if (form.hasAttribute ('is')) return;
  
  var formType = form.getAttribute ('data-form-type');
  if (formType === 'uploader') {
    return initUploader (form);
  } else if (form.getAttribute ('action') === 'javascript:' &&
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

    var stages = ["prep", "fetch"];

    var as = getActionStatus (form);
    var nextActions = (form.getAttribute ('data-next') || '')
        .split (/\s+/)
        .filter (function (_) { return _.length })
        .map (function (_) {
          var v = _.split (/:/, 2);
          return {
            action: v[0],
            arg: v[1], // or undefined
            as: as, form: form, submitButton: submit,
          };
        });
    nextActions.forEach (function (_) {
      if (!stageActions[_.action]) {
        throw "Action " + _.action + ' is not defined';
      }
      stages = stages.concat (stageActions[_.action].stages || []);
    });
    as.start ({stages: stages});
    var fd = new FormData (form); // this must be done before withFormDisabled
    withFormDisabled (form, function () {
      as.stageEnd ("prep");
      as.stageStart ("fetch");
      return gFetch (form.getAttribute ('data-action'), {post: true, formData: fd}).then (function (json) {
        as.stageEnd ("fetch");
        var p = Promise.resolve ();
        nextActions.forEach (function (stage) {
          p = p.then (function () {
            stage.result = json;
            return stageActions[stage.action] (stage);
          });
        });
        return p;
      });
    }).then (function () {
      as.end ({ok: true});
    }, function (error) {
      as.end ({error: error});
    });
  };
} // upgradeForm

(() => {
  var e = document.createElementNS ('data:,pc', 'loader');
  e.setAttribute ('name', 'groupLoader');
  e.pcHandler = function (opts) {
    if (!this.hasAttribute ('src')) return {};
    var url = (document.documentElement.getAttribute ('data-group-url') || '') + '/' + this.getAttribute ('src');
    if (this.hasAttribute ('src-search')) {
      if (GR._state.searchWord) {
        url += /\?/.test (url) ? '&' : '?';
        url += 'q=' + encodeURIComponent (GR._state.searchWord);
      }
    }
    if (opts.ref) {
      url += /\?/.test (url) ? '&' : '?';
      url += 'ref=' + encodeURIComponent (opts.ref);
    }
    if (opts.limit) {
      url += /\?/.test (url) ? '&' : '?';
      url += 'limit=' + encodeURIComponent (opts.limit);
    }
    return fetch (url, {
      credentials: "same-origin",
      referrerPolicy: 'same-origin',
    }).then ((res) => res.json ()).then ((json) => {
      if (!this.hasAttribute ('key')) throw new Error ("|key| is not specified");
      json = json || {};
      var hasNext = json.next_ref && opts.ref !== json.next_ref; // backcompat
      return {
        data: json[this.getAttribute ('key')],
        prev: {ref: json.prev_ref, has: json.has_prev, limit: opts.limit},
        next: {ref: json.next_ref, has: json.has_next || hasNext, limit: opts.limit},
      };
    });
  };
  document.head.appendChild (e);
  
  var e = document.createElementNS ('data:,pc', 'saver');
  e.setAttribute ('name', 'groupSaver');
  e.pcHandler = function (fd) {
    var url = (document.documentElement.getAttribute ('data-group-url') || '') + '/' + this.getAttribute ('action');
    return fetch (url, {
      credentials: 'same-origin',
      method: 'POST',
      referrerPolicy: 'same-origin',
      body: fd,
    }).then ((res) => {
      if (res.status !== 200) throw res;
      return res;
    });
  };
  document.head.appendChild (e);
  
  var e = document.createElementNS ('data:,pc', 'formsaved');
  e.setAttribute ('name', 'groupGo');
  e.pcHandler = function (args) {
    return args.json ().then ((json) => {
      var url = (document.documentElement.getAttribute ('data-group-url') || '') + '/' + $fill.string (args.args[1], json);
      return GR.navigate.go (url, {});
    });
  }; // groupGo
  document.head.appendChild (e);
}) ();

defineElement ({
  name: 'gr-editable-tr',
  props: {
    pcInit: function () {
      var tr = this;
      while (tr && tr.localName !== 'tr') {
        tr = tr.parentNode;
      }
      if (!tr) throw new Error ('No |tr| ancestor');

      this.row = tr;
      return GR.group.info ().then (group => {
        if (this.hasAttribute ('owneronly') &&
            group.member.member_type == 2) {
          //
        } else {
          this.row.querySelectorAll ('.if-editable').forEach (_ => _.remove ());
          this.remove ();
        }
        this.querySelectorAll ('.edit-button').forEach (_ => _.onclick = () => this.grToggleEditable (true));
        var id;
        this.querySelectorAll ('form').forEach (_ => {
          _.id = _.id || Math.random ();
          id = _.id;
        });
        this.row.querySelectorAll ('input, select, textarea').forEach (_ => {
          if (!_.form) _.setAttribute ('form', id);
        });
        this.grToggleEditable (false);
      });
    }, // pcInit
    grToggleEditable: function (editable) {
      this.row.querySelectorAll ('.if-editable').forEach (_ => _.hidden = ! editable);
      this.row.querySelectorAll ('.if-not-editable').forEach (_ => _.hidden = editable);
    }, // grToggleEditable
  },
}); // <gr-editable-tr>

defineElement ({
  name: 'form',
  is: 'gr-search',
  props: {
    pcInit: function () {
      this.onsubmit = (ev) => {
        this.grSearch ();
        return false;
      };
    }, // pcInit
    grSearch: function () {
      var q = this.elements.q.value;
      var url = (document.documentElement.getAttribute ('data-group-url') || '') + '/search?q=' + encodeURIComponent (q);
      return GR.navigate.go (url, {});
    }, // grSearch
  },
});

defineElement ({
  name: 'gr-search-wiki-name',
  props: {
    pcInit: function () {
      var word = (GR._state.searchWord || '').replace (/^\s+/, '').replace (/\s+$/, '');
      if (word.match (/^\S+$/)) {
        this.hidden = false;
        $fill (this, {name: word});
      } else {
        this.hidden = true;
      }      
    }, // pcInit
  },
}); // <gr-search-wiki-name>

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
        fillFields (list, item, item, object, {});
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
    f.onclick = function (ev) {
      if (e.getAttribute ('type') === 'jump') {
        var fd = new FormData;
        if (f.title) fd.append ('label', f.title);
        fd.append ('url', f.href);
        gFetch ('/jump/add.json', {post: true, formData: fd}).then (function () {
          $$ (document, 'gr-list-container[src="/jump/list.json"]').forEach (function (e) {
            e.clearObjects ();
            e.load ();
          });
        });
      } else {
        copyText (f.href);
      }
      ev.stopPropagation ();
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

function upgradeObjectRef (e) {
  var objectId = e.getAttribute ('value');
  if (!objectId) return;

  if (e.hasAttribute ('template')) {
    e.appendChild (document.querySelector (e.getAttribute ('template')).content.cloneNode (true));
    e.removeAttribute ('template');
  }

  return getObjectWithSearchData (objectId).then (function (object) {
    fillFields (e, e, e, object, {});
  });
} // upgradeObjectRef

(function () {
  var objects = {};
  this.getObjectWithSearchData = function (objectId) {
    if (objects[objectId]) return Promise.resolve (objects[objectId]);

    var fd = new FormData;
    fd.append ('object_id', objectId);
    return gFetch ('o/get.json?with_data=1&with_snippet=1', {post: true, formData: fd}).then (function (json) {
      return objects[objectId] = json.objects[objectId] || {};
    });
  } // getObjectWithSearchData
}) ();

function showTooltip (e, opts) {
  if (! e) {
    var container = document.querySelector ('tooltip-box');
    if (container) container.hidden = true;
    return;
  }

  var container = document.querySelector ('tooltip-box') || document.createElement ('tooltip-box');
  container.textContent = '';
  container.style.top = opts.top + 'px';
  container.style.left = opts.left + 'px';
  container.hidden = false;
  container.appendChild (e);
  document.body.appendChild (container);
} // showTooltip

(function () {
  var urlToImportedURL = {};

  this.showURLTooltip = function (url, opts) {
    var url;
    try {
      url = new URL (url);
    } catch (e) {
      url = {};
    }
    if (url.origin === location.origin) {
      var m = url.pathname.match (/^\/g\/[^\/]+\/o\/([0-9]+)\//);
      if (m) {
        var ref = document.createElement ('object-ref');
        ref.setAttribute ('value', m[1]);
        ref.setAttribute ('template', '#object-ref-template');
        showTooltip (ref, opts);
        return;
      }

      if (url.pathname.match (/imported.+go$/)) {
        if (urlToImportedURL[url.pathname]) {
          return showURLTooltip (urlToImportedURL[url.pathname], opts);
        }
        return gFetch (url.pathname + '.json', {}).then (function (json) {
          urlToImportedURL[url.pathname] = json.url;
          return showURLTooltip (json.url, opts);
        });
      }
    }

    return showTooltip (null, {});
  } // showURLTooltip
}) ();

var RunAction = {};

RunAction.installPrependNewObjects = function () {
  this.parentNode.addEventListener ('gruwaobjectsadded', function (ev) {
    return ev.wait (Promise.all ($$c (this, 'gr-list-container[key=objects]').map (function (e) {
      return e.showObjects (ev.objects, {prepend: true});
    })));
  });
}; // installPrependNewObjects

function upgradeRunAction (e) {
  var action = RunAction[e.getAttribute ('name')];
  action.apply (e);
} // upgradeRunAction

function Formatter () { }

Formatter.html = function (source) {
  var doc = document.implementation.createHTMLDocument ();
  var div = doc.createElement ('div');
  div.innerHTML = source;
  return div;
}; // html

Formatter.hatena = function (source) {
  return fetch ("https://textformatter.herokuapp.com/hatena", { // XXX
    method: "post",
    body: source,
  }).then (function (r) {
    return r.text ();
  }).then (function (x) {
    var div = Formatter.html (x);
    $$ (div, 'hatena-html[base]').forEach (function (container) {
      var base = container.getAttribute ('base');
      $$ (container, 'a[href]:not([href^="http:"]):not([href^="https:"])').forEach (function (link) {
        try {
          link.href = new URL (link.getAttribute ('href'), base).toString ();
        } catch (e) { }
      });
    });
    $$ (div, 'hatena-html[keywordindexid]').forEach (function (container) {
      var indexId = container.getAttribute ('keywordindexid');
      $$ (container, 'a[data-hatena-keyword]').forEach (function (link) {
        link.classList.add ('hatena-keyword');
        link.href = document.documentElement.getAttribute ('data-group-url') + '/i/' + encodeURIComponent (indexId) + '/wiki/' + encodeURIComponent (link.getAttribute ('data-hatena-keyword'));
      });
    });
    $$ (div, 'a[data-hatena-keyword]:not(.hatena-keyword)').forEach (function (link) {
      link.classList.add ('hatena-keyword');
      link.href = document.documentElement.getAttribute ('data-group-url') + '/wiki/' + encodeURIComponent (link.getAttribute ('data-hatena-keyword'));
    });
    return div.innerHTML;
  });
}; // hatena

(new MutationObserver (function (mutations) {
  mutations.forEach (function (m) {
    Array.prototype.forEach.call (m.addedNodes, function (x) {
      if (x.localName === 'gr-list-container') {
        upgradeList (x);
      } else if (x.localName) {
        $$ (x, 'gr-list-container').forEach (upgradeList);
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
      if (x.localName === 'gr-popup-menu') {
        upgradePopupMenu (x);
      } else if (x.localName) {
        $$ (x, 'gr-popup-menu').forEach (upgradePopupMenu);
      }
      if (x.localName === 'copy-button') {
        upgradeCopyButton (x);
      } else if (x.localName) {
        $$ (x, 'copy-button').forEach (upgradeCopyButton);
      }
      if (x.localName === 'with-sidebar') {
        upgradeWithSidebar (x);
      } else if (x.localName) {
        $$ (x, 'with-sidebar').forEach (upgradeWithSidebar);
      }
      if (x.localName === 'run-action') {
        upgradeRunAction (x);
      } else if (x.localName) {
        $$ (x, 'run-action').forEach (upgradeRunAction);
      }
      if (x.localName === 'object-ref') {
        upgradeObjectRef (x);
      } else if (x.localName) {
        $$ (x, 'object-ref').forEach (upgradeObjectRef);
      }
    });
  });
})).observe (document.documentElement, {childList: true, subtree: true});
$$ (document, 'gr-list-container').forEach (upgradeList);
$$ (document, 'form').forEach (upgradeForm);
$$ (document, 'account-name[account_id]').forEach (upgradeAccountName);
$$ (document, 'gr-popup-menu').forEach (upgradePopupMenu);
$$ (document, 'copy-button').forEach (upgradeCopyButton);
$$ (document, 'with-sidebar').forEach (upgradeWithSidebar);
$$ (document, 'run-action').forEach (upgradeRunAction);
$$ (document, 'object-ref').forEach (upgradeObjectRef);

GR.navigate = {};

GR.navigate._init = function () {
  addEventListener ('click', (ev) => {
    var n = ev.target;
    while (n && n.localName !== 'a') {
      n = n.parentElement;
    }
    if (n &&
        (n.protocol === 'https:' || n.protocol === 'http:') &&
        n.target === '' &&
        !n.is) {
      GR.navigate.go (n.href, {});
      ev.preventDefault ();
    }
  });
  GR.navigate.enabled = true;
  history.scrollRestoration = "manual";
}; // GR.navigate._init

GR.navigate.go = function (u, args) {
  var url = new URL (u, location.href);
  var status = document.querySelector ('gr-navigate-status');
  status.grStart (url);
  return Promise.resolve ().then (() => {
    if (GR.navigate.enabled &&
        url.origin === location.origin) {
      if (!args.reload &&
          url.pathname === location.pathname &&
          url.search === location.search) {
        return ['fragment', url];
      }
      return GR.group.info ().then (group => {
        var path = url.pathname;
        var prefix = '/g/' + group.group_id + '/';
        if (path.substring (0, prefix.length) === prefix) {
          path = path.substring (prefix.length);

          if (path === '') {
            return ['group', 'index', {}];
          }

          var m = path.match (/^(search|config|members)$/);
          if (m) return ['group', m[1], {
            q: url.searchParams.get ('q'),
          }];

          m = path.match (/^o\/([0-9]+)\/$/);
          if (m) return ['group', 'index-index', {
            objectId: m[1],
          }];

          m = path.match (/^i\/([0-9]+)\/$/);
          if (m) return ['group', 'index-index', {
            indexId: m[1],
          }];

          m = path.match (/^i\/([0-9]+)\/(config)$/);
          if (m) return ['group', 'index-' + m[2], {
            indexId: m[1],
          }];

          m = path.match (/^i\/([0-9]+)\/wiki\/([^\/]+)$/);
          if (m) {
            var n;
            try {
              n = decodeURIComponent (m[2]);
            } catch (e) { }
            return ['group', 'index-index', {
              indexId: m[1],
              wikiName: n,
            }];
          }

          m = path.match (/^wiki\/([^\/]+)$/);
          if (m) {
            var n;
            try {
              n = decodeURIComponent (m[1]);
            } catch (e) { }
            return ['group', 'index-index', {
              wikiName: n,
            }];
          }

          return ['site', url];
        } else {
          return ['site', url];
        }
      });
    }
    return ['external', url];
  }).then (_ => {
    if (GR._state.currentNavigate) {
      GR._state.currentNavigate.abort ();
      delete GR._state.currentNavigate;
    }
    if (_[0] === 'group') {
      var ac = new AbortController;
      var nav = GR._state.currentNavigate = {
        abort: () => ac.abort (),
      };
      return GR.navigate._show (_[1], _[2], {
        url: url,
        replace: args.replace,
        reload: args.reload,
        status: status,
        signal1: args.signal || (new AbortController).signal,
        signal2: ac.signal,
        thisNavigate: nav,
      });
    } else if (_[0] === 'fragment') {
      status.grStop ();
      location.hash = _[1].hash;
    } else { // external or site
      if (location.href === _[1].href) {
        var e = new Error ('Failed to navigate to URL <'+_[1]+'>');
        status.grThrow (e);
      } else {
        status.grStop ();
        if (args.reload) {
          location.replace (_[1]);
        } else {
          location.href = _[1];
        }
      }
    }
  });
}; // go

GR.navigate._show = function (pageName, pageArgs, opts) {
  // Assert: pageName is valid
  // XXX revision test / session timeout / account changed / 50[234]
  var pushed = false;
  return $getTemplateSet ('page-' + pageName).then (ts => {
    var params = {};
    var wait = [];
    wait.push (GR.group.info ().then (_ => params.group = _));
    if (pageArgs.indexId) {
      wait.push (GR.index.info (pageArgs.indexId).then (_ => params.index = _));
    }
    if (pageName === 'search') {
      params.search = {q: pageArgs.q || ''};
    }
    // XXX abort wait by opts.signal[12]
    return Promise.all (wait).then (_ => {
      if (opts.signal1.aborted || opts.signal2.aborted) {
        throw new DOMException ('Navigation request aborted', 'AbortError');
      }
      if (opts.url) {
        if (opts.reload) {
          //
        } else if (opts.replace) {
          history.replaceState ({}, null, opts.url);
        } else {
          history.pushState ({}, null, opts.url);
        }
      }
      pushed = true;
    }).then (_ => {
      if (GR._state.currentNavigate !== opts.thisNavigate) return;
      
      params.title = params.group.title;
      params.url = '/g/' + params.group.group_id + '/';
      params.theme = params.group.theme;
      if (params.index && params.index.theme) {
        params.theme = params.index.theme;
        params.url += 'i/' + params.index.index_id + '/';
        params.title = params.index.title;
      }
      document.querySelectorAll ('body > header.page').forEach (_ => {
        $fill (_, params);

        var menu = _.querySelector ('gr-menu');
        if (params.index && params.index.theme) {
          menu.setAttribute ('type', 'index');
          menu.setAttribute ('indexid', params.index.index_id);
        } else {
          menu.setAttribute ('type', 'group');
        }
      });
      var contentTitle = '';
      document.querySelectorAll ('page-main').forEach (_ => {
        var div = ts.createFromTemplate ('div', params);
        contentTitle = div.title;
        div.title = '';

        var isOwner = params.group.member.member_type == 2;
        if (isOwner) {
          div.querySelectorAll ('[data-gr-if-group-non-owner]').forEach (_ => {
            _.remove ();
          });
        } else {
          div.querySelectorAll ('[data-gr-if-group-owner]').forEach (_ => {
            _.remove ();
          });
        }

        if (params.index) {
          div.querySelectorAll ('[data-gr-if-index-type]:not([data-gr-if-index-type~="'+params.index.index_type+'"])').forEach (_ => {
            _.remove ();
          });

          var isDefaultIndex = params.index.index_id == params.group.member.default_index_id;
          if (isDefaultIndex) {
            div.querySelectorAll ('[data-gr-if-not-default-index]').forEach (_ => {
              _.remove ();
            });
          } else {
            div.querySelectorAll ('[data-gr-if-default-index]').forEach (_ => {
              _.remove ();
            });
          }

          var isDefaultWiki = params.index.index_id == params.group.default_wiki_index_id;
          if (isDefaultWiki) {
            div.querySelectorAll ('[data-gr-if-not-default-wiki]').forEach (_ => {
              _.remove ();
            });
          } else {
            div.querySelectorAll ('[data-gr-if-default-wiki]').forEach (_ => {
              _.remove ();
            });
          }
        }

        _.textContent = '';
        while (div.firstChild) _.appendChild (div.firstChild);
      });
      var title = [params.group.title];
      if (params.index) {
        title.unshift (params.index.title);
      }
      if (contentTitle !== '') title.unshift (contentTitle);
      if (params.search) {
        GR.page.setSearch (params.search);
      } else {
        GR.page.setSearch (null);
      }
      GR.page.setTitle (title.join (' - '));
      return GR.theme.set (params.theme);
    });
  }).then (_ => {
    if (GR._state.currentNavigate !== opts.thisNavigate) return;
    document.documentElement.scrollTop = 0; // XXX restore
    opts.status.grStop ();
    delete GR._state.currentNavigate;
  }, e => {
    if (GR._state.currentNavigate !== opts.thisNavigate) {
      if (e && e.name === 'AbortError') {
        console.log ("Navigation to <"+url+"> canceled");
        return;
      } else {
        console.log ("Navigation to <"+url+"> canceled and errored");
        throw e;
      }
    }
    
    if (!pushed && opts.url) {
      if (opts.reload) {
        //
      } else if (opts.replace) {
        history.replaceState ({}, null, opts.url);
      } else {
        history.pushState ({}, null, opts.url);
      }
    }
    document.querySelectorAll ('page-main').forEach (_ => {
      _.textContent = '';
    });
    if (e && e.name === 'AbortError') {
      opts.status.grStop ();
    } else {
      opts.status.grThrow (e);
    }
    delete GR._state.currentNavigate;
  });
}; // _show

defineElement ({
  name: 'gr-navigate-status',
  pcActionStatus: true,
  props: {
    pcInit: function () {
      this.hidden = true;
    }, // pcInit
    grStart: function (url) {
      console.log ("Open URL <"+url+">...");
      document.documentElement.setAttribute ('data-navigating', '');
      clearTimeout (this.grTimer);
      this.grTimer = setTimeout (() => this.hidden = false, 500);

      var as = this.grAS = this.pcActionStatus ();
      as.start ({stages: ['loading']});
      as.stageStart ('loading');
    }, // grStart
    grStop: function () {
      this.grAS.end ({ok: true});
      this.hidden = true;
      clearTimeout (this.grTimer);
      document.documentElement.removeAttribute ('data-navigating');
    }, // grStop
    grThrow: function (e) {
      this.grAS.end ({error: e});
      clearTimeout (this.grTimer);
      this.hidden = false;
      document.documentElement.removeAttribute ('data-navigating');
    }, // grThrow
  },
}); // <gr-navigate-status>

defineElement ({
  name: 'gr-navigate',
  props: {
    pcInit: function () {
      if (!GR.navigate.enabled) GR.navigate._init ();
      GR.navigate.go (location.href, {reload: true});
      this.remove ();
    }, // pcInit
  },
}); // <gr-navigate>

addEventListener ('popstate', ev => {
  var nav = document.createElement ('gr-navigate');
  document.body.appendChild (nav);
});

/*

License:

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
