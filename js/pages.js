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

GR.compat = {};

// XXX
$with.register ('GR', () => window.GR);

GR.idle = self.requestIdleCallback ? (cb) => {
  requestIdleCallback (cb);
} : (cb) => {
  setTimeout (cb, 600);
};

class GRError extends Error {
  constructor (type) {
    var message = type;
    if (type === 'InvalidAccountError') {
      message = 'ログインしていないか、グループに参加していないアカウントです。正しいアカウントでログインしてからもう一度実行してください。 (403)';
    }
    super (message);
    this.name = type;
  };
};
GR.Error = GRError;
delete window.GRError;

GR.Error.handle403 = function (res) {
  var e = new GR.Error ('InvalidAccountError');
  e.errorResponse = res;
  GR.account.check ({source: '403'});
  return e;
}; // handle403

GR._decodeURL = function (s) {
  try {
    return decodeURIComponent (s);
  } catch (e) {
    return null;
  }
}; // GR._decodeURL

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

GR._state = {currentPage: {}, uToImported: {}};
GR._objects = {};
GR._timestamp = {};

GR.Favicon = {};

GR.Favicon.loadBaseImage = function () {
  var link = document.querySelector ('link[rel~=icon]');
  if (!link) return;
  return new Promise ((ok, ng) => {
    var img = document.createElement ('img');
    img.src = link.href;
    img.width = img.height = 600;
    img.onload = () => ok (img);
    img.onerror = ng;
  }).then (img => {
    GR._state.faviconBaseImage = img;
    GR.Favicon.redraw ();
  });
}; // GR.Favicon.loadBaseImage

GR.Favicon.redraw = function () {
  var canvas = document.createElement ('canvas');
  canvas.width = canvas.height = 600;
  var ctx = canvas.getContext ('2d');
  
  var envName = document.documentElement.getAttribute ('data-env');
  if (envName) {
    ctx.globalAlpha = 0.4;
  }

  if (GR._state.faviconBaseImage) {
    ctx.drawImage (GR._state.faviconBaseImage, 0, 0, 600, 600);
  }

  if (envName) {
    ctx.globalAlpha = 1;
    ctx.font = "bold 480px serif";
    ctx.fillStyle = "red";
    ctx.fillText (envName, 0, 600);
  }
  
  var link = document.querySelector ('link[rel~=icon]');
  link.href = canvas.toDataURL ();
}; // GR.Favicon.redraw    

(() => {
  var m = location.pathname.match (/^\/g\/([0-9]+)\//);
  if (m) {
    document.documentElement.setAttribute ('data-group-url', '/g/' + m[1]);

    var link = document.createElement ('link');
    link.rel = 'prefetch';
    link.as = 'fetch';
    link.href = '/g/' + m[1] + '/my/info.json';
    document.head.appendChild (link);

    var link = document.createElement ('link');
    link.rel = 'icon';
    link.href = '/g/' + m[1] + '/icon';
    document.head.appendChild (link);
  } else {
    var link = document.createElement ('link');
    link.rel = 'prefetch';
    link.as = 'fetch';
    link.href = '/my/info.json';
    document.head.appendChild (link);
  }
  
  GR.idle (() => GR.Favicon.loadBaseImage ());

  var envName = document.documentElement.getAttribute ('data-env');
  if (envName) {
    var label = "Gruwa - " + envName + " -";
    var div = document.createElement ('div');
    div.innerHTML = '<svg height="'+(label.length/2+1)+'em" width="1em" style="font-size: 24px; opacity: 0.4"><text x="0" y="1em" fill="red" font-weight="bold" transform="rotate(90 12 12)"></text></svg>';
    div.querySelector ('text').textContent = label;
    var d = document.implementation.createDocument (null, null);
    d.appendChild (div.firstChild);
    document.documentElement.style.backgroundPosition = 'right';
    document.documentElement.style.backgroundRepeat = 'repeat-y';
    document.documentElement.style.backgroundImage = 'url("data:image/svg+xml;charset=utf-8,' + encodeURIComponent (d.documentElement.outerHTML) + '")';
    document.documentElement.style.paddingRight = '24px';
  }
  
}) ();

GR._findPointedElement = function (context, prefix) {
  var sel = context.getAttribute (prefix + 'selector');
  if (sel) {
    var ancestor;
    var ancestorName = context.getAttribute (prefix + 'ancestor');
    if (ancestorName) {
      ancestor = context.parentNode;
      while (ancestor && ancestor.localName !== ancestorName) {
        ancestor = ancestor.parentNode;
      }
      if (!ancestor) throw new Error ('Bad |'+prefix+'ancestor|: |'+ancestorName+'|');
    }
    return Array.prototype.slice.call ((ancestor || document).querySelectorAll (sel)); // or throw
  } else {
    return [];
  }
}; // GR._findPointedElement

GR._updateMyInfo = function () {
  delete GR._state.getMembers;
  
  // Cached until updated by reloadGroupInfo
  return GR._state.updateMyInfo = Promise.resolve ().then (() => {
    if (GR._state.navigatePartition === 'dashboard') {
      return fetch ('/my/info.json', {}).then (res => {
        if (res.status !== 200) throw res;
        return res.json ();
      }).then (json => {
        return {account: json};
      });
    } else {
      var url = document.documentElement.getAttribute ('data-group-url') + '/my/info.json';
      return fetch (url).then (res => {
        if (res.status !== 200) throw res;
        return res.json ();
      });
    }
  }).then (json => {
    var oldAccount = GR._state.account || {newSession: true};
    GR._state.account = json.account;
    GR._state.group = json.group;
    if (json.group) {
      GR._state.account.group_id = json.group.group_id;
      GR._state.group.member = json.group_member;
    }
    GR._timestamp.myinfo = performance.now ();

    document.querySelectorAll ('gr-account-dialog').forEach (_ => _.grClose ());
    if (json.account.account_id == null) {
      GR.account.showDialog ();

      if (oldAccount.account_id) {
        if (window.BroadcastChannel)
        new BroadcastChannel ('grAccount').postMessage ({grAccountUpdated: true});
      }
    } else if (oldAccount.account_id !== json.account.account_id &&
               !oldAccount.newSession) {
      document.querySelectorAll ('gr-account[self]').forEach (_ => _.grRender ());
      
      if (window.BroadcastChannel)
      new BroadcastChannel ('grAccount').postMessage ({grAccountUpdated: true});

      if (GR._state.navigatePartition === 'dashboard') {
        location.reload ();
      }
    }
    GR.account.scheduleCheck ();
  }, (e) => {
    if (e instanceof Response && e.status === 403) {
      GR.account.showDialog ();

      if (!GR._state.account) GR._state.account = {};
      if (!GR._state.account.stale) {
        GR._state.account.stale = true;
        if (window.BroadcastChannel)
        new BroadcastChannel ('grAccount').postMessage ({grAccountUpdated: true});
      }
      return;
    }
    delete GR._state.updateMyInfo;
    throw e;
  });
}; // GR._updateMyInfo

GR._myinfo = function () {
  return GR._state.updateMyInfo || GR._updateMyInfo ();
}; // GR._myinfo

GR.page = {};

GR.page.setTitle = function (titles) {
  GR._state.title = titles.map (_ => "\u2066"+_+"\u2069").join (" - ");
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
    document.title = "\u2066" + GR._state.searchWord + "\u2069 - " + GR._state.title;
  } else {
    document.title = GR._state.title;
  }
}; // GR.page._title

GR.page.showMiniNotification = function (obj) {
  return $getTemplateSet (obj.template).then (tm => {
    var e = tm.createFromTemplate ('gr-mn-item', obj);
    e.querySelectorAll ('.cancel-button').forEach (_ => {
      _.onclick = () => {
        e.remove ();
        if (obj.close) obj.close.apply (_);
      };
    });

    var f = document.body.querySelector ('gr-mn-list');
    if (!f) {
      f = document.createElement ('gr-mn-list');
      document.body.appendChild (f);
    }
    f.appendChild (e);
  });
}; // GR.page.showMiniNotification

GR.account = {};

GR.account.info = function () {
  return GR._myinfo ().then (_ => {
    return GR._state.account;
  });
}; // GR.account.info

GR.account.get = function (accountId) {
  return GR.group._members ().then (members => {
    return members[accountId];
  });
}; // GR.account.get

GR.account.showDialog = function () {
  if (document.querySelector ('gr-account-dialog')) return;
  document.body.appendChild (document.createElement ('gr-account-dialog'));
}; // GR.account.showDialog

GR.account.check = function (opt) {
  if (opt.force ||
      !(performance.now () - GR._timestamp.myinfo < 3*60*1000)) {
    //
  } else {
    return Promise.resolve ();
  }
  return GR._state.accountChecking = GR._state.accountChecking || Promise.resolve ().then (() => {
    console.log ('account check invoked from:', opt.source, performance.now ()); // debug
    return GR._updateMyInfo ();
  }).finally (() => {
    delete GR._state.accountChecking;
  });
}; // GR.account.check

GR.account.scheduleCheck = function () {
  clearTimeout (GR._state.checkTimer);
  GR._state.checkTimer = setTimeout (() => {
    GR.account.check ({source: 'timer'});
  }, 30*60*1000);
}; // GR.account.scheduleCheck

GR.group = {};

GR.group.info = function () {
  return GR._myinfo ().then (_ => {
    if (!GR._state.group) throw new GR.Error ('InvalidAccountError');
    return GR._state.group;
  });
}; // GR.group.info

GR.group._members = function () {
  // Cached until updated by reloadGroupInfo
  if (GR._state.getMembers) return GR._state.getMembers;
  
  var map = {};
  var get = (ref) => {
    var r = '';
    if (ref) r = '?ref=' + encodeURIComponent (ref);
    return Promise.all ([
      gFetch ('members/list.json' + r, {}),
      GR.group.info (),
    ]).then (_ => {
      var [json, group] = _;
      Object.values (json.members).forEach (_ => {
        map[_.account_id] = _;
        _.group_id = group.group_id;
      });
      if (json.has_next) {
        return get (json.next_ref);
      }
    });
  }; // get
  return GR._state.getMembers = get (null).then (_ => {
    return map;
  });
}; // GR.group._members

GR.group.activeMembers = function () {
  return GR.group._members ().then (list => {
    return Object.values (list).filter (_ => _.user_status == 1 && _.owner_status == 1); // open
  });
}; // GR.group.activeMembers

(() => {

  GR.account.scheduleCheck ();
  if (window.BroadcastChannel) {
    var bc = new BroadcastChannel ('grAccount');
    bc.onmessage = (ev) => {
      if (ev.data.grAccountUpdated) {
        setTimeout (() => {
          GR.account.check ({source: 'bc'});
        }, Math.random () * 60*1000);
      }
    };
  }

  var e = document.createElementNS ('data:,pc', 'loader');
  e.setAttribute ('name', 'groupMembersLoader');
  e.pcHandler = function (opts) {
    return GR.group._members ().then (members => {
      return {
        data: members,
      };
    });
  };
  document.head.appendChild (e);

  var e = document.createElementNS ('data:,pc', 'formsaved');
  e.setAttribute ('name', 'createGroupInitials');
  e.pcHandler = function (args) {
    return args.json ().then (json => {
      return Promise.all ([
        (() => {
          var fd = new FormData;
          fd.append ('title', this.getAttribute ('data-wikititle'));
          fd.append ('index_type', 2);
          return gFetch ("g/" + json.group_id + '/i/create.json', {post: true, formData: fd}).then (function (json) {
            var fd2 = new FormData;
            fd2.append ('default_wiki_index_id', json.index_id);
            return gFetch ("g/" + json.group_id + '/edit.json', {post: true, formData: fd2});
          });
        }) (),
        (() => {
          var fd = new FormData;
          fd.append ('title', this.getAttribute ('data-iconsettitle'));
          fd.append ('index_type', 6);
          fd.append ('subtype', 'icon');
          return gFetch ("g/" + json.group_id + '/i/create.json', {post: true, formData: fd});
        }) (),
      ]);
    });
  }; // createGroupInitials
  document.head.appendChild (e);
  
  var e = document.createElementNS ('data:,pc', 'formsaved');
  e.setAttribute ('name', 'reloadGroupInfo');
  e.pcHandler = function (args) {
    return Promise.all ([
      GR._updateMyInfo (),
      gFetch ('icon', {reload: true, ignoreError: true}),
    ]).then (() => {
      return GR.account.info ();
    }).then (account => {
      if (account.guide_object_id) {
        document.querySelectorAll ('#account-guide-create-form').forEach (_ => {
          _.hidden = true;
        });
        document.querySelectorAll ('#account-guide-link').forEach (_ => {
          _.hidden = false;
        });
      } else {
        document.querySelectorAll ('#account-guide-create-form').forEach (_ => {
          _.hidden = false;
        });
        document.querySelectorAll ('#account-guide-link').forEach (_ => {
          _.hidden = true;
        });
      }
      return gFetch ('account/'+account.account_id+'/icon', {reload: true, ignoreError: true});
    }).then (() => {
      document.querySelectorAll ('head link[rel~=icon]').forEach (_ => {
        _.href += '?' + Math.random ();
      });
      document.querySelectorAll ('img.icon').forEach (_ => {
        if (_.src.match (/^https?:/)) _.src += '?' + Math.random ();
      });
      return GR.group.info ();
    }).then (group => {
      if (group.guide_object_id) {
        document.querySelectorAll ('#guide-create-form').forEach (_ => {
          _.hidden = true;
        });
        document.querySelectorAll ('#guide-link').forEach (_ => {
          _.hidden = false;
        });
      } else {
        document.querySelectorAll ('#guide-create-form').forEach (_ => {
          _.hidden = false;
        });
        document.querySelectorAll ('#guide-link').forEach (_ => {
          _.hidden = true;
        });
      }
    });
  }; // reloadGroupInfo
  document.head.appendChild (e);

  var e = document.createElementNS ('data:,pc', 'formsaved');
  e.setAttribute ('name', 'reloadIndexInfo');
  e.pcHandler = function (args) {
    return GR.index._updateList ({force: true});
  }; // reloadIndexInfo
  document.head.appendChild (e);

  var e = document.createElementNS ('data:,pc', 'loader');
  e.setAttribute ('name', 'recentIndexListLoader');
  e.pcHandler = function (opts) {
    return GR.index.list ().then (list => {
      list = Object.values (list).filter (_ => {
        return _.index_type == 1 || _.index_type == 2 || _.index_type == 3;
      }).sort ((a, b) => b.updated - a.updated);
      return {
        data: list,
      };
    });
  };
  document.head.appendChild (e);

  var e = document.createElementNS ('data:,pc', 'loader');
  e.setAttribute ('name', 'filesetIndexListLoader');
  e.pcHandler = function (opts) {
    return GR.index.list ().then (list => {
      list = Object.values (list).filter (_ => {
        return _.index_type == 6;
      }).sort ((a, b) => b.updated - a.updated);
      return {
        data: list,
      };
    });
  };
  document.head.appendChild (e);

}) ();

GR.group.resolveImportedURL = function (u) {
  if (GR._state.uToImported[u] !== undefined) {
    return Promise.resolve (GR._state.uToImported[u]);
  }
  return gFetch ('imported/' + encodeURIComponent (u) + '/go.json', {}).then (function (json) {
    return GR._state.uToImported[u] = json.url;
  });
}; // GR.group.resolveImportedURL

GR.group.importedSites = function () {
  // XXX stale after ...
  if (GR._state.importedSites) return Promise.resolve (GR._state.importedSites);
  return gFetch ('imported/sites.json', {}).then (json => GR._state.importedSites = json.sites);
}; // GR.group.importedSites

GR.index = {};

GR.index.list = () => {
  if (GR._state.getIndexList) {
    if (performance.now () - GR._timestamp.indexList > 3*60*60*1000) {
      GR.idle (() => GR.index._updateList ());
    }
    return GR._state.getIndexList;
  }
  return GR._state.getIndexList = gFetch ('i/list.json', {}).then (json => {
    GR._timestamp.indexList = performance.now ();
    return json.index_list;
  });
}; // GR.index.list

GR.index._updateList = (opts) => {
  if (opts.force ||
      !(performance.now () - GR._timestamp.indexList < 3*60*1000)) {
    //
  } else {
    return GR.index.list ();
  }
  delete GR._state.getIndexList;
  return GR.index.list ();
}; // GR.index._updateList

GR.index.info = function (indexId) {
  return GR.index.list ().then (list => {
    var info = list[indexId];
    if (info) return info;

    return GR.index._updateList ({}).then (list => {
      var info = list[indexId];
      if (info) return info;
      throw new Error ('404 Index |'+indexId+'| not found');
      //console.log ('Index |'+indexId+'| not found');
      //return {index_id: indexId, title: indexId, group_id: GR._state.group.group_id};
    });
  });
}; // GR.index.info

defineElement ({
  name: 'gr-index-list',
  fill: 'idlattribute',
  props: {
    pcInit: function () {
      this.grValue = Object.keys (this.value || {});
      if (this.grValue) Promise.resolve ().then (() => this.grRender ());
      Object.defineProperty (this, 'value', {
        set: function (v) {
          this.grValue = Object.keys (v || {});
          Promise.resolve ().then (() => this.grRender ());
        },
      });
    }, // pcInit
    grRender: function () {
      var indexIds = this.grValue.sort ((a, b) => {
        return a - b;
      });
      var currentIndex = this.hasAttribute ('nocurrentindex') ? GR._state.currentPage.index ? GR._state.currentPage.index.index_id : null : null;
      var indexList = {};
      return Promise.all ([
        $getTemplateSet ('gr-index-list-item'),
        Promise.all (indexIds.map (indexId => GR.index.info (indexId).then (_ => indexList[indexId] = _))),
      ]).then (_ => {
        var [tm] = _;
        this.textContent = '';

        var expectedIndexType = this.getAttribute ('indextype'); // or null

        indexIds.forEach (indexId => {
          if (indexId === currentIndex) return;
          
          var index = indexList[indexId];
          if (expectedIndexType && expectedIndexType != index.index_type) return;
          var item = {index: index, class: 'label-index'};
          if (index.color) {
            var m = index.color.match (/#(..)(..)(..)/);
            var r = parseInt ("0x" + m[1]);
            var g = parseInt ("0x" + m[2]);
            var b = parseInt ("0x" + m[3]);
            var y = 0.299 * r + 0.587 * g + 0.114 * b;
            var c = y > 127 + 64 ? 0 : 255;
            item.style = 'color:rgb('+c+','+c+','+c+');background-color:'+index.color;
            item['class'] += ' colored';
          }
          var e = tm.createFromTemplate ('span', item);
          while (e.firstChild) this.appendChild (e.firstChild);
        });
      });
    }, // grRender
  },
}); // <gr-index-list>

defineElement ({
  name: 'gr-select-index',
  props: {
    pcInit: function () {
      var val = this.value; // or undefined
      Object.defineProperty (this, 'value', {
        get: () => val,
        set: function (v) {
          val = v;
          this.querySelectorAll ('select').forEach (_ => _.value = val);
        },
      });
      return GR.index.list ().then (list => {
        this.textContent = '';
        var select = document.createElement ('select');
        var filter = () => true;
        var type = this.getAttribute ('type');
        if (type === 'file' || type === 'image' || type === 'icon' || type === 'stamp') {
          filter = _ => {
            return _.index_type == 6 /* fileset */ && _.subtype === type;
          };
        } else if (type === 'blog') {
          filter = _ => {
            return _.index_type == 1;
          };
        }
        list = Object.values (list).filter (filter).sort ((a, b) => {
          return b.updated - a.updated;
        });
        if (this.hasAttribute ('optional')) {
          var opt = document.createElement ('option');
          opt.value = '';
          opt.label = this.getAttribute ('optional');
          select.appendChild (opt);
        }
        if (list.length) {
          list.forEach (idx => {
            var opt = document.createElement ('option');
            opt.value = idx.index_id;
            opt.label = idx.title;
            select.appendChild (opt);
          });
        } else {
          if (!select.firstChild) {
            var opt = document.createElement ('option');
            opt.label = this.getAttribute ('empty');
            opt.value = '';
            select.appendChild (opt);
          }
        }
        select.value = val;
        select.onchange = () => val = select.value;
        if (select.selectedIndex === -1) {
          select.selectedIndex = 0;
          if (select.selectedIndex !== -1) {
            val = select.value;
            setTimeout (() => {
              this.dispatchEvent (new Event ('change', {bubbles: true}));
            }, 0);
          }
        }
        this.appendChild (select);
      });
    }, // pcInit
    pcModifyFormData: function (fd) {
      var name = this.getAttribute ('name');
      if (!name) return;
      fd.append (name, this.value || '');
    }, // pcModifyFormData
  },
}); // <gr-select-index>

GR.object = {};

GR.object.get = function (objectId, opts) {
  if (!opts.revisionId && !opts.reload) {
    var v = GR._objects[objectId];
    if (v) {
      var needFetch = false;
      if (opts.withTitle && !v.hasTitle) needFetch = true;
      if (opts.withData && !v.hasData) needFetch = true;
      if (opts.withSearchData && !v.hasSearchData) needFetch = true;
      var age = performance.now () - v.fetched;
      if (age > 60*60*1000) {
        needFetch = true;
      } else if (age > 60*1000 && opts.withData) {
        needFetch = true;
      }
      if (!needFetch) {
        return Promise.resolve (v.object);
      }
    }
  }
  return gFetch ('o/get.json?object_id=' + objectId
                     + (opts.withTitle ? '&with_title=1' : '')
                     + (opts.withData ? '&with_data=1' : '')
                     + (opts.withSearchData ? '&with_snippet=1' : '')
                     + (opts.revisionId ? '&object_revision_id=' + encodeURIComponent (opts.revisionId) : ''), {}).then (json => {
    var object = json.objects[objectId];
    if (object) {
      if (!object.data) object.data = {};
      if (!opts.revisionId) {
        GR.object._cache (object, {
          hasData: opts.withData, hasTitle: opts.withData,
          hasSearchData: opts.withSearchData,
        });
      } // !opts.revisionId
      return object;
    } else {
      throw new Error ('Object not found');
    }
  });
}; // GR.object.get

// XXX cache eviction
GR.object._cache = function (object, info) {
  var objectId = object.object_id;
  var v = {object: object, fetched: performance.now ()};
  if (GR._objects[objectId]) {
    if (GR._objects[objectId].object.updated === object.updated) {
      v = GR._objects[objectId];
      if (!v.object.data) v.object.data = {};
      // v.fetched
      for (var k in object) {
        if (k === 'data') {
          for (var kk in object.data) {
            v.object.data[kk] = object.data[kk];
          }
        } else {
          v.object[k] = object[k];
        }
      }
    }
  }
  GR._objects[objectId] = v;
  if (info.hasData) v.hasData = true;
  if (info.hasTitle) v.hasTitle = true;
  if (info.hasSearchData) v.hasSearchData = true;
}; // GR.object._cache

defineElement ({
  name: 'gr-create-object',
  props: {
    pcInit: function () {
      this.setAttribute ('formcontrol', '');
    }, // pcInit
    pcModifyFormData: function (fd) {
      var name = this.getAttribute ('name');
      if (!name) return;
      return gFetch ('o/create.json', {post: true}).then (function (json) {
        fd.append (name, json.object_id);
      });
    }, // pcModifyFormData
  },
}); // <gr-create-object>

(() => {

  var e = document.createElementNS ('data:,pc', 'loader');
  e.setAttribute ('name', 'groupIndexLoader');
  e.pcHandler = function (opts) {
    var indexId = this.getAttribute ('loader-indexid');
    var indexType = this.getAttribute ('loader-indextype');
    var withData = this.hasAttribute ('loader-withdata');
    var url = (document.documentElement.getAttribute ('data-group-url') || '') + '/o/get.json?index_id=' + encodeURIComponent (indexId) + (withData ? '&with_data=1' : '&with_title=1&with_snippet=1');
    if (opts.ref) url += '&ref=' + encodeURIComponent (opts.ref);
    var limit = this.getAttribute ('loader-limit') || opts.limit;
    if (limit) url += '&limit=' + encodeURIComponent (limit);
    // XXX cache
    return fetch (url, {
      credentials: "same-origin",
      referrerPolicy: 'same-origin',
    }).then ((res) => {
      if (res.status !== 200) throw res;
      return res.json ();
    }).then ((json) => {
      var list = Object.values (json.objects).sort ((a, b) => {
        return b.timestamp - a.timestamp;
      }).map (_ => {
        GR.object._cache (_, {
          hasData: withData, hasTitle: true, hasSearchData: !withData,
        });
        return {
          url: (indexType == 2 /* wiki */ ? '/g/'+_.group_id+'/i/'+indexId+'/wiki/'+encodeURIComponent (_.title)+'#' + _.object_id : '/g/'+_.group_id+'/o/'+_.object_id+'/'),
          object: _,
        };
      });
      var hasNext = json.next_ref && opts.ref !== json.next_ref; // backcompat
      return {
        data: list,
        prev: {ref: json.prev_ref, has: json.has_prev, limit: limit},
        next: {ref: json.next_ref, has: json.has_next || hasNext, limit: limit},
      };
    }).catch (e => {
      if (e instanceof Response && e.status === 403) {
        throw GR.Error.handle403 (e);
      }
      throw e;
    });
  };
  document.head.appendChild (e);

  var e = document.createElementNS ('data:,pc', 'loader');
  e.setAttribute ('name', 'groupCommentLoader');
  e.pcHandler = function (opts) {
    var url = (document.documentElement.getAttribute ('data-group-url') || '') + '/o/get.json?with_data=1';
    var objectId = this.getAttribute ('loader-parentobjectid');
    if (objectId) {
      url += '&parent_object_id=' + encodeURIComponent (objectId);
    } else {
      url += '&parent_wiki_name=' + encodeURIComponent (this.getAttribute ('loader-parentwikiname'));
      url += '&index_id=' + encodeURIComponent (this.getAttribute ('loader-indexid'));
    }
    if (opts.ref) url += '&ref=' + encodeURIComponent (opts.ref);
    var limit = this.getAttribute ('loader-limit') || opts.limit;
    if (limit) url += '&limit=' + encodeURIComponent (limit);
    // XXX cache
    return fetch (url, {
      credentials: "same-origin",
      referrerPolicy: 'same-origin',
    }).then ((res) => {
      if (res.status !== 200) throw res;
      return res.json ();
    }).then ((json) => {
      var list = Object.values (json.objects).sort ((a, b) => {
        return b.timestamp - a.timestamp;
      }).map (_ => {
        GR.object._cache (_, {
          hasData: true, hasTitle: true,
        });
        return {
          object: _,
        };
      });
      var hasNext = json.next_ref && opts.ref !== json.next_ref; // backcompat
      return {
        data: list,
        prev: {ref: json.prev_ref, has: json.has_prev, limit: limit},
        next: {ref: json.next_ref, has: json.has_next || hasNext, limit: limit},
      };
    }).catch (e => {
      if (e instanceof Response && e.status === 403) {
        throw GR.Error.handle403 (e);
      }
      throw e;
    });
  };
  document.head.appendChild (e);

  var e = document.createElementNS ('data:,pc', 'templateselector');
  e.setAttribute ('name', 'grCommentObjectTemplateSelector');
  e.pcHandler = function (templates, obj) {
    var object = obj.object;
    if (object.data.body_type == 3 /* data */) {
      if (object.data.body_data.hatena_star) {
        return templates.empty;
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
    } else if (object.data.body_type == 2 /* plaintext */) {
      return templates.plaintextbody;
    }
    return templates[""];
  };
  document.head.appendChild (e);
  
}) ()

defineElement ({
  name: 'gr-index-viewer',
  props: {
    pcInit: function () {
      var selects = GR._findPointedElement (this, 'select');
      selects.forEach (select => {
        select.addEventListener ('change', () => {
          this.grSetIndex (select.value);
        });
        this.grSetIndex (select.value);
      });
    }, // pcInit
    grSetIndex: function (indexId) {
      if (indexId == null || indexId === '') {
        this.textContent = '';
        return;
      }

      return $getTemplateSet ('gr-index-viewer-' + this.getAttribute ('type')).then (tm => {
        var e = tm.createFromTemplate ('panel-main', {index_id: indexId});
        this.textContent = '';
        this.appendChild (e);
        this.onclick = (ev) => {
          var e = ev.target;
          while (e && e.localName !== 'button') {
            e = e.parentNode;
          }
          if (!e) return;
          var ev = new Event ('grSelectObject', {bubbles: true});
          ev.grObjectURL = e.value;
          this.dispatchEvent (ev);
        };
      });
    }, // grSetIndex
  },
}); // <gr-index-viewer>

GR.wiki = {};

GR.wiki.url = function (indexId, wikiName) {
  var group = GR._state.group;
  if (!group) throw new DOMException ('Group info not found', 'InvalidStateError');
  if (indexId === group.default_wiki_index_id) {
    return '/g/'+group.group_id+'/wiki/'+encodeURIComponent (wikiName);
  } else {
    return '/g/'+group.group_id+'/i/'+indexId+'/wiki/'+encodeURIComponent (wikiName);
  }
}; // GR.wiki.url

defineElement ({
  name: 'gr-account',
  fill: 'contentattribute',
  props: {
    pcInit: function () {
      this.grRender ();
    }, // pcInit
    grRender: function () {
      if (this.hasAttribute ('self')) {
        return GR.account.info ().then (account => {
          $fill (this, account);
        });
      } else if (this.hasAttribute ('value')) {
        return GR.account.get (this.getAttribute ('value')).then (account => {
          $fill (this, account);
        });
      }
    }, // grRender
  },
}); // <gr-account>

defineElement ({
  name: 'gr-account-list',
  fill: 'idlattribute',
  props: {
    pcInit: function () {
      this.grValue = Object.keys (this.value || {});
      if (this.grValue) Promise.resolve ().then (() => this.grRender ());
      Object.defineProperty (this, 'value', {
        set: function (v) {
          this.grValue = Object.keys (v || {});
          Promise.resolve ().then (() => this.grRender ());
        },
      });
    }, // pcInit
    grRender: function () {
      return $getTemplateSet ('gr-account-list-item').then (tm => {
        this.textContent = '';

        this.grValue.sort ((a, b) => {
          return a - b;
        }).forEach (accountId => {
          var e = tm.createFromTemplate ('span', {account_id: accountId});
          while (e.firstChild) this.appendChild (e.firstChild);
        });
      });
    }, // grRender
  },
}); // <gr-account-list>

defineElement ({
  name: 'gr-account-dialog',
  props: {
    pcInit: function () {
      this.grShow ();
    }, // pcInit
    grShow: function () {
      var backdrop = document.createElement ('gr-backdrop');
      var iframe = document.createElement ('iframe');
      iframe.className = 'dialog';
      iframe.src = '/account/login?next='+encodeURIComponent (new URL ('/account/login?done=1', location.href));
      backdrop.appendChild (iframe);
      this.appendChild (backdrop);
      var listener = ev => {
        if (ev.origin === location.origin &&
            ev.data.grAccountUpdated) {
          this.grClose ();
          GR.account.check ({force: true, source: 'logindone'});
          if (window.BroadcastChannel)
          new BroadcastChannel ('grAccount').postMessage ({grAccountUpdated: true});
          if (!GR._state.group && GR._state.navigatePartition === 'group') location.reload ();
        }
      };
      window.addEventListener ('message', listener);
      this.grClose = () => {
        this.remove ();
        window.removeEventListener ('message', listener);
        this.grClose = () => {};
      };
    }, // grShow
    grClose: function () {},
  },
}); // <gr-account-dialog>

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
          obj.wiki = {name: wikiName, url: GR.wiki.url (indexId, wikiName)};
          return Promise.all ([
            ts,
            $getTemplateSet ('gr-menu-wiki'),
            GR.group.info ().then (_ => obj.group = _),
            GR.index.info (indexId).then (_ => obj.index = _),
          ]);
        } else if (type === 'dashboard') {
          return Promise.all ([
            ts,
            $getTemplateSet ('gr-menu-dashboard'),
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

GR.dashboard = {_state: {}};

GR.dashboard._groupMembers = function (groupId) {
  if (!GR.dashboard._state.getGroupMembers) GR.dashboard._state.getGroupMembers = {};
  if (GR.dashboard._state.getGroupMembers[groupId]) return GR.dashboard._state.getGroupMembers[groupId];
  
  var map = {};
  var get = (ref) => {
    var r = '';
    if (ref) r = '?ref=' + encodeURIComponent (ref);
    return fetch ('/g/'+groupId+'/members/list.json' + r, {}).then (res => {
      if (res.status !== 200) throw res;
      return res.json ();
    }).then (json => {
      Object.values (json.members).forEach (_ => {
        map[_.account_id] = _;
        _.group_id = groupId;
      });
      if (json.has_next) {
        return get (json.next_ref);
      }
    }).catch (e => {
      if (e instanceof Response && e.status === 403) {
        throw GR.Error.handle403 (e);
      }
      throw e;
    });
  }; // get
  return GR.dashboard._state.getGroupMembers[groupId] = get (null).then (_ => {
    return map;
  });
}; // GR.dashboard._groupMembers

GR.dashboard._groupObject = function (groupId, objectId) {
  if (!GR.dashboard._state.getGroupObjects) GR.dashboard._state.getGroupObjects = {};
  if (!GR.dashboard._state.getGroupObjects[groupId]) GR.dashboard._state.getGroupObjects[groupId] = {};
  if (GR.dashboard._state.getGroupObjects[groupId][objectId]) return GR.dashboard._state.getGroupObjects[groupId][objectId];

  var fd = new FormData;
  var get = () => {
    return new Promise (ok => {
      setTimeout (ok, 500);
    }).then (() => {
      delete GR.dashboard._state.getGroupObjects[groupId].current;
      return fetch ('/g/'+groupId+'/o/get.json?with_title=1&with_snippet=1', {method: 'POST', body: fd});
    }).then ((res) => {
      if (res.status !== 200) throw res;
      return res.json ();
    }).then (function (json) {
      return json.objects;
    }).catch (e => {
      if (e instanceof Response && e.status === 403) {
        throw GR.Error.handle403 (e);
      }
      throw e;
    });
  }; // get
  return GR.dashboard._state.getGroupObjects[groupId][objectId] = Promise.resolve ().then (() => {
    if (GR.dashboard._state.getGroupObjects[groupId].current) {
      GR.dashboard._state.getGroupObjects[groupId].current.fd.append ('object_id', objectId);
    } else {
      fd.append ('object_id', objectId);
      GR.dashboard._state.getGroupObjects[groupId].current = get ();
      GR.dashboard._state.getGroupObjects[groupId].current.fd = fd;
    }
    return GR.dashboard._state.getGroupObjects[groupId].current;
  }).then (objects => {
    return objects[objectId];
  });
}; // GR.dashboard._groupObject

GR.dashboard._groupList = function () {
  if (GR.dashboard._state.getGroupList) return GR.dashboard._state.getGroupList;
  
  var list = [];
  var get = (ref) => {
    var r = '';
    if (ref) r = '?ref=' + encodeURIComponent (ref);
    return fetch ('/my/groups.json' + r, {}).then (res => {
      if (res.status !== 200) throw res;
      return res.json ();
    }).then (json => {
      Object.values (json.groups).forEach (_ => {
        list.push (_);
      });
      if (json.has_next) {
        return get (json.next_ref);
      }
    }).catch (e => {
      if (e instanceof Response && e.status === 403) {
        throw GR.Error.handle403 (e);
      }
      throw e;
    });
  }; // get
  return GR.dashboard._state.getGroupList = get (null).then (_ => {
    list.forEach (g => {
      if (g.user_status == 1 && g.owner_status == 1) {
        if (g.member_type == 2) {
          g.status = 'owner';
        } else if (g.member_type == 1) {
          g.status = 'member';
        } else { // error
          g.status = 'member_type ' + g.member_type;
        }
      } else if (g.user_status == 2 && g.owner_status == 1) {
        g.status = 'invited';
      } else { // error
        g.status = 'user_status ' + g.user_status + ', owner_status ' + g.owner_status;
      }
      if (!g.default_index_id) g["hidden-unless-has-default-index"] = "hidden";
    });
    return list;
  });
}; // GR.dashboard._groupList

(() => {

  var e = document.createElementNS ('data:,pc', 'loader');
  e.setAttribute ('name', 'dashboardGroupListLoader');
  e.pcHandler = function (opts) {
    return GR.dashboard._groupList ().then (groups => {
      return {
        data: groups.sort ((a, b) => b.updated - a.updated),
      };
    });
  };
  document.head.appendChild (e);
  
}) ();

defineElement ({
  name: 'gr-dashboard-item',
  fill: 'contentattribute',
  props: {
    pcInit: function () {
      new MutationObserver (() => this.grRender ()).observe
          (this, {attributes: true, attributeFilter: ['type', 'groupid', 'value']});
      return Promise.resolve ().then (() => this.grRender ());
    }, // pcInit
    grRender: function () {
      return Promise.resolve ().then (() => {
        var type = this.getAttribute ('type');
        var value = this.getAttribute ('value');
        var groupId = this.getAttribute ('groupid');
        if (type === 'object') {
          if (!value || !groupId) return null;
          return GR.dashboard._groupObject (groupId, value);
        } else if (type === 'account') {
          if (!value || !groupId) return null;
          return GR.dashboard._groupMembers (groupId).then (members => {
            return members[value];
          });
        } else if (type === 'group') {
          if (!value) return null;
          return GR.dashboard._groupList ().then (groups => {
            for (var i = 0; i < groups.length; i++) {
              if (groups[i].group_id == value) {
                return groups[i];
              }
            }
            return null;
          });
        } else {
          return null;
        }
      }).then (_ => {
        $fill (this, _ || {});
      });
    }, // grRender
  },
}); // <gr-dashboard-item>

defineElement ({
  name: 'form',
  is: 'invitation-accept',
  props: {
    pcInit: function () {
      return fetch ('/my/info.json', {credentials: 'same-origin', referrerPolicy: 'origin'}).then (function (res) {
        return res.json ();
      }).then ((json) => {
        if (json.account_id) {
          this.querySelectorAll ('.login-button').forEach (function (e) { e.hidden = true });
          this.querySelectorAll ('.save-button').forEach (function (e) { e.hidden = false });
          document.querySelectorAll ('.no-account').forEach (function (e) { e.hidden = true });
        }
      });
    }, // pcInit
  },
}); // <form is=invitation-accept>

function $$c (n, s) {
  return Array.prototype.filter.call (n.querySelectorAll (s), function (e) {
    var f = e.parentNode;
    while (f) {
      if (f === n) break;
      if (f.localName === 'gr-list-container' ||
          f.localName === 'edit-container' ||
          f.localName === 'list-query' ||
          f.localName === 'list-control' ||
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
      var fo = {
        credentials: "same-origin",
        method: method,
        body: body,
        referrerPolicy: 'origin',
      };
      if (opts.reload) fo.cache = "reload";
      var ff = fetch (url, fo).then (function (res) {
        if (res.status !== 200) throw res;
        if (opts.asStage) opts.as.stageEnd (opts.asStage);
        return res.json ();
      });
      if (opts.ignoreError) {
        ff = ff.catch (e => {
          console.log (e);
        });
      }
      return ff;
    }
  }).catch (e => {
    if (e instanceof Response && e.status === 403) {
      throw GR.Error.handle403 (e);
    }
    throw e;
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

defineElement ({
  name: 'gr-html-viewer',
  fill: 'idlattribute',
  props: {
    pcInit: function () {
      var e = document.createElement ('sandboxed-viewer');
      if (this.hasAttribute ('seamlessheight')) e.setAttribute ('seamlessheight', '');
      this.grMode = this.getAttribute ('mode') || 'viewer';
      if (this.grMode === 'viewer') {
        e.setAttribute ('allowsandbox', 'allow-popups');
      }
      this.appendChild (e);
      this.grViewer = e;

      return $paco.upgrade (e).then (() => e.ready).then (() => this.grInit ());
    }, // pcInit
    grInit: function () {
      var initialValue = this.value;
      if (initialValue) this.grSetObject (initialValue);
      Object.defineProperty (this, 'value', {
        set: function (v) {
          this.grSetObject (v);
        },
      });

      this.grViewer.pcRegisterMethod ('navigate', args => {
        if (this.grMode === 'viewer') {
          GR.navigate.go (args.url, {});
        }
      });
      this.grViewer.pcRegisterMethod ('getStarData', args => {
        var results = {};
        var wait = [];
        args.objectIds.forEach (objectId => {
          wait.push (GR.object.get (objectId, {withData: true}).then (object => {
            results[objectId] = (object.data.body_data || {}).hatena_star; // or undefined
          }));
        });

        return Promise.all (wait).then (_ => results);
      });
      
      var installMinimum = this.grViewer.pcInvoke ('pcEval', {code: `
        pcRegisterMethod ('appendHead', (args) => {
          var e = document.createElement ('div');
          e.innerHTML = args.value;
          while (e.firstChild) {
            document.head.appendChild (e.firstChild);
          }
        });
        pcRegisterMethod ('setBody', (args) => {
          var fragment = document.createElement ('div');
          fragment.innerHTML = args.body;

          document.documentElement.setAttribute ('data-group-url', args.group_url);

          var imported = args.imported_sites || [];
          if (imported.length) {
            Array.prototype.forEach.call (fragment.querySelectorAll ('a[href], link[href], img[src], iframe[src]'), function (e) {
              ["href", "src"].forEach (function (a) {
                var value = e[a]; // canonicalized URL
                if (!value) return;
                var matchedValue = value.replace (/^https?:/, '');
                for (var i = 0; i < imported.length; i++) {
                  var importedPrefix = imported[i].replace (/^https?:/, '');
                  if (matchedValue.substring (0, importedPrefix.length) === importedPrefix) {
                    e.setAttribute (a, document.documentElement.getAttribute ('data-group-url') + '/imported/' + encodeURIComponent (value) + '/go');
                    return;
                  }
                }
              });
            });
          } // imported.length

          var setStarShadow = (e, data) => {
            var sr = e.attachShadow ({mode: 'open'});

            var link = document.createElement ('link');
            link.rel = 'stylesheet';
            link.href = '/css/hatenastar.css';
            sr.appendChild (link);

            sr.appendChild (document.createElement ('slot'));
            var f = document.createElement ('hatena-star');
            if (document.body.isContentEditable) {
              f.style.pointerEvents = 'none';
              f.onclick = function () { return false };
            }

            data.sort (function (a, b) {
              return b[1] - a[1] || b[2] - a[2];
            }).forEach (star => {
              var a = document.createElement ('a');
              a.href = 'https://profile.hatena.ne.jp/'+star[0]+'/';
              a.setAttribute ('referrerpolicy', 'no-referrer');
              a.title = star[0];
              if (star[3].length) a.title += ' ' + star[3];
              a.className = 'star-type-' + star[1];
              a.innerHTML = '<span>★</span><img class=hatena-user-icon><hatena-star-count></hatena-star-count>';
              var img = a.childNodes[1];
              img.alt = star[0];
              img.referrerpolicy = 'no-referrer';
              img.src = 'https://cdn1.www.st-hatena.com/users/'+star[0].substring (0, 2)+'/'+star[0]+'/profile.gif';
              var sc = a.lastChild;
              sc.className = 'star-count-' + star[2];
              sc.textContent = star[2];
              a.onclick = () => {
                pcInvoke ('navigate', {url: a.href});
                return false;
              };
              f.appendChild (a);
            });

            sr.appendChild (f);
          }; // setStarShadow
          
          fragment.querySelectorAll ('hatena-html[starmap]').forEach ((e) => {
            var hatenaStarMap = {};
            var values = e.getAttribute ('starmap').split (/\\s+/);
            while (values.length) {
              var id = values.shift ();
              var objectId = values.shift ();
              hatenaStarMap[id] = objectId;
            }

            var starElements = new Map;
            e.querySelectorAll ('.section > h3.title > a[name], .section > h3[id], section > h1[data-hatena-timestamp]').forEach (_ => {
              if (_.localName === 'a') { // Hatena Group formatter
                var h = _.parentNode;
                var objectId = hatenaStarMap[_.name];
                if (objectId) {
                  //h.setAttribute ('data-debug-starelement', objectId);
                  starElements.set (h, objectId);
                }
              } else { // Formatter.hatena
                var objectId = hatenaStarMap[_.id];
                if (objectId) {
                  //_.setAttribute ('data-debug-starelement', objectId);
                  starElements.set (_, objectId);
                }
              }
            });

            if (starElements.size) {
              return pcInvoke ('getStarData', {
                objectIds: Array.from (starElements.values ()),
              }).then (starData => {
                Array.from (starElements.keys ()).forEach (e => {
                  var objectId = starElements.get (e);
                  var data = starData[objectId] || [];
                  if (data.length) setStarShadow (e, data);
                });
              });
            }
          });

          document.body.textContent = '';
          document.body.setAttribute ('data-source-type', args.body_source_type || 0);
          while (fragment.firstChild) {
            document.body.appendChild (fragment.firstChild);
          }
        });

        window.addEventListener ('click', (ev) => {
          var n = ev.target;
          while (n && !(n.localName === 'a' || n.localName === 'area')) {
            n = n.parentElement;
          }
          if (n &&
              (n.protocol === 'https:' || n.protocol === 'http:') &&
              (n.target === '' || n.target === '_blank') &&
              !n.hasAttribute ('is')) {
            pcInvoke ('navigate', {url: n.href});
            ev.preventDefault ();
          }
        }); // click
      `}); // installMinimum

      installMinimum.then (() => {
        var div = document.createElement ('div');

        var base = document.createElement ('base');
        base.href = location.href;
        div.appendChild (base);

        document.querySelectorAll ('link.body-css').forEach (e => {
          var link = document.createElement ('link');
          link.rel = 'stylesheet';
          link.href = e.href;
          div.appendChild (link);
        });

        return this.grViewer.pcInvoke ('appendHead', {value: div.innerHTML});
      });

      // XXX if not editable
      installMinimum.then (() => {
        this.grViewer.pcInvoke ('pcEval', {code: `
          var over = false;
          window.addEventListener ('mouseover', ev => {
            var parent = ev.target;
            while (parent) {
              if (parent.localName === 'a' ||
                  parent.localName === 'area') {
                break;
              } else {
                parent = parent.parentNode;
              }
            }
            if (parent &&
                (parent.localName === 'a' || parent.localName === 'area')) {
              pcInvoke ('linkSelected', {
                url: parent.href,
                top: parent.offsetTop, left: parent.offsetLeft,
                width: parent.offsetWidth, height: parent.offsetHeight,
              });
              over = true;
            } else {
              if (over) {
                pcInvoke ('linkSelected', {});
                over = false;
              }
            }
          });
        `});
        this.grViewer.pcRegisterMethod ('linkSelected', args => {
          GR.tooltip.showURL (args.url, {
            top: this.offsetTop + args.top + args.height,
            left: this.offsetLeft + args.left,
          });
        });
      });

      if (this.hasAttribute ('checkboxeditable')) { // XXX and not editable
        installMinimum.then (() => {
          this.grViewer.pcRegisterMethod ('checkboxChanged', args => {
            clearTimeout (this.grSaveTimer);
            this.grSaveTimer = setTimeout (() => this.grSave (), 10000);
          });
          this.grViewer.pcInvoke ('pcEval', {code: `
            window.addEventListener ('change', ev => {
              var e = ev.target;
              if (e.type === 'checkbox' &&
                  e.localName === 'input') {
                if (e.checked !== e.defaultChecked) {
                  e.defaultChecked = e.checked;

                  var f = e.parentNode;
                  while (f) {
                    if (f.localName === 'li') break;
                    f = f.parentNode;
                  }
                  if (f) {
                    if (e.checked) {
                      f.setAttribute ('data-checked', '');
                    } else {
                      f.removeAttribute ('data-checked');
                    }
                  }
                  pcInvoke ('checkboxChanged', {});
                }
              }
            });
          `}); // onchange
        });
      } // checkboxeditable
      
      return installMinimum;
    }, // grInit
    grSave: function () {
      if (!this.grEditableData) return;

      var c = this.parentNode;
      while (c) {
        if (c.localName === 'article') break;
        c = c.parentNode;
      }
      if (c) c = c.querySelector ('gr-article-status');
      var as;
      if (c) as = c.pcActionStatus ();
      if (as) as.start ({stages: ['saver']});
      if (as) as.stageStart ('saver');
      var objectId = this.getAttribute ('objectid');
      return this.grViewer.pcInvoke ('pcEval', {code: "return document.body.innerHTML"}).then (body => {
        var data = this.grEditableData;
        data.body = body;
        data.body_source_type = 0; // WYSIWYG
        delete data.body_source;
        var fd = new FormData;
        fd.append ('body', data.body);
        fd.append ('body_type', data.body_type);
        return gFetch ('o/'+objectId+'/edit.json', {post: true, formData: fd});
      }).then (() => {
        if (as) as.end ({ok: true});
        GR.object.get (objectId, {reload: true, withData: true}); // XXX background
      }, e => {
        if (as) as.end ({error: e});
        else throw e;
      });
    }, // grSave
    grSetObject: function (data) {
      if (this.hasAttribute ('checkboxeditable') &&
          data.body_type == 1 /* html */ &&
          (data.body_source_type || 0) == 0 /* WYSIWYG */) {
        this.grEditableData = data;
      } else {
        delete this.grEditableData;
      }
      return GR.group.importedSites ().then (sites => {
        return this.grViewer.pcInvoke ('setBody', {
          body: data.body,
          body_source_type: data.body_source_type,
          imported_sites: sites,
          group_url: document.documentElement.getAttribute ('data-group-url'),
        });
      });
    }, // grSetObject
  },
}); // <gr-html-viewer>

defineElement ({
  name: 'gr-article-status',
  pcActionStatus: true,
  props: {
    pcInit: function () { },
  },
}); // <gr-article-status>

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
    } else if (field.localName === 'gr-account' ||
               field.localName === 'gr-stars') {
      field.setAttribute ('value', value);
    } else if (field.localName === 'gr-object-author') {
      field.value = value;
    } else if (field.localName === 'unit-number') {
      field.setAttribute ('value', value);

    } else if (field.localName === 'only-if') {
      var matched = true;
      var cond = field.getAttribute ('cond');
      if (cond === '==0') {
        if (value != 0) matched = false;
      } else if (cond === '!=0') {
        if (value == 0) matched = false;
      }
      field.hidden = ! matched;

    } else if (field.localName === 'gr-html-viewer') {
      field.value = value;
      field.setAttribute ('objectid', object.object_id);
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
  $$c (el, 'form[data-child-form], form[data-next~=markAncestorArticleDeleted]').forEach (function (field) {
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
  $$c (el, '[data-action-template]').forEach (function (field) {
    field.setAttribute ('action', field.getAttribute ('data-action-template').replace (/\{([^{}]+)\}/g, function (_, k) {
      return object[k];
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
    } else if (field.localName === 'gr-account-list') {
      field.value = value;
    } else if (field.localName === 'gr-index-list') {
      field.value = value;
    } else if (field.localName === 'iframe') {
      initIframeViewer (field, object, opts.importedSites);
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
    } else if (field.localName === 'enum-value') {
      field.setAttribute ('value', value);
    } else if (field.localName === 'gr-count') {
      field.setAttribute ('value', value);
      var maxKey = field.getAttribute ('data-all-data-field');
      if (maxKey) {
        var max = object.data ? object.data[maxKey] : null;
        if (max) field.setAttribute ('all', max);
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

function initIframeViewer (field, object, importedSites) {
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
          } else if (ev.data.type === 'getObjectWithData') {
            GR.object.get (ev.data.value, {withData: true}).then (function (object) {
              ev.ports[0].postMessage (object);
            });
          } else if (ev.data.type === 'linkSelected') {
            GR.tooltip.showURL (ev.data.url, {
              top: field.offsetTop + ev.data.top + ev.data.height,
              left: field.offsetLeft + ev.data.left,
            });
          } else if (ev.data.type === 'linkClicked') {
            GR.navigate.go (ev.data.url, {
              ping: ev.data.ping,
            });
          }
        };
        field.onload = null;
      };
  mc.port2.postMessage ({type: "setCurrentValue",
                         valueSourceType: (object.data ? object.data.body_source_type : null),
                         importedSites: importedSites,
                         value: object.data.body});
} // initIframeViewer

defineElement ({
  name: 'iframe',
  is: 'gr-old-iframe-viewer',
  fill: 'idlattribute',
  props: {
    pcInit: function () {
      this.grValue = this.value;
      Object.defineProperty (this, 'value', {
        set: function (v) {
          this.grValue = v;
          Promise.resolve ().then (() => this.grRender ());
        },
      });
      Promise.resolve ().then (() => this.grRender ());
    }, // pcInit
    grRender: function () {
      if (!this.grValue) return;
      initIframeViewer (this, this.grValue, {/*XXX*/});
    }, // grRender
  },
}); // <iframe is=gr-old-iframe-viewer>

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

  $$c (form, 'gr-called-editor').forEach (_ => {
    _.grObjectCalled = object.data.called || {};
  });

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
  if (data.body_type == 2) { // plain text
    data.body_source = data.body;
    data.body_source_type = 4; // plain text
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
    } else if (data.body_source_type == 3 || // hatena
               data.body_source_type == 4) { // plain text
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
      $$c (f, 'iframe, textarea, gr-html-viewer').forEach (function (g) {
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
      } else if (ev.data.type === 'getObjectWithData') {
        GR.object.get (ev.data.value, {withData: true}).then (function (object) {
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
        } else if (data.body_source_type == 4) { // plain text
          return Formatter.autolink (data.body_source).then (body => {
            data.body = body;
          });
        } else {
          data.body = data.body_source;
        }
      }
    }
  }; // saver.textarea

  loader.preview = function () {
    var field = e.querySelector ('body-control-tab[name=preview] gr-html-viewer');
    field.value = data;
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
            if (f.localName === 'article-comments') {
              if (!item.grACFilled) {
                item.grACFilled = true;
                $fill (f, {object: object});
              }
              f.querySelectorAll ('details[is=gr-comment-form]').forEach (_ => {
                _.setAttribute ('data-parentobjectid', object.object_id);
                _.setAttribute ('data-threadid', object.data.thread_id);
                if (_.grObjectUpdated) {
                  _.grObjectUpdated (object);
                } else {
                  _.grObject = object;
                }
              });
            } else if (f.localName !== 'edit-container') {
              fillFields (el, item, f, object, {
                importedSites: opts.importedSites,
              });
            }
          });
          // XXX replace by templateselector
          if (object.user_status == 2) { // deleted
            item.classList.add ('deleted');
            item.querySelectorAll ('main').forEach (_ => {
              _.textContent = '(削除されました。)';
            });
          }
        }; // updateView
        item.addEventListener ('objectdataupdate', function (ev) {
          if (ev.grNewTodoState) object.data.todo_state = ev.grNewTodoState;
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
            w.push (GR.account.get (key).then (function (account) {
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
        if (attr === 'src-object_id') {
          var u = new URL (location.href);
          var rev = u.searchParams.get ('object_revision_id');
          if (rev) url += '&object_revision_id=' + encodeURIComponent (rev);
        }
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
      return Promise.all ([
        gFetch (url, {}),
        url.match (/o\/get.json/) ? GR.group.importedSites () : null,
      ]).then (([json, imported]) => {
        as.stageEnd ("load");
        if (imported) json.imported_sites = imported;
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
        var list = document.querySelector ('gr-list-container[src-index_id]');
        return Promise.resolve ().then (() => {
          if (list) {
            return gFetch ('o/get.json?with_data=1&object_id=' + objectId, {}).then (function (json) {
              return list.showObjects (json.objects, {prepend: true});
            });
          } else {
            // XXX loadPrev ({})
            document.querySelectorAll ('list-container.search-result').forEach (_ => _.load ({}));
          }
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
  $$ (form, 'gr-called-editor').forEach (function (control) {
    control.pcModifyFormData (fd);
  });
  return Promise.all (ps).then (function () {
    opts.actionStatus.stageEnd ("dataset");
    opts.actionStatus.stageStart ("create");
    var objectId = article.getAttribute ('data-object');
    if (objectId) {
      return objectId;
    } else {
      return gFetch ('o/create.json', {post: true}).then (function (json) {
        fd.append ('is_new_object', 1);
        return json.object_id;
      });
    }
  }).then (function (objectId) {
    opts.actionStatus.stageEnd ("create");
    opts.actionStatus.stageStart ("edit");
    return gFetch ('o/' + objectId + '/edit.json', {post: true, formData: fd}).then (function (json) {
      c.forEach (function (_) { _ () });
      object.updated = (new Date).valueOf () / 1000;
      if (json.called) object.data.called = json.called;
      opts.actionStatus.stageEnd ("edit");
      return objectId;
    });
  }).then ((objectId) => {
    $$ (form, 'gr-called-editor').forEach (function (control) {
      control.grObjectCalled = object.data.called;
      control.grReset ();
    });
    return objectId;
  });
} // saveObject

(() => {

  var e = document.createElementNS ('data:,pc', 'saver');
  e.setAttribute ('name', 'objectSaver');
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
    }).catch (e => {
      if (e instanceof Response && e.status === 403) {
        throw GR.Error.handle403 (e);
      }
      throw e;
    });
    // XXX notify object update
  };
  document.head.appendChild (e);

  var e = document.createElementNS ('data:,pc', 'saver');
  e.setAttribute ('name', 'newObjectSaver');
  e.pcHandler = function (fd) {
    var todoState = fd.get ('todo_state');
    fd.delete ('todo_state');
    return Promise.resolve ().then (() => {
      if (fd.get ('body') !== '') {
        return gFetch ('o/create.json', {post: true}).then (json => {
          return gFetch ('o/' + json.object_id + '/edit.json', {post: true, formData: fd});
        });
      }
    }).then (() => {
      if (todoState) {
        var fd2 = new FormData;
        fd2.append ('todo_state', todoState);
        return gFetch ('o/' + fd.get ('parent_object_id') + '/edit.json', {post: true, formData: fd2}).then (() => {
          var ev = new Event ('objectdataupdate', {bubbles: true});
          ev.grNewTodoState = todoState;
          this.dispatchEvent (ev);
        });
      }
    });
    // XXX notify object update
  };
  document.head.appendChild (e);

  var def = document.createElementNS ('data:,pc', 'formvalidator');
  def.setAttribute ('name', 'commentFormValidator');
  def.pcHandler = (opts) => {
    if (opts.formData.get ('body') === '' &&
        !opts.formData.get ('todo_state')) {
      throw this.getAttribute ('data-gr-emptybodyerror');
    }
  };
  document.head.appendChild (def);
  
  var e = document.createElementNS ('data:,pc', 'formsaved');
  e.setAttribute ('name', 'reloadCommentList');
  e.pcHandler = function (args) {
    var e = this.parentNode;
    while (e && e.localName !== 'article-comments') {
      e = e.parentNode;
    }
    if (!e) return;
    e.querySelectorAll ('list-container[loader=groupCommentLoader]').forEach (_ => {
      // XXX loadPrev ()
      _.load ({});
    });
  }; // reloadCommentList
  document.head.appendChild (e);

  // XXX paco integration
  var e = document.createElementNS ('data:,pc', 'formsaved');
  e.setAttribute ('name', 'resetCalledEditor');
  e.pcHandler = function (args) {
    this.querySelectorAll ('gr-called-editor').forEach (_ => _.grReset ());
  }; // resetCalledEditor
  document.head.appendChild (e);

  var e = document.createElementNS ('data:,pc', 'formsaved');
  e.setAttribute ('name', 'grFocus');
  e.pcHandler = function (args) {
    setTimeout (() => {
      this.querySelectorAll (args.args[1]).forEach (_ => _.focus ());
    }, 100);
  }; // grFocus
  document.head.appendChild (e);

  // XXX replace by article reload ()
  var e = document.createElementNS ('data:,pc', 'formsaved');
  e.setAttribute ('name', 'markAncestorArticleDeleted');
  e.pcHandler = function (args) {
    var obj = this.parentObject;
    obj.user_status = 2; // deleted
    this.dispatchEvent (new Event ('objectdataupdate', {bubbles: true}));
  }; // markAncestorArticleDeleted
  document.head.appendChild (e);
  
  var e = document.createElementNS ('data:,pc', 'templateselector');
  e.setAttribute ('name', 'gr-object-author');
  e.pcHandler = function (templates, obj) {
    if (obj.author_hatena_id) {
      return templates.hatenauser;
    } else if (obj.author_name) {
      return templates.hatenaguest;
    } else if (obj.author_account_id) {
      return templates.account;
    } else {
      return templates[""];
    }
  }; // gr-object-author
  document.head.appendChild (e);
  
}) ();

defineElement ({
  name: 'gr-object-author',
  fill: 'idlattribute',
  templateSet: true,
  props: {
    pcInit: function () {
      this.grValue = this.value;
      if (this.grValue) Promise.resolve ().then (() => this.grSetValue ());
      Object.defineProperty (this, 'value', {
        set: function (v) {
          this.grValue = v;
          Promise.resolve ().then (() => this.grSetValue ());
        },
      });
      
      this.addEventListener ('pctemplatesetupdated', (ev) => {
        this.grTemplateSet = ev.pcTemplateSet;
        Promise.resolve ().then (() => this.grSetValue ());
      });
    }, // pcInit
    grSetValue: function () {
      if (!this.grTemplateSet || !this.grValue) return;

      var v = this.grValue;
      if (v.author_hatena_id) {
        v.author_hatena_id_2 = v.author_hatena_id.substring (0, 2);
      }

      var tm = this.grTemplateSet;
      var e = tm.createFromTemplate ('div', v);
      this.textContent = '';
      while (e.firstChild) this.appendChild (e.firstChild);
    }, // grSetValue
  },
}); // <gr-object-author>

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
    
    var cmd = template.getAttribute ('data-selectobject-command');
    if (cmd) {
      section.addEventListener ('grSelectObject', (ev0) => {
        var ev = new Event ('gruwaeditcommand', {bubbles: true});
        ev.data = {type: cmd, value: ev0.grObjectURL};
        section.dispatchEvent (ev);
      });
    }
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
    return {object_id: data.object_id};
  });
} // uploadFile

defineElement ({
  name: 'gr-uploader',
  props: {
    pcInit: function () {
      return $getTemplateSet ('gr-uploader').then (ts => {
        var e = ts.createFromTemplate ('div', {});
        this.textContent = '';
        while (e.firstChild) this.appendChild (e.firstChild);

        var subtype = this.getAttribute ('indexsubtype');
        this.querySelectorAll ('input[type=file]').forEach (_ => {
          if (subtype === 'image' ||
              subtype === 'icon' ||
              subtype === 'stamp') _.accept = 'image/*';
          _.onchange = () => {
            Array.prototype.forEach.call (_.files, (file) => this.grUploadFile (file)); 
            _.form.reset ();
          };
        });
        this.querySelectorAll ('button[is=gr-uploader-button]').forEach (_ => {
          _.onclick = () => this.grOpenDialog ();
        });
        
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
        this.ondragenter = (ev) => {
          targetted++;
          if (!setDropEffect (ev.dataTransfer)) {
            this.classList.add ('drop-target');
            return false;
          }
        };
        this.ondragover = (ev) => {
          return setDropEffect (ev.dataTransfer);
        };
        this.ondragleave = (ev) => {
          targetted--;
          if (targetted <= 0) {
            this.classList.remove ('drop-target');
          }
        };
        this.ondrop = (ev) => {
          this.classList.remove ('drop-target');
          targetted = 0;
          Array.prototype.forEach.call (ev.dataTransfer.files, (file) => {
            this.grUploadFile (file);
          });
          return false;
        };
      });
    }, // pcInit
    grOpenDialog: function () {
      this.querySelector ('input[type=file]').click ();
    }, // grOpenDialog
    grUploadFile: function (file) {
      var data = {
        file_name: file.name,
        file_size: file.size,
        mime_type: file.type,
        timestamp: file.lastModified / 1000,
        index_id: this.getAttribute ('indexid'),
      };
      var as;
      var list = this.querySelector ('gr-list-container');
      return list.showObjects ([data], {}).then (function (r) {
        var item = r.items[0];
        as = getActionStatus (item);
        as.start ({stages: ["create", "upload", "close", "show"]});
        return uploadFile (file, data, as);
      }).then (() => {
        as.stageStart ("show");
        var lists = GR._findPointedElement (this, 'list');
        lists.forEach (_ => {
          // XXX loadPrev
          _.load ({});
        });
      }).then (function () {
        as.end ({ok: true});
      }, function (error) {
        as.end ({ok: false, error: error});
      });
    }, // grUploadFile
  },
}); // <gr-uploader>

defineElement ({
  name: 'button',
  is: 'gr-download-img',
  props: {
    pcInit: function () {
      this.onclick = () => this.grDownload ();
    }, // pcInit
    grDownload: function () {
      var el = document.querySelector (this.getAttribute ('data-selector'));
      var a = document.createElement ('a');
      a.href = el.src;
      a.download = this.getAttribute ('data-filename') || '';
      document.body.appendChild (a);
      a.click ();
      a.remove ();
    }, // grDownload
  },
}); // <button is=gr-download-img>

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

stageActions.resetForm = function (args) {
  args.form.reset ();
}; // resetForm
stageActions.resetForm.stages = [];

stageActions.resetCallEditor = function (args) {
  args.form.querySelectorAll ('gr-called-editor').forEach (_ => _.grReset ());
}; // resetCallEditor
stageActions.resetCallEditor.stages = [];

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
  $$ (args.form, 'gr-called-editor[data-edit-created-object]').forEach (function (control) {
    control.pcModifyFormData (fd);
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
  
  if (form.getAttribute ('action') === 'javascript:' &&
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
    var urlPrefix = (document.documentElement.getAttribute ('data-group-url') || '') + '/';
    var url = urlPrefix + this.getAttribute ('src');
    var isSearch = this.hasAttribute ('loader-search');
    if (isSearch) {
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
    }).then ((res) => {
      if (res.status !== 200) throw res;
      return res.json ();
    }).then ((json) => {
      if (!this.hasAttribute ('key')) throw new Error ("|key| is not specified");
      json = json || {};

      var list = json[this.getAttribute ('key')];
      if (isSearch) {
        list = list.map (_ => {
          return {
            url: urlPrefix+'o/'+_.object_id+'/',
            object: _,
          };
        });
      }
      
      var hasNext = json.next_ref && opts.ref !== json.next_ref; // backcompat
      return {
        data: list,
        prev: {ref: json.prev_ref, has: json.has_prev, limit: opts.limit},
        next: {ref: json.next_ref, has: json.has_next || hasNext, limit: opts.limit},
      };
    }).catch (e => {
      if (e instanceof Response && e.status === 403) {
        throw GR.Error.handle403 (e);
      }
      throw e;
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
    }).catch (e => {
      if (e instanceof Response && e.status === 403) {
        throw GR.Error.handle403 (e);
      }
      throw e;
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
  
  var e = document.createElementNS ('data:,pc', 'formsaved');
  e.setAttribute ('name', 'groupReload');
  e.pcHandler = function (args) {
    return GR.navigate.go ('', {reload: true});
  }; // groupGo
  document.head.appendChild (e);

  var def = document.createElementNS ('data:,pc', 'formsaved');
  def.setAttribute ('name', 'reloadList');
  def.pcHandler = function (args) {
    document.querySelectorAll (args.args[1]).forEach (_ => {
      if (_.localName === 'gr-list-container') {
        _.reload ();
      } else {
        _.load ({});
      }
    });
  };
  document.head.appendChild (def);

  var e = document.createElementNS ('data:,pc', 'formsaved');
  e.setAttribute ('name', 'fill');
  e.pcHandler = function (args) {
    return args.json ().then ((json) => {
      document.querySelectorAll (args.args[1]).forEach (_ => {
        $fill (_, json);
        _.hidden = false;
      });
    });
  }; // fill
  document.head.appendChild (e);

}) ();

defineElement ({
  name: 'details',
  is: 'gr-comment-form',
  props: {
    pcInit: function () {
      this.grOpenHandler = _ => {
        if (this.hasAttribute ('open')) this.grOpen ();
      };
      this.addEventListener ('toggle', this.grOpenHandler);
    }, // pcInit
    grOpen: function () {
      if (this.grOpened) return;
      this.grOpened = true;
      this.removeEventListener ('toggle', this.grOpenHandler);
      delete this.grOpenHandler;
      this.addEventListener ('toggle', () => {
        if (this.hasAttribute ('open')) {
          this.querySelectorAll ('textarea[name=body]').forEach (_ => _.focus ());
        }
      });

      return $getTemplateSet ('gr-comment-form').then (ts => {
        var e = ts.createFromTemplate ('div', {
          parent_object_id: this.getAttribute ('data-parentobjectid'),
        });
        e.querySelectorAll ('gr-called-editor').forEach (_ => {
          _.setAttribute ('threadid', this.getAttribute ('data-threadid'));
        });
        while (e.firstChild) this.appendChild (e.firstChild);

        if (this.grObject) {
          this.grObjectUpdated (this.grObject);
          delete this.grObject;
        }
      });
    }, // grOpen
    grObjectUpdated: function (obj) {
      return GR.index.list ().then (indexList => {
        var indexIds = Object.keys (obj.data.index_ids || {});
        for (var i = 0; i < indexIds.length; i++) {
          var index = indexList[indexIds[i]];
          if (index && index.index_type == 3 /* todo */) {
            return true;
          }
        }
        return false;
      }).then (isTodo => {
        this.querySelectorAll ('[data-gr-if-parent-todo]').forEach (_ => {
          if (isTodo) {
            _.hidden = (_.value == obj.data.todo_state);
          } else {
            _.hidden = true;
          }
        });
      });
    }, // grObjectUpdated
  },
}); // <details is=gr-comment-form>

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
  name: 'gr-select-icon',
  props: {
    pcInit: function () {
      this.setAttribute ('formcontrol', '');
      return $getTemplateSet ('gr-select-icon').then (ts => {
        var e = ts.createFromTemplate ('div', {});
        this.textContent = '';
        while (e.firstChild) this.appendChild (e.firstChild);

        this.querySelectorAll ('gr-index-viewer').forEach (_ => {
          _.addEventListener ('click', (ev) => {
            ev.stopPropagation (); // cancel popup-menu click
          });
          _.addEventListener ('grSelectObject', (ev) => {
            this.grSetImage (ev.grObjectURL);
          });
        });
        this.querySelectorAll ('.generate-icon-button').forEach (_ => {
          _.hidden = ! this.hasAttribute ('generationtextselector');
          _.onclick = (ev) => this.grGenerate ();
        });
        this.querySelectorAll ('.reset-icon-button').forEach (_ => {
          _.onclick = (ev) => this.grSetImage (null);
        });

        this.grSetImage (null);
      });
    }, // pcInit
    grGenerate: function () {
      var defs = [
        {name: 'dark'},
        {name: 'light-1'},
        {name: 'light-2'},
      ];
      var def = defs[Math.floor (defs.length * Math.random ())];
      var bgs = ['●', '■', '★', '▲', '▼', '\u25B6', '\u25C0'];
      var bg = bgs[Math.floor (bgs.length * Math.random ())];
      var text = document.querySelector (this.getAttribute ('generationtextselector')).value;
      text = text.substring (Math.floor (text.length * Math.random ())).substring (0, 1);
      var style = getComputedStyle (document.documentElement);
      var canvas = document.createElement ('canvas');
      canvas.width = 160;
      canvas.height = 160;
      var ctx = canvas.getContext ('2d');
      ctx.textBaseline = 'middle';
      ctx.textAlign = 'center';
      ctx.font = '160px sans-serif';
      ctx.fillStyle = style.getPropertyValue ('--'+def.name+'-background-color');
      ctx.fillText (bg, 80, 80);
      ctx.font = '80px ' + style.getPropertyValue ('font-family');
      ctx.fillStyle = style.getPropertyValue ('--'+def.name+'-color');
      ctx.fillText (text, 80, 80);
      this.grSetImage (canvas);
    }, // grGenerate
    grSetImage: function (obj) { 
      delete this.grImageObjectURL;
      delete this.grImageObject;

      if (obj) {
        if (typeof obj === 'string') {
          this.grImageObjectURL = obj;
          this.querySelectorAll ('popup-menu > button img').forEach (_ => _.src = obj + 'image');
        } else {
          this.grImageObject = obj;
          this.querySelectorAll ('popup-menu > button img').forEach (_ => _.src = obj.toDataURL ());
        }
        return;
      }
      
      this.querySelectorAll ('popup-menu > button img').forEach (_ => _.src = this.getAttribute ('src'));
    }, // grSetURL
    pcModifyFormData: function (fd) {
      var name = this.getAttribute ('name');
      if (!name) return;
      if (this.grImageObject) {
        return new Promise (ok => {
          this.grImageObject.toBlob (ok);
        }).then ((blob) => {
          var nullAs = getActionStatus (null);
          nullAs.start ({stages: []});
          return uploadFile (blob, {
            mime_type: 'image/png',
            index_id: this.querySelector ('gr-select-index').value,
          }, nullAs);
        }).then (obj => {
          fd.append (name, obj.object_id);
        });
      } else if (this.grImageObjectURL) {
        var m = this.grImageObjectURL.match (/\/g\/[0-9]+\/o\/([0-9]+)\//);
        if (!m[1]) throw new Error ('Bad grImageObjectURL |'+this.grImageObjectURL+'|');
        fd.append (name, m[1]);
      }
    }, // pcModifyFormData
  },
}); // <gr-select-icon>

defineElement ({
  name: 'gr-called-editor',
  templateSet: true,
  props: {
    pcInit: function () {
      this.grSelected = {account_id: {}, category: {}};
      this.grSelected.category.thread = this.hasAttribute ('threadid');
      this.setAttribute ('formcontrol', '');
      this.addEventListener ('pctemplatesetupdated', (ev) => {
        this.grTemplateSet = ev.pcTemplateSet;
        Promise.resolve ().then (() => this.grRender ());
      });

      this.grOC = this.grObjectCalled || {};
      Object.defineProperty (this, 'grObjectCalled', {
        set: function (v) {
          this.grOC = v || {};
          Promise.resolve ().then (() => this.grRender ());
        },
      });
    }, // pcInit
    grRender: function () {
      if (!this.grTemplateSet) return;
      
      var tm = this.grTemplateSet;
      var e = tm.createFromTemplate ('div', {});
      this.textContent = '';
      while (e.firstChild) this.appendChild (e.firstChild);

      this.grThreadAccountIds ().then (accountIds => {
        if (accountIds === null) {
          this.querySelectorAll ('[data-called-type=if-in-thread]').forEach (_ => _.remove ());
        } else {
          this.querySelectorAll ('[data-called-type=if-in-thread]').forEach (_ => {
            _.hidden = false;
            _.querySelectorAll ('[data-called-type=thread-notified-count]').forEach (_ => _.textContent = accountIds.length);
            _.querySelectorAll ('input[data-called-type]').forEach (_ => {
              _.onchange = () => this.grToggleCalled (_.getAttribute ('data-called-type'), _.value, _.checked);
              _.checked = this.grSelected[_.getAttribute ('data-called-type')][_.value];
            });
          });
        }
      });

      this.grUpdateSelectedView ();
      return new Promise (ok => {
        this.ontoggle = (ev) => {
          if (ev.target.localName === 'popup-menu' &&
              ev.target.hasAttribute ('open')) {
            this.ontoggle = null;
            ok ();
          }
        };
      }).then (() => {
        return Promise.all ([
          $getTemplateSet ('gr-called-editor-menu-item'),
          GR.group.activeMembers (),
        ]);
      }).then (_ => {
        var [tm, mems] = _;
        var oca = this.grOC.account_ids || {};
        this.querySelectorAll ('gr-called-editor-menu-items').forEach (c => {
          c.textContent = '';
          mems.forEach (mem => {
            mem.last_sent = (oca[mem.account_id] || {}).last_sent;
            var e = tm.createFromTemplate ('list-item', mem);
            e.querySelectorAll ('input[data-called-type]').forEach (_ => {
              _.onchange = () => this.grToggleCalled (_.getAttribute ('data-called-type'), _.value, _.checked);
              _.checked = this.grSelected[_.getAttribute ('data-called-type')][_.value];
            });
            if (!mem.last_sent) e.querySelectorAll ('.if-sent').forEach (_ => _.remove ());
            c.appendChild (e);
          });
        });
      });
    }, // grRender
    grToggleCalled: function (type, id, selected) {
      var old = this.grSelected[type][id];
      if (old && selected) return;
      if (!old && !selected) return;
      if (selected) {
        this.grSelected[type][id] = selected;
      } else {
        delete this.grSelected[type][id];
      }
      return this.grUpdateSelectedView ();
    }, // grToggleCalled
    grThreadAccountIds: function () {
      if (this.grThreadAIDs) return this.grThreadAIDs;
      if (this.hasAttribute ('threadid')) {
        return this.grThreadAIDs = gFetch ('o/' + this.getAttribute ('threadid') + '/notified.json', {}).then (json => {
          return json.account_ids;
        });
      } else {
        return this.grThreadAIDs = Promise.resolve (null);
      }
    }, // grThreadAccountIds
    grReset: function () {
      this.grSelected = {account_id: {}, category: {}};
      this.grSelected.category.thread = this.hasAttribute ('threadid');
      return this.grRender ();
    }, // grReset
    grUpdateSelectedView: function () {
      clearTimeout (this.grUpdateSelectedViewTimer);
      this.grUpdateSelectedViewTimer = setTimeout (() => this.gr_updateSelectedView (), 200);
    }, // grUpdateSelectedView
    gr_updateSelectedView: function () {
      this.querySelectorAll ('gr-called-editor-selected').forEach (c => {
        return Promise.all ([
          $getTemplateSet ('gr-called-editor-selected-item'),
          $getTemplateSet ('gr-called-editor-selected-category-thread'),
          GR.group.activeMembers (),
        ]).then (([tm, tm2, mems]) => {
          c.textContent = '';
          if (this.grSelected.category.thread) {
            var e = tm2.createFromTemplate ('list-item', {});
            c.appendChild (e);
          }
          mems.forEach (mem => {
            if (this.grSelected.account_id[mem.account_id]) {
              var e = tm.createFromTemplate ('list-item', mem);
              c.appendChild (e);
            }
          });
          if (!c.firstChild) {
            c.classList.add ('placeholder');
            c.textContent = c.getAttribute ('placeholder');
          } else {
            c.classList.remove ('placeholder');
          }
        });
      });
    }, // gr_updateSelectedView
    pcModifyFormData: function (fd) {
      var added = {};
      Object.keys (this.grSelected.account_id).forEach (aid => {
        if (this.grSelected.account_id[aid]) {
          fd.append ('called_account_id', aid);
          added[aid] = true;
        }
      });
      if (this.grSelected.category.thread) {
        return this.grThreadAccountIds ().then (accountIds => {
          if (accountIds) accountIds.forEach (aid => {
            if (!added[aid]) {
              fd.append ('called_account_id', aid);
              added[aid] = true;
            }
          });
        });
      }
    }, // pcModifyFormData
  },
}); // gr-called-editor

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

GR.jumpList = {};

GR.jumpList.get = function () {
  if (GR._state.getJumpList) return GR._state.getJumpList;
  
  return GR._state.getJumpList = fetch ('/jump/list.json', {
    credentials: 'same-origin',
    referrerPolicy: 'same-origin',
  }).then ((res) => {
    if (res.status !== 200) throw res;
    return res.json ();
  }).then (json => {
    json.items.forEach (_ => {
      _.absoluteURL = new URL (_.url, location.href);
    });
    return json.items;
  }).catch (e => {
    if (e instanceof Response && e.status === 403) {
      throw GR.Error.handle403 (e);
    }
    throw e;
  });
}; // GR.jumpList.get

GR.jumpList.reload = function () {
  delete GR._state.getJumpList;
  document.querySelectorAll ('gr-nav-panel[active] list-container[loader=jumpListLoader]:not([loader-delayed])').forEach (_ => _.load ({}));
  document.querySelectorAll ('gr-nav-panel:not([active]) list-container[loader=jumpListLoader]:not([loader-delayed])').forEach (_ => _.setAttribute ('loader-delayed', ''));
}; // GR.jumpList.reload

defineElement ({
  name: 'a',
  is: 'gr-jump-add',
  props: {
    pcInit: function () {
      this.onclick = () => { this.grClick (); return false };
    }, // pcInit
    grClick: function () {
      var fd = new FormData;
      if (this.title) fd.append ('label', this.title);
      fd.append ('url', this.href);
      this.setAttribute ('data-saving', '');
      return gFetch ('/jump/add.json', {post: true, formData: fd}).then (() => {
        GR.jumpList.reload ();
      }).finally (() => {
        this.removeAttribute ('data-saving');
      });
    }, // grClick
  },
});

(() => {
  var e = document.createElementNS ('data:,pc', 'loader');
  e.setAttribute ('name', 'jumpListLoader');
  e.pcHandler = function (opts) {
    if (this.hasAttribute ('loader-delayed')) return {data: []};
    return GR.jumpList.get ().then (items => {
      return {
        data: items,
      };
    });
  };
  document.head.appendChild (e);

}) ();

defineElement ({
  name: 'gr-object-ref',
  fill: 'contentattribute',
  props: {
    pcInit: function () {
      var mo = new MutationObserver (() => this.grRender ());
      mo.observe (this, {attributes: true, attributeFilter: ['value']});
      this.grRender ();
    }, // pcInit
    grRender: function () {
      var objectId = this.getAttribute ('value');
      if (!objectId) return;

      return Promise.all ([
        GR.object.get (objectId, {withSearchData: true}),
        $getTemplateSet ('gr-object-ref'),
      ]).then (([object, tm]) => {
        this.textContent = '';
        var e = tm.createFromTemplate ('div', {object: object});
        while (e.firstChild) this.appendChild (e.firstChild);
      });
    }, // grRender
  },
}); // <gr-object-ref>

(() => { // STAR ELEMENTS

  GR._stars = function (objectId) {
    if (!GR._state.getStars) {
      GR._state.getStarsObjectIds = [];
      GR._state.getStars = new Promise (ok => {
        setTimeout (ok, 200);
      }).then (() => {
        delete GR._state.getStars;
        var fd = new FormData;
        GR._state.getStarsObjectIds.forEach (_ => fd.append ('o', _));
        return gFetch ('star/list.json', {post: true, formData: fd});
      });
    }

    GR._state.getStarsObjectIds.push (objectId);
    return GR._state.getStars.then (json => {
      return json.items[objectId] || [];
    });
  }; // GR._stars

  defineElement ({
    name: 'gr-stars',
    fill: 'contentattribute',
    props: {
      pcInit: function () {
        return Promise.all ([
          $getTemplateSet ('gr-stars'),
          $getTemplateSet ('gr-star-item'),
        ]).then (([tm, tm2]) => {
          this.grTemplateSet = tm;
          this.grTemplateSet2 = tm2;

          var mo = new MutationObserver (() => this.grRender ());
          mo.observe (this, {attributes: true, attributeFilter: ['value']});
          this.grRender ();
        });
      }, // pcInit
      grRender: function () {
        var objectId = this.getAttribute ('value');
        if (!objectId) return;
        
        var tm = this.grTemplateSet;
        var e = tm.createFromTemplate ('div', {object_id: objectId});
        this.textContent = '';
        while (e.firstChild) this.appendChild (e.firstChild);

        this.querySelectorAll ('.add-star-button').forEach (_ => {
          _.onclick = () => this.grAddStar (+1);
        });

        this.querySelectorAll ('.remove-star-button').forEach (_ => {
          _.onclick = () => this.grAddStar (-1);
        });

        return GR._stars (objectId).then (stars => {
          this.gr_ShowStars (stars);
        });
      }, // grRender
      grAddStar: function (delta) {
        var objectId = this.getAttribute ('value');
        if (!objectId) return;

        if (!this.grStarDelta) this.grStarDelta = 0;
        this.grStarDelta += delta;
        if (delta > 0) this.gr_ShowStars ([{count: delta}]);
        if (delta < 0) this.grNegativeDelta = true;

        clearTimeout (this.grAddStarTimer);
        this.grAddStarTimer = setTimeout (() => {
          var d = this.grStarDelta;
          this.grStarDelta = 0;
          delete this.grNegativeDelta;
          var fd = new FormData;
          fd.append ('object_id', objectId);
          fd.append ('delta', d);
          return gFetch ('star/add.json', {post: true, formData: fd}).then (() => {
            if (d < 0) this.grRender ();
          });
        }, 800);
      }, // grAddStar
      gr_ShowStars: function (stars) {
        var container = this.querySelector ('gr-star-list');
        stars.forEach (_ => {
          var tm2 = this.grTemplateSet2;
          var x = [_];
          if (!(_.count > 10)) {
            for (var i = 1; i < _.count; i++) x.push (_);
          }
          x.forEach (_ => {
            var e = tm2.createFromTemplate ('gr-star-item', _);
            if (!_.author_account_id) {
              e.querySelectorAll ('gr-account').forEach (_ => {
                _.removeAttribute ('data-field');
                _.removeAttribute ('value');
                _.setAttribute ('self', '');
              });
            }
            container.appendChild (e);
          });
        });
      }, // gr_ShowStars
    },
  }); // <gr-stars>

  var e = document.createElementNS ('data:,pc', 'templateselector');
  e.setAttribute ('name', 'gr-star-item-selector');
  e.pcHandler = function (templates, obj) {
    if (obj.count > 10) {
      return templates[""];
    } else {
      return templates.single;
    }
  }; // gr-star-item-selector
  document.head.appendChild (e);

}) ();

GR.tooltip = {};

GR.tooltip.show = function (opts) {
  GR.tooltip.hideAll ();
  var e = document.createElement ('gr-tooltip-box');
  e.hidden = true;
  document.body.appendChild (e);
  return $getTemplateSet ('gr-tooltip-box-' + opts.type).then (tm => {
    if (opts.top) e.style.top = opts.top + 'px';
    if (opts.left) e.style.left = opts.left + 'px';
    
    var f = tm.createFromTemplate ('gr-tooltip-content', opts);
    if (f.childNodes.length === 0) {
      e.remove ();
      return;
    }
    e.appendChild (f);
    e.hidden = false;
  });
}; // GR.tooltip.show

GR.tooltip.showURL = function (u, opts) {
  opts._depth = opts._depth || 0;
  var url;
  try {
    url = new URL (u);
  } catch (e) {
    url = {};
  }
  if (url.origin === location.origin) {
    var m = url.pathname.match (/^\/g\/([^\/]+)\/o\/([0-9]+)\//);
    if (m && m[1] == GR._state.group.group_id) {
      opts.type = 'object';
      opts.data = {group_id: m[1], object_id: m[2]};
      return GR.tooltip.show (opts);
    }

    m = url.pathname.match (/^\/g\/([^\/]+)\/imported\/([^\/]+)\/go/);
    if (m && m[1] == GR._state.group.group_id && opts._depth < 10) {
      return GR.group.resolveImportedURL (GR._decodeURL (m[2])).then (u => {
        opts._depth++;
        return GR.tooltip.showURL (u, opts); // recursive!
      });
    }
  }
  return GR.tooltip.hideAll ();
}; // GR.tooltip.showURL

GR.tooltip.hideAll = function () {
  document.querySelectorAll ('gr-tooltip-box').forEach (_ => _.remove ());
}; // GR.tooltip.hideAll

function Formatter () { }

Formatter.html = function (source) {
  var doc = document.implementation.createHTMLDocument ();
  var div = doc.createElement ('div');
  div.innerHTML = source;
  return div;
}; // html

Formatter.hatena = function (source) {
  return fetch (document.documentElement.getAttribute ('data-formatter-url') + "/hatena", {
    method: "post",
    body: source,
  }).then (function (r) {
    if (r.status !== 200) throw r;
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

Formatter.autolink = function (source) {
  return fetch (document.documentElement.getAttribute ('data-formatter-url') + "/autolink", {
    method: "post",
    body: source,
  }).then (function (r) {
    if (r.status !== 200) throw r;
    return r.text ();
  });
}; // autolink

(new MutationObserver (function (mutations) {
  mutations.forEach (function (m) {
    Array.prototype.forEach.call (m.addedNodes, function (x) {
      if (x.localName === 'gr-list-container') {
        upgradeList (x);
      } else if (x.localName) {
        $$ (x, 'gr-list-container').forEach (upgradeList);
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
      if (x.localName === 'with-sidebar') {
        upgradeWithSidebar (x);
      } else if (x.localName) {
        $$ (x, 'with-sidebar').forEach (upgradeWithSidebar);
      }
    });
  });
})).observe (document.documentElement, {childList: true, subtree: true});
$$ (document, 'gr-list-container').forEach (upgradeList);
$$ (document, 'form').forEach (upgradeForm);
$$ (document, 'gr-popup-menu').forEach (upgradePopupMenu);
$$ (document, 'with-sidebar').forEach (upgradeWithSidebar);

GR.navigate = {};

GR.navigate._init = function (partition) {
  addEventListener ('click', (ev) => {
    var n = ev.target;
    while (n && n.localName !== 'a') {
      n = n.parentElement;
    }
    if (n &&
        (n.protocol === 'https:' || n.protocol === 'http:') &&
        n.target === '' &&
        !n.hasAttribute ('is')) {
      GR.navigate.go (n.href, {ping: n.ping});
      ev.preventDefault ();
    }
  });
  history.scrollRestoration = "manual";
  GR.navigate.enabled = true;
  GR._state.navigateInitiated = performance.now ();
  if (partition) GR._state.navigatePartition = partition;
}; // GR.navigate._init

GR.navigate.avail = function () {
  if (!GR.navigate.enabled) return false;

  var elapsed = performance.now () - GR._state.navigateInitiated;
  if (elapsed > 10*60*60*1000) {
    return false;
  }

  // XXX revision test / account changed
  
  return true;
}; // GR.navigate.avail

GR.navigate.go = function (u, args) {
  var url = new URL (u, location.href);
  var status = document.querySelector ('gr-navigate-status');
  status.grStart (url);
  GR.tooltip.hideAll ();
  return Promise.resolve ().then (() => {
    if (GR.navigate.avail () &&
        url.origin === location.origin) {
      if (!args.reload &&
          url.pathname === location.pathname &&
          url.search === location.search) {
        return ['fragment', url];
      }
      if (GR._state.navigatePartition === 'group') {
        return GR.group.info ().then (group => {
          var path = url.pathname;
          var prefix = '/g/' + group.group_id + '/';
          if (path.substring (0, prefix.length) === prefix) {
            path = path.substring (prefix.length);

            if (path === '') {
              return ['group', 'index', {}];
            }

            var m = path.match (/^(files|search|config|members)$/);
            if (m) return ['group', m[1], {
              q: url.searchParams.get ('q'),
            }];

            m = path.match (/^o\/([0-9]+)\/$/);
            if (m) return ['group', 'object-index', {
              objectId: m[1],
              objectRevisionId: url.searchParams.get ('object_revision_id') || null,
              withObjectData: true,
            }];

            m = path.match (/^o\/([0-9]+)\/(revisions)$/);
            if (m) return ['group', 'object-' + m[2], {
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
              return ['group', 'wiki', {
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
              return ['group', 'wiki', {
                wikiName: n,
              }];
            }

            m = path.match (/^account\/([0-9]+)\/$/);
            if (m) return ['group', 'account-index', {
              accountId: m[1],
            }];

            m = path.match (/^my\/(config)$/);
            if (m) return ['group', 'my-config', {
              myAccount: true,
              welcome: url.searchParams.has ('welcome'),
            }];

            if (path === 'guide') {
              if (group.guide_object_id) {
                return ['group', 'object-index', {
                  objectId: group.guide_object_id,
                  withObjectData: true,
                }];
              } else {
                return ['group', 'guide-none', {}];
              }
            }

            m = path.match (/^imported\/([^\/]+)\/go$/);
            args._depth = args._depth || 0;
            if (m && args._depth < 10) {
              return GR.group.resolveImportedURL (GR._decodeURL (m[1])).then (u => {
                return ['recursive', u];
              });
            }

            return ['site', url];
          } else if (path.match (/^\/g\//)) {
            return ['external', url];
          } else { // dashboard, etc.
            return ['site', url];
          }
        });
      } else if (GR._state.navigatePartition === 'dashboard') {
        var path = url.pathname;
        if (path === '/dashboard') {
          return ['dashboard', 'dashboard', {}];
        } else if (path === '/jump') {
          return ['dashboard', 'jump', {}];
        }

        var m = path.match (/^\/dashboard\/(groups|receive|calls)$/);
        if (m) {
          return ['dashboard', 'dashboard-' + m[1], {}];
        }
        
        return ['site', url];
      } else {
        throw new Error ('Bad navigate partition |'+GR._state.navigatePartition+'|');
      }
    } else if (url.origin === location.origin) { // ! GR.navigate.avail ()
      return ['site', url];
    }
    return ['external', url];
  }).then (_ => {
    if (_[0] === 'recursive') {
      args._depth++;
      return GR.navigate.go (_[1], args);
    }
    
    if (GR._state.currentNavigate) {
      GR._state.currentNavigate.abort ();
      delete GR._state.currentNavigate;
    }
    var sendPing = () => {
      if (args.ping) {
        args.ping.split (/\s+/).forEach (_ => {
          navigator.sendBeacon (_);
        });
      }
    }; // sendPing
    if (_[0] === 'group' || _[0] === 'dashboard') {
      var ac = new AbortController;
      var nav = GR._state.currentNavigate = {
        abort: () => ac.abort (),
      };
      Promise.resolve ().then (sendPing);
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
      sendPing ();
    } else if (_[0] === 'site') {
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
        sendPing ();
      }
    } else if (_[0] === 'external') {
      var e = document.createElement ('gr-navigate-dialog');
      e.setAttribute ('href', _[1]);
      // sendPing
      document.body.appendChild (e);
      status.grStop ();
    }
  });
  // XXX catch
}; // go

GR.navigate._show = function (pageName, pageArgs, opts) {
  // Assert: pageName is valid
  var pushed = false;
  return $getTemplateSet ('page-' + pageName).then (ts => {
    var params = {};
    var wait = [];
    var isGroup = GR._state.navigatePartition === 'group';
    var setGI = isGroup ? GR.group.info ().then (_ => params.group = _) : null;
    wait.push (setGI);
    if (pageName === 'search') {
      params.search = {q: pageArgs.q || ''};
    }
    if (pageName === 'wiki') {
      params.wiki = {name: pageArgs.wikiName};
    }
    if (pageArgs.indexId) {
      wait.push (GR.index.info (pageArgs.indexId).then (_ => params.index = _));
    } else if (params.wiki) {
      wait.push (setGI.then (() => {
        if (!params.group.default_wiki_index_id) {
          throw new DOMException ('The group has no default wiki', 'InvalidStateError');
        }
        return GR.index.info (params.group.default_wiki_index_id).then (_ => params.index = _);
      }));
    }
    if (pageArgs.objectId) {
      wait.push (Promise.all ([
        GR.index.list (),
        GR.object.get (pageArgs.objectId, {
          revisionId: pageArgs.objectRevisionId,
          withTitle: true,
          withData: pageArgs.withObjectData,
        }).then (_ => params.object = _),
      ]).then (_ => {
        var [indexList] = _;
        var indexIds = Object.keys ((params.object.data || {}).index_ids || {});
        for (var i = 0; i < indexIds.length; i++) {
          var index = indexList[indexIds[i]];
          if (index &&
              (index.index_type == 1 /* blog */ ||
               index.index_type == 2 /* wiki */ ||
               index.index_type == 3 /* todo */ ||
               index.index_type == 6 /* fileset */)) {
            params.index = index;
            break;
          }
        }
      }));
    }
    if (pageArgs.accountId) {
      wait.push (GR.account.get (pageArgs.accountId).then (_ => {
        if (!_) throw new DOMException ('Account not found', 'InvalidStateError');
        params.account = _;
      }));
    } else if (pageArgs.myAccount) {
      wait.push (GR.account.info ().then (_ => params.account = _));
    }
    // XXX abort wait by opts.signal[12]
    return Promise.all (wait).then (_ => {
      if (opts.signal1.aborted || opts.signal2.aborted) {
        throw new DOMException ('Navigation request aborted', 'AbortError');
      }

      if (params.wiki) {
        params.wiki.url = GR.wiki.url (params.index.index_id, params.wiki.name);
        if (opts.url) {
          var url = new URL (params.wiki.url, location.href);
          url.search = opts.url.search;
          url.fragment = opts.url.fragment;
          if (opts.reload && !opts.popstate && opts.url.href !== url.href) {
            opts.url = url;
            delete opts.reload;
            opts.replace = true;
          }
        }
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

      params.title = 'Gruwa';
      params.url = '/dashboard';
      params.theme = 'green';
      if (params.group) {
        params.title = params.group.title;
        params.url = '/g/' + params.group.group_id + '/';
        params.theme = params.group.theme;
      }
      if (params.index && params.index.theme) {
        params.theme = params.index.theme;
        params.url += 'i/' + params.index.index_id + '/';
        params.title = params.index.title;
      } else if (params.index && params.index.index_type == 6 /* fileset */) {
        params.url += 'i/' + params.index.index_id + '/';
        params.title = params.index.title;
      }
      
      document.querySelectorAll ('body > header.page').forEach (_ => {
        $fill (_, params);

        var menu = _.querySelector ('gr-menu');
        if (params.index && (params.index.theme || params.index.index_type == 6 /* fileset */)) {
          menu.setAttribute ('type', 'index');
          menu.setAttribute ('indexid', params.index.index_id);
          _.querySelector ('header.page > a').style.visibility = 'visible';
        } else if (params.group) {
          menu.setAttribute ('type', 'group');
          _.querySelector ('header.page > a').style.visibility = 'hidden';
        } else {
          menu.setAttribute ('type', 'dashboard');
        }
      }); // header.page
      
      var contentTitle = '';
      var contentClasses;
      document.querySelectorAll ('page-main').forEach (_ => {
        var div = ts.createFromTemplate ('div', params);
        params.contentTitle = contentTitle = div.title;
        contentClasses = div.classList;
        div.title = '';

        if (params.group) {
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
          if (params.group.guide_object_id) {
            div.querySelectorAll ('#guide-create-form').forEach (_ => {
              _.hidden = true;
            });
          } else {
            div.querySelectorAll ('#guide-link').forEach (_ => {
              _.hidden = true;
            });
          }
        } // params.group

        if (params.index) {
          div.querySelectorAll ('[data-gr-if-index-type]:not([data-gr-if-index-type~="'+params.index.index_type+'"])').forEach (_ => {
            _.remove ();
          });
          div.querySelectorAll ('[data-gr-if-index-subtype]:not([data-gr-if-index-subtype~="'+params.index.subtype+'"])').forEach (_ => {
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

          div.querySelectorAll ('gr-menu[type=index]').forEach (_ => {
            _.setAttribute ('indexid', params.index.index_id);
          });
        } // params.index

        if (params.wiki) {
          div.querySelectorAll ('gr-menu[type=wiki]').forEach (_ => {
            _.setAttribute ('indexid', params.index.index_id);
            _.setAttribute ('wikiname', params.wiki.name);
          });
        }

        if (!pageArgs.objectRevisionId) {
          div.querySelectorAll ('[data-gr-if-revision]').forEach (_ => {
            _.remove ();
          });
        }

        if (pageArgs.myAccount) {
          if (params.account.guide_object_id) {
            div.querySelectorAll ('#account-guide-create-form').forEach (_ => {
              _.hidden = true;
            });
          } else {
            div.querySelectorAll ('#account-guide-link').forEach (_ => {
              _.hidden = true;
            });
          }
        }
        
        if (pageArgs.welcome !== undefined) {
          if (pageArgs.welcome) {
            div.querySelectorAll ('gr-if-not-welcome').forEach (_ => {
              _.remove ();
            });
          } else {
            div.querySelectorAll ('gr-if-welcome').forEach (_ => {
              _.remove ();
            });
          }
        }

        // XXX
        if (pageName === 'object-index') {
          var list = div.querySelector ('gr-list-container[key=objects]');
          list.setAttribute ('src-object_id', params.object.object_id);
        } else if (pageName === 'account-index') {
          if (params.account && params.account.guide_object_id) {
            var list = div.querySelector ('gr-list-container[key=objects]');
            list.setAttribute ('src-object_id', params.account.guide_object_id);
          }
        } else if (pageName === 'wiki') {
          var list = div.querySelector ('gr-list-container[key=objects]');
          list.setAttribute ('src-index_id', params.index.index_id);
          list.setAttribute ('src-wiki_name', params.wiki.name);
        } else if (pageName === 'index-index') {
          div.querySelectorAll ('gr-list-container[key=objects]').forEach (list => {
            list.setAttribute ('src-index_id', params.index.index_id);
          });
        }

        _.textContent = '';
        while (div.firstChild) _.appendChild (div.firstChild);
      });

      document.querySelectorAll ('body > header.subpage').forEach (_ => {
        _.hidden = ! contentClasses.contains ('is-subpage');
        if (contentClasses.contains ('subpage-back-to-subdirectory')) {
          params.backURL = './';
        } else {
          params.backURL = params.url;
        }
        if (!_.hidden) $fill (_, params);
      });
      
      var title = [];
      if (params.group) {
        title.unshift (params.group.title);
      } else {
        title.unshift ('Gruwa');
      }
      if (params.index) title.unshift (params.index.title);
      if (params.wiki) {
        title.unshift (params.wiki.name);
      } else if (params.object) {
        title.unshift (params.object.data.title || params.object.title);
      }
      if (contentTitle !== '') title.unshift (contentTitle);
      if (params.search) {
        GR.page.setSearch (params.search);
      } else {
        GR.page.setSearch (null);
      }
      GR.page.setTitle (title);
      GR._state.currentPage = params;
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
        console.log ("Navigation to <"+opts.url+"> canceled");
        return;
      } else {
        console.log ("Navigation to <"+opts.url+"> canceled and errored");
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
  name: 'gr-nav-button',
  props: {
    pcInit: function () {
      this.querySelectorAll ('button').forEach (_ => {
        _.onclick = () => {
          var active = ! this.hasAttribute ('active');
          document.querySelectorAll ('gr-nav-button, gr-nav-panel').forEach (_ => {
            if (active) {
              _.setAttribute ('active', '');
            } else {
              _.removeAttribute ('active');
            }
          });
          document.querySelectorAll ('gr-nav-panel[active]').forEach (_ => _.grOpened ());
        };
      });
    }, // pcInit
  },
}); // <gr-nav-button>

defineElement ({
  name: 'gr-nav-panel',
  props: {
    pcInit: function () {
      this.onclick = (ev) => {
        if (ev.target.localName === 'a' ||
            ev.target.localName === 'button') {
          this.grClose ();
        }
      };
    }, // pcInit
    grOpened: function () {
      this.querySelectorAll ('list-container[loader-delayed]').forEach (_ => {
        _.removeAttribute ('loader-delayed');
        _.load ({});
      });
      this.querySelector ('summary, a, button, input').focus ();
    }, // grOpened
    grClose: function () {
      document.querySelectorAll ('gr-nav-button button').forEach (_ => _.click ());
    }, // grClose
  },
}); // <gr-nav-panel>

(() => {
  
  var e = document.createElementNS ('data:,pc', 'templateselector');
  e.setAttribute ('name', 'selectIndexIndexTemplate');
  e.pcHandler = function (templates, obj) {
    if (obj.index.index_type == 1 /* blog */) {
      return templates.blog;
    } else if (obj.index.index_type == 3 /* todos */ ||
               obj.index.index_type == 4 /* label */ ||
               obj.index.index_type == 5 /* milestone */) {
      return templates.todos;
    } else if (obj.index.index_type == 6 /* fileset */) {
      return templates.fileset;
    } else {
      return templates[""];
    }
  }; // selectIndexIndexTemplate
  document.head.appendChild (e);

}) ();

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

      this.querySelectorAll ('gr-error, .reload-button').forEach (_ => _.hidden = true);
    }, // grStart
    grStop: function () {
      this.grAS.end ({ok: true});
      this.hidden = true;
      clearTimeout (this.grTimer);
      document.documentElement.removeAttribute ('data-navigating');
    }, // grStop
    grThrow: function (e) {
      var found = false;
      this.querySelectorAll ('gr-error').forEach (_ => {
        if (_.getAttribute ('message') === e.message) {
          found = true;
          _.hidden = false;
        } else {
          _.hidden = true;
        }
      });

      this.querySelectorAll ('.reload-button').forEach (_ => {
        _.onclick = () => GR.navigate.go ('', {reload: true});
        _.hidden = false;
      });

      if (found) {
        this.grAS.end ({ok: true});
      } else {
        this.grAS.end ({error: e});
      }
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
      if (!GR.navigate.enabled) GR.navigate._init (this.getAttribute ('partition'));
      GR.navigate.go (location.href, {
        reload: true,
        popstate: this.hasAttribute ('popstate'),
      });
      this.remove ();
    }, // pcInit
  },
}); // <gr-navigate>

addEventListener ('popstate', ev => {
  var nav = document.createElement ('gr-navigate');
  nav.setAttribute ('popstate', '');
  document.body.appendChild (nav);
});

defineElement ({
  name: 'gr-navigate-dialog',
  props: {
    pcInit: function () {
      this.grShow ();
    }, // pcInit
    grShow: function () {
      return $getTemplateSet ('gr-navigate-external').then (ts => {
        var backdrop = document.createElement ('gr-backdrop');
        var url = new URL (this.getAttribute ('href'));
        var obj = {
          href: url.href,
          origin: url.origin,
        };
        var container = ts.createFromTemplate ('article', obj);
        container.className = 'dialog msgbox';
        container.querySelectorAll ('a').forEach (_ => {
          _.onclick = () => this.grClose ();
        });
        backdrop.onclick = (ev) => {
          if (ev.target === ev.currentTarget) this.grClose ();
        };
        backdrop.appendChild (container);
        this.appendChild (backdrop);
      });
    }, // grShow
    grClose: function () {
      this.remove ();
    }, // grClose
  },
}); // <gr-navigate-dialog>

defineElement ({
  name: 'gr-count',
  fill: 'contentattribute',
  templateSet: true,
  props: {
    pcInit: function () {
      this.addEventListener ('pctemplatesetupdated', (ev) => {
        this.grTemplateSet = ev.pcTemplateSet;
        Promise.resolve ().then (() => this.grRender ());
      });
      new MutationObserver (() => this.grRender ()).observe
          (this, {attributes: true, attributeFilter: ['all', 'value']});
    }, // pcInit
    grRender: function () {
      var tm = this.grTemplateSet;
      if (!tm) return;

      var v = {
        value: this.getAttribute ('value'),
        all: parseFloat (this.getAttribute ('all')),
      };
      if (!v.all || !Number.isFinite (v.all)) {
        this.hidden = true;
      } else {
        this.hidden = false;
        var e = tm.createFromTemplate ('div', v);
        this.textContent = '';
        while (e.firstChild) this.appendChild (e.firstChild);
      }
    }, // grRender
  },
}); // <gr-count>

defineElement ({
  name: 'xxx-multi-enum', // XXX
  fill: 'idlattribute',
  props: {
    pcInit: function () {
      var value = this.value;
      Object.defineProperty (this, 'value', {
        get: () => value,
        set: (newValue) => {
          value = newValue;
          this.meRender (value);
        },
      });
      this.meRender (value);
    },
    meRender: function (value) {
      this.textContent = '';
      var hasPrev = false;
      for (var k in value) {
        if (!value[k]) continue;
        if (hasPrev) {
          this.appendChild (document.createTextNode (' '));
        }
        var e = document.createElement ('XXX-multi-enum-item');
        var v = this.getAttribute ('label-' + k);
        if (v === null) v = k;
        if (v !== '') {
          e.textContent = v;
          this.appendChild (e);
          hasPrev = true;
        }
      }
    }, // meRender
  },
}); // <XXX-multi-enum>

(() => {
  var def = document.createElementNS ('data:,pc', 'formsaved');
  def.setAttribute ('name', 'reloadPushList');
  def.pcHandler = function (fd) {
    document.querySelectorAll ('.push-list').forEach (_ => _.load ({}));
    document.querySelectorAll ('gr-push-config').forEach (_ => _.grReset ());
  };
  document.head.appendChild (def);

  var def = document.createElementNS ('data:,pc', 'saver');
  def.setAttribute ('name', 'addPush');
  def.pcHandler = function (fd) {
    return navigator.serviceWorker.register ('/js/sw.js', {scope: "/"}).then (function (reg) {
      return navigator.serviceWorker.ready;
    }).then (function (reg) {
      return reg.pushManager.subscribe ({
        userVisibleOnly: true,
        applicationServerKey: Uint8Array.from (document.documentElement.getAttribute ('data-push-server-key').split (/,/)),
      });
    }).then (function (sub) {
      fd.append ('sub', JSON.stringify (sub.toJSON ()));
      return fetch ('/account/push/add.json', {
        method: 'POST',
        body: fd,
        credentials: 'same-origin',
        referrerPolicy: 'same-origin',
      });
    }).then ((res) => {
      if (res.status !== 200) throw res;
    }).catch (e => {
      if (e instanceof Response && e.status === 403) {
        throw GR.Error.handle403 (e);
      }
      throw e;
    });
  };
  document.head.appendChild (def);

  var def = document.createElementNS ('data:,pc', 'saver');
  def.setAttribute ('name', 'removePush');
  def.pcHandler = function (fd) {
    if (!navigator.serviceWorker.controller) return;
    return navigator.serviceWorker.ready.then (function (reg) {
      return reg.pushManager.getSubscription ();
    }).then (function (sub) {
      if (!sub) return;
      fd.append ('url', sub.endpoint);
      return fetch ('/account/push/delete.json', {
        method: 'POST',
        body: fd,
        credentials: 'same-origin',
        referrerPolicy: 'same-origin',
      }).then ((res) => {
        if (res.status !== 200) throw res;
      }).then (() => sub.unsubscribe ());
    });
  };
  document.head.appendChild (def);

  var hasPush = !(!navigator.serviceWorker || !window.PushManager || !(location.protocol === 'https:' || location.hostname === 'localhost'));

  if (location.pathname !== '/dashboard/receive')
  GR.idle (() => {
    fetch ('/account/configsummary.json').then (res => {
      if (res.status !== 200) throw res;
      return res.json ();
    }).then (json => {
      if (!json.email && !localStorage.hideEmailMN) {
        GR.page.showMiniNotification ({template: "mn-email", close: () => {
          localStorage.hideEmailMN = true;
        }});
      }
      if (!json.push && !localStorage.hidePushMN && hasPush) {
        GR.page.showMiniNotification ({template: "mn-push", close: () => {
          localStorage.hidePushMN = true;
        }});
      }
    });
  });
  
  var e = document.createElementNS ('data:,pc', 'formsaved');
  e.setAttribute ('name', 'resetConfig');
  e.pcHandler = function (args) {
    delete localStorage[args.args[1]];
  }; // resetConfig
  document.head.appendChild (e);

  defineElement ({
    name: 'gr-push-config',
    props: {
      pcInit: function () {
        this.querySelectorAll ('gr-has-push').forEach (_ => _.hidden = !hasPush);
        this.querySelectorAll ('gr-no-push').forEach (_ => _.hidden = hasPush);
        if (!hasPush) return;

        this.grReset ();
      }, // pcInit
      grReset: function () {
        this.querySelectorAll ('gr-has-push-sub').forEach (_ => _.hidden = true);
        this.querySelectorAll ('gr-no-push-sub').forEach (_ => _.hidden = false);
        navigator.serviceWorker.ready.then ((reg) => {
          return reg.pushManager.getSubscription ();
        }).then ((sub) => {
          this.querySelectorAll ('gr-has-push-sub').forEach (_ => _.hidden = !sub);
          this.querySelectorAll ('gr-no-push-sub').forEach (_ => _.hidden = !!sub);
        });
      }, // grReset
    },
  }); // <gr-push-config>
  
  var def = document.createElementNS ('data:,pc', 'filter');
  def.setAttribute ('name', 'uaLabelFilter');
  def.pcHandler = function (result) {
    result.data.forEach ((_) => {
      _.uaLabel = _.ua;
    });
    return result;
  };
  document.head.appendChild (def);

}) ();

defineElement ({
  name: 'link',
  is: 'gr-html-import',
  props: {
    pcInit: function () {
      return fetch (this.href).then (res => {
        return res.text ();
      }).then (text => {
        var div = document.createElement ('div');
        div.hidden = true;
        div.innerHTML = text;
        document.body.appendChild (div);
      });
    }, // pcInit
  },
}); // <link is=gr-html-import>

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

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
<https://www.gnu.org/licenses/>.

*/
