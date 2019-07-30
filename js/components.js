(function () {
  var texts = {
    "lat.plus": "N",
    "lat.minus": "S",
    "lon.plus": "E",
    "lon.minus": "W",
  };

  var mpf = 0.3048; // meter = 1 international foot
  var fpml = 5280; // feet = 1 mile

  var useIUnits = false;
  if (document.documentElement) {
    useIUnits = document.documentElement.getAttribute ('data-distance-unit') === 'imperial';
    new MutationObserver (function (mutations) {
      useIUnits = document.documentElement.getAttribute ('data-distance-unit') === 'imperial';
      document.querySelectorAll ('unit-number[type=distance], unit-number[type=elevation]').forEach (update);
    }).observe (document.documentElement, {attributes: true, attributeFilter: ['data-distance-unit']});
  }
  
  var update = function (e) {
    var value = parseFloat (e.getAttribute ('value'));
    if (!Number.isFinite (value)) return;
    var type = e.getAttribute ('type');
    var unit = null;
    var separator = '';
    if (type === 'distance') {
      unit = 'm';
      if (useIUnits) {
        if (value >= 10 * fpml * mpf || value <= -10 * fpml * mpf) {
          value = value / mpf / fpml;
          unit = 'ml';
        } else {
          value = value / mpf;
          unit = 'ft';
        }
      } else {
        if (value >= 10000 || value <= -10000) {
          value = Math.floor (value / 100) / 10;
          unit = 'km';
        }
      }
      if (unit === 'km') {
        //
      } else if (value >= 100 || value <= -100) {
        value = Math.floor (value);
      } else {
        value = Math.floor (value * 100) / 100;
      }
    } else if (type === 'elevation') {
      unit = 'm';
      if (useIUnits) {
        value = value / mpf;
        unit = 'ft';
      }
      if (value >= 100 || value <= -100) {
        value = Math.floor (value);
      } else {
        value = Math.floor (value * 100) / 100;
      }
    } else if (type === 'count' || type === 'rank') {
      // XXX plural rules
      unit = e.getAttribute ('unit') || '';
      if (/^[A-Za-z]/.test (unit)) separator = ' ';
    } else if (type === 'percentage') {
      unit = '%';
      value = Math.round (value * 100 * 10) / 10;
    } else if (type === 'duration') {
      e.textContent = '';
      var format = e.getAttribute ('format') || 'h:mm:ss.ss';
      var h = Math.floor (value / 60 / 60);
      var m = Math.floor (value / 60) - h * 60;
      var s = value - m * 60 - h * 60 * 60;
      if (format === 'h:mm:ss') {
        s = Math.floor (s);
      } else {
        s = s.toFixed (2);
      }
      e.appendChild (document.createElement ('number-value')).textContent = h;
      e.appendChild (document.createElement ('number-separator')).textContent = ":";
      e.appendChild (document.createElement ('number-value')).textContent = m >= 10 ? m : "0" + m;
      e.appendChild (document.createElement ('number-separator')).textContent = ":";
      e.appendChild (document.createElement ('number-value')).textContent = s >= 10 ? s : "0" + s;
      e.removeAttribute ('hasseparator');
      return;
    } else if (type === 'bytes') {
      unit = 'B';
      if (value > 1000) {
        value = Math.round (value / 1024 * 10) / 10;
        unit = 'KB';
        if (value > 1000) {
          value = Math.round (value / 1024 * 10) / 10;
          unit = 'MB';
          if (value > 1000) {
            value = Math.round (value / 1024 * 10) / 10;
            unit = 'GB';
          }
        }
      }
    } else if (type === 'lat' || type === 'lon') {
      var sign = value >= 0;
      if (!sign) value = -value;
      var v = Math.floor (value);
      value = (value % 1) * 60;
      var w = Math.floor (value);
      value = (value % 1) * 60;
      var x = Math.floor (value);

      e.innerHTML = "<number-value></number-value><number-unit>\u00B0</number-unit><number-value></number-value><number-unit>\u2032</number-unit><number-value></number-value><number-unit>\u2033</number-unit><number-sign></number-sign>";
      e.children[0].textContent = v;
      e.children[2].textContent = w;
      e.children[4].textContent = x;
      e.children[6].textContent = texts[type + (sign ? ".plus" : ".minus")];
      e.removeAttribute ('hasseparator');
      return;
    } else if (type === 'pixels') {
      value = Math.ceil (value * 10) / 10;
      unit = 'px';
    }
    if (unit === '') {
      e.innerHTML = '<number-value></number-value>';
      e.firstChild.textContent = value.toLocaleString ();
      e.removeAttribute ('hasseparator');
    } else if (unit !== null) {
      e.innerHTML = '<number-value></number-value><number-unit></number-unit>';
      e.firstChild.textContent = value.toLocaleString ();
      e.lastChild.textContent = unit;
      e.insertBefore (document.createTextNode (separator), e.lastChild);
      if (separator.length) {
        e.setAttribute ('hasseparator', '');
      } else {
        e.removeAttribute ('hasseparator');
      }
    }
  }; // update

  var upgrade = function (e) {
    if (e.unitNumberUpgraded) return;
    e.unitNumberUpgraded = true;
    var mo = new MutationObserver (function (mutations) {
      update (mutations[0].target);
    });
    mo.observe (e, {attributes: true, attributeFilter: ['value', 'type']});
    Promise.resolve (e).then (update);
  }; // upgrade
  
  var op = upgrade;
  var selector = 'unit-number';
  var mo = new MutationObserver (function (mutations) {
    mutations.forEach (function (m) {
      Array.prototype.forEach.call (m.addedNodes, function (e) {
        if (e.nodeType === e.ELEMENT_NODE) {
          if (e.matches && e.matches (selector)) op (e);
          Array.prototype.forEach.call (e.querySelectorAll (selector), op);
        }
      });
    });
  });
  mo.observe (document, {childList: true, subtree: true});
  Array.prototype.forEach.call (document.querySelectorAll (selector), op);

  // Integration with <https://github.com/wakaba/html-page-components>
  var def = document.createElementNS ('data:,pc', 'filltype');
  def.setAttribute ('name', 'unit-number');
  def.setAttribute ('content', 'contentattribute');
  document.head.appendChild (def);
}) ();

/*

Copyright 2017-2019 Wakaba <wakaba@suikawiki.org>.

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
(function () {
  var exportable = {};

  var $promised = exportable.$promised = {};

  $promised.forEach = function (code, items) {
    var list = Array.prototype.slice.call (items);
    var run = function () {
      if (!list.length) return Promise.resolve ();
      return Promise.resolve (list.shift ()).then (code).then (run);
    };
    return run ();
  }; // forEach

  $promised.map = function (code, items) {
    var list = Array.prototype.slice.call (items);
    var newList = [];
    var run = function () {
      if (!list.length) return Promise.resolve (newList);
      return Promise.resolve (list.shift ()).then (code).then ((_) => {
        newList.push (_);
      }).then (run);
    };
    return run ();
  }; // map

  var definables = {
    loader: {type: 'handler'},
    filter: {type: 'handler'},
    templateselector: {type: 'handler'},
    saver: {type: 'handler'},
    formsaved: {type: 'handler'},
    formvalidator: {type: 'handler'},
    filltype: {type: 'map'},
    templateSet: {type: 'element'},
    element: {type: 'customElement'},
  };
  var defs = {};
  var defLoadedPromises = {};
  var defLoadedCallbacks = {};
  for (var n in definables) {
    defs[n] = {};
    defLoadedPromises[n] = {};
    defLoadedCallbacks[n] = {};
  }
  var addDef = function (e) {
    var type = e.localName;
    if (!(e.namespaceURI === 'data:,pc' && definables[type])) return;
    if (definables[type].type === 'element') return;

    var name;
    if (definables[type].type === 'customElement') {
      name = e.pcDef ? e.pcDef.name : null;
      if (e.pcDef && e.pcDef.is) {
        name += ' is=' + e.pcDef.is;
      }
    } else {
      name = e.getAttribute ('name');
    }

    if (defs[type][name]) {
      throw new Error ("Duplicate |"+type+"|: |"+name+"|");
    } else {
      var value = null;
      if (definables[type].type === 'handler') {
        value = e.pcHandler || (() => {});
      } else if (definables[type].type === 'customElement') {
        defineElement (e.pcDef);
        value = true;
      } else {
        value = e.getAttribute ('content');
      }
      defs[type][name] = value;
    }
    if (defLoadedCallbacks[type][name]) {
      defLoadedCallbacks[type][name] (value);
      delete defLoadedCallbacks[type][name];
      delete defLoadedPromises[type][name];
    }
    e.remove ();
  }; // addDef
  var addElementDef = (type, name, e) => {
    if (defs[type][name]) {
      throw new Error ("Duplicate |"+type+"|: |"+name+"|");
    }
    defs[type][name] = e;
    if (defLoadedCallbacks[type][name]) {
      defLoadedCallbacks[type][name] (e);
      delete defLoadedCallbacks[type][name];
      delete defLoadedPromises[type][name];
    }
  }; // addElementDef
  new MutationObserver (function (mutations) {
    mutations.forEach
        ((m) => Array.prototype.forEach.call (m.addedNodes, addDef));
  }).observe (document.head, {childList: true});
  Promise.resolve ().then (() => {
    Array.prototype.slice.call (document.head.children).forEach (addDef);
  });
  var getDef = function (type, name) {
    var def = defs[type][name];
    if (def) {
      return Promise.resolve (def);
    } else {
      if (!defLoadedPromises[type][name]) {
        defLoadedPromises[type][name] = new Promise ((a, b) => {
          defLoadedCallbacks[type][name] = a;
        });
      }
      return defLoadedPromises[type][name];
    }
  }; // getDef

  var waitDefsByString = function (string) {
    return Promise.all (string.split (/\s+/).map ((_) => {
      if (_ === "") return;
      var v = _.split (/:/, 2);
      if (defs[v[0]]) {
        return getDef (v[0], v[1]);
      } else {
        throw new Error ("Unknown definition type |"+v[0]+"|");
      }
    }));
  }; // waitDefsByString

  defs.filltype.time = 'datetime';
  // <data>
  defs.filltype.input = 'idlattribute';
  defs.filltype.select = 'idlattribute';
  defs.filltype.textarea = 'idlattribute';
  defs.filltype.output = 'idlattribute';
  // <progress>
  // <meter>

  var upgradableSelectors = [];
  var currentUpgradables = ':not(*)';
  var newUpgradableSelectors = [];
  var upgradedElementProps = {};
  var upgrader = {};
  
  var upgrade = function (e) {
    if (e.pcUpgraded) return;
    e.pcUpgraded = true;

    var props = (upgradedElementProps[e.localName] || {})[e.getAttribute ('is')] || {};
    Object.keys (props).forEach (function (k) {
      e[k] = props[k];
    });

    new Promise ((re) => re ((upgrader[e.localName] || {})[e.getAttribute ('is')].call (e))).catch ((err) => console.log ("Can't upgrade an element", e, err));
  }; // upgrade

  new MutationObserver (function (mutations) {
    mutations.forEach (function (m) {
      Array.prototype.forEach.call (m.addedNodes, function (e) {
        if (e.nodeType === e.ELEMENT_NODE) {
          if (e.matches && e.matches (currentUpgradables)) upgrade (e);
          Array.prototype.forEach.call
              (e.querySelectorAll (currentUpgradables), upgrade);
        }
      });
    });
  }).observe (document, {childList: true, subtree: true});

  var commonMethods = {};
  var defineElement = function (def) {
    upgradedElementProps[def.name] = upgradedElementProps[def.name] || {};
    upgradedElementProps[def.name][def.is || null] = def.props = def.props || {};
    if (def.pcActionStatus) {
      def.props.pcActionStatus = commonMethods.pcActionStatus;
    }
    
    upgrader[def.name] = upgrader[def.name] || {};
    var init = def.templateSet ? function () {
      initTemplateSet (this);
      this.pcInit ();
    } : upgradedElementProps[def.name][def.is || null].pcInit || function () { };
    upgrader[def.name][def.is || null] = function () {
      var e = this;
      if (e.nextSibling ||
          document.readyState === 'interactive' ||
          document.readyState === 'complete') {
        return init.call (e);
      }
      return new Promise (function (ok) {
        setInterval (function () {
          if (e.nextSibling ||
              document.readyState === 'interactive' ||
              document.readyState === 'complete') {
            ok ();
          }
        }, 100);
      }).then (function () {
        return init.call (e);
      });
    };
    if (!def.notTopLevel) {
      var selector = def.name;
      if (def.is) selector += '[is="' + def.is + '"]';
      newUpgradableSelectors.push (selector);
      Promise.resolve ().then (() => {
        var news = newUpgradableSelectors.join (',');
        if (!news) return;
        newUpgradableSelectors.forEach ((_) => upgradableSelectors.push (_));
        newUpgradableSelectors = [];
        currentUpgradables = upgradableSelectors.join (',');
        Array.prototype.forEach.call (document.querySelectorAll (news), upgrade);
      });
    } // notTopLevel
  }; // defineElement

  var filledAttributes = ['href', 'src', 'id', 'title', 'value', 'action',
                          'class'];
  var $fill = exportable.$fill = function (root, object) {
    root.querySelectorAll ('[data-field]').forEach ((f) => {
      var name = f.getAttribute ('data-field').split (/\./);
      var value = object;
      for (var i = 0; i < name.length; i++) {
        value = value[name[i]];
        if (value == null) break;
      }

      var ln = f.localName;
      var fillType = defs.filltype[ln];
      if (fillType === 'contentattribute') {
        f.setAttribute ('value', value);
      } else if (fillType === 'idlattribute') {
        f.value = value;
      } else if (fillType === 'datetime') {
        try {
          var dt = new Date (value * 1000);
          f.setAttribute ('datetime', dt.toISOString ());
        } catch (e) {
          f.removeAttribute ('datetime');
          f.textContent = e;
        }
        if (f.hasAttribute ('data-tzoffset-field')) {
          var name = f.getAttribute ('data-tzoffset-field').split (/\./);
          var v = object;
          for (var i = 0; i < name.length; i++) {
            v = v[name[i]];
            if (v == null) break;
          }
          if (v != null) {
            f.setAttribute ('data-tzoffset', v);
          } else {
            f.removeAttribute ('data-tzoffset');
          }
        }
      } else {
        if ((value == null || (value + "") === "") && f.hasAttribute ('data-empty')) {
          f.textContent = f.getAttribute ('data-empty');
        } else {
          f.textContent = value;
        }
      }

      f.removeAttribute ('data-filling');
    }); // [data-field]

    root.querySelectorAll ('[data-enable-by-fill]').forEach ((f) => {
      f.removeAttribute ('disabled');
    });

    filledAttributes.forEach ((n) => {
      root.querySelectorAll ('[data-'+n+'-field]').forEach ((f) => {
        var name = f.getAttribute ('data-'+n+'-field').split (/\./);
        var value = object;
        for (var i = 0; i < name.length; i++) {
          value = value[name[i]];
          if (value == null) break;
        }
        if (value) {
          f.setAttribute (n, value);
        } else {
          f.removeAttribute (n);
        }
      }); // [data-*-field]

      root.querySelectorAll ('[data-'+n+'-template]').forEach ((f) => {
        f.setAttribute (n, $fill.string (f.getAttribute ('data-'+n+'-template'), object));
      }); // [data-*-template]
    }); // filledAttributes
  }; // $fill

  $fill.string = function (s, object) {
    return s.replace (/\{([\w.]+)\}/g, function (_, n) {
      var name = n.split (/\./);
      var value = object;
      for (var i = 0; i < name.length; i++) {
        value = value[name[i]];
        if (value == null) break;
      }
      return value;
    });
  }; // $fill.string

  var templateSetLocalNames = {};
  var templateSetSelector = '';
  var templateSetMembers = {
    pcCreateTemplateList: function () {
      var oldList = this.pcTemplateList || {};
      var newList = this.pcTemplateList = {};
      Array.prototype.slice.call (this.querySelectorAll ('template')).forEach ((g) => {
        this.pcTemplateList[g.getAttribute ('data-name') || ""] = g;
      });
      var oldKeys = Object.keys (oldList);
      var newKeys = Object.keys (newList);
      var changed = false;
      if (oldKeys.length !== newKeys.length) {
        changed = true;
      } else {
        for (var v in newKeys) {
          if (oldKeys[v] !== newKeys[v]) {
            changed = true;
            break;
          }
        }
      }
      if (!changed) return;
      
      this.pcSelectorUpdatedDispatched = false;
      this.pcSelectorName = this.getAttribute ('templateselector') || 'default';
      return getDef ('templateselector', this.pcSelectorName).then ((_) => {
        this.pcSelector = _;
        return Promise.all (Object.values (this.pcTemplateList).map ((e) => waitDefsByString (e.getAttribute ('data-requires') || '')));
      }).then (() => {
        var event = new Event ('pctemplatesetupdated', {});
        event.pcTemplateSet = this;
        var nodes;
        if (this.localName === 'template-set') {
          var name = this.getAttribute ('name');
          nodes = Array.prototype.slice.call (this.getRootNode ().querySelectorAll (templateSetSelector)).filter ((e) => e.getAttribute ('template') === name);
        } else {
          nodes = [this];
        }
        this.pcSelectorUpdatedDispatched = true;
        nodes.forEach ((e) => e.dispatchEvent (event));
      });
    }, // pcCreateTemplateList
    createFromTemplate: function (localName, object) {
      if (!this.pcSelector) throw new DOMException ('The template set is not ready', 'InvalidStateError');
      var template = this.pcSelector.call (this, this.pcTemplateList, object); // or throw
      if (!template) {
        console.log ('Template is not selected (templateselector=' + this.pcSelectorName + ')', this);
        template = document.createElement ('template');
      }
      var e = document.createElement (localName);
      e.appendChild (template.content.cloneNode (true));
      ['class', 'title', 'id'].forEach (_ => {
        if (template.hasAttribute (_)) {
          e.setAttribute (_, template.getAttribute (_));
        }
        if (template.hasAttribute ('data-'+_+'-template')) {
          e.setAttribute (_, $fill.string (template.getAttribute ('data-'+_+'-template'), object));
        }
        if (template.hasAttribute ('data-'+_+'-field')) {
          e.setAttribute (_, $fill.string ('{'+template.getAttribute ('data-'+_+'-field')+'}', object));
        }
      });
      $fill (e, object);
      return e;
    }, // createFromTemplate
  }; // templateSetMembers

  var initTemplateSet = function (e) {
    templateSetLocalNames[e.localName] = true;
    templateSetSelector = Object.keys (templateSetLocalNames).map ((n) => n.replace (/([^A-Za-z0-9])/g, (_) => "\\" + _.charCodeAt (0).toString (16) + " ") + '[template]').join (',');
    
    for (var n in templateSetMembers) {
      e[n] = templateSetMembers[n];
    }

    var templateSetName = e.getAttribute ('template');
    if (templateSetName) {
      var ts = defs.templateSet[templateSetName];
      if (ts && ts.pcSelectorUpdatedDispatched) {
        Promise.resolve ().then (() => {
          if (!ts.pcSelectorUpdatedDispatched) return;
          var event = new Event ('pctemplatesetupdated', {});
          event.pcTemplateSet = ts;
          e.dispatchEvent (event);
        });
      }
    } else {
      e.pcCreateTemplateList ();
      new MutationObserver ((mutations) => {
        e.pcCreateTemplateList ();
      }).observe (e, {childList: true});
    }
  }; // initTemplateSet

  exportable.$getTemplateSet = function (name) {
    return getDef ('templateSet', name).then (ts => {
      ts.pcCreateTemplateList ();
      return ts;
    });
  }; // $getTemplateSet

  var ActionStatus = function (elements) {
    this.stages = {};
    this.elements = elements;
  }; // ActionStatus

  ActionStatus.prototype.start = function (opts) {
    if (opts.stages) {
      opts.stages.forEach ((s) => {
        this.stages[s] = 0;
      });
    }
    this.elements.forEach ((e) => {
      e.querySelectorAll ('action-status-messages').forEach ((f) => f.hidden = true);
      e.querySelectorAll ('progress').forEach ((f) => {
        f.hidden = false;
        var l = Object.keys (this.stages).length;
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
    }); // e
  }; // start

  ActionStatus.prototype.stageStart = function (stage) {
    this.elements.forEach ((e) => {
      var label = e.getAttribute ('stage-' + stage);
      e.querySelectorAll ('action-status-message').forEach ((f) => {
        if (label) {
          f.textContent = label;
          f.hidden = false;
        } else {
          f.hidden = true;
        }
      });
    });
  }; // stageStart

  ActionStatus.prototype.stageProgress = function (stage, value, max) {
    if (Number.isFinite (value) && Number.isFinite (max)) {
      this.stages[stage] = value / (max || 1);
    } else {
      this.stages[stage] = 0;
    }
    this.elements.forEach ((e) => {
      e.querySelectorAll ('progress').forEach ((f) => {
        var stages = Object.keys (this.stages);
        f.max = stages.length;
        var v = 0;
        stages.forEach ((s) => v += this.stages[s]);
        f.value = v;
      });
    });
  }; // stageProgress

  ActionStatus.prototype.stageEnd = function (stage) {
    this.stages[stage] = 1;
    this.elements.forEach ((e) => {
      e.querySelectorAll ('progress').forEach ((f) => {
        var stages = Object.keys (this.stages);
        f.max = stages.length;
        var v = 0;
        stages.forEach ((s) => v += this.stages[s]);
        f.value = v;
      });
    });
  }; // stageEnd

  ActionStatus.prototype.end = function (opts) {
    this.elements.forEach ((e) => {
      var shown = false;
      e.querySelectorAll ('action-status-message').forEach ((f) => {
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
      e.querySelectorAll ('progress').forEach ((f) => f.hidden = true);
      e.hidden = !shown;
      e.setAttribute ('status', opts.ok ? 'ok' : 'ng');
    });
    if (!opts.ok) setTimeout (() => { throw opts.error }, 0); // invoke onerror
  }; // end

  commonMethods.pcActionStatus = function () {
    var elements = this.querySelectorAll ('action-status');
    elements.forEach (function (e) {
      if (e.hasChildNodes ()) return;
      e.hidden = true;
      e.innerHTML = '<action-status-message></action-status-message> <progress></progress>';
    });
    return new ActionStatus (elements);
  }; // pcActionStatus

  defineElement ({
    name: 'template-set',
    props: {
      pcInit: function () {
        var name = this.getAttribute ('name');
        if (!name) {
          throw new Error
          ('|template-set| element does not have |name| attribute');
        }
        addElementDef ('templateSet', name, this);
        initTemplateSet (this);
      }, // pcInit
    },
  }); // <template-set>

  defs.templateselector["default"] = function (templates) {
    return templates[""];
  }; // empty

  defs.filltype["enum-value"] = 'contentattribute';
  defineElement ({
    name: 'enum-value',
    props: {
      pcInit: function () {
        var mo = new MutationObserver ((mutations) => this.evRender ());
        mo.observe (this, {attributes: true, attributeFilter: ['value']});
        this.evRender ();
      }, // pcInit
      evRender: function () {
        var value = this.getAttribute ('value');
        if (value === null) {
          this.hidden = true;
        } else {
          this.hidden = false;
          var label = this.getAttribute ('label-' + value);
          if (label === null) {
            this.textContent = value;
          } else {
            this.textContent = label;
          }
        }
      }, // evRender
    }, // props
  }); // <enum-value>

  defineElement ({
    name: 'button',
    is: 'command-button',
    props: {
      pcInit: function () {
        this.addEventListener ('click', () => this.cbClick ());
      }, // pcInit
      cbClick: function () {
        var selector = this.getAttribute ('data-selector');
        var selected = document.querySelector (selector);
        if (!selected) {
          throw new Error ("Selector |"+selector+"| does not match any element in the document");
        }
        
        var command = this.getAttribute ('data-command');
        var cmd = selected.cbCommands ? selected.cbCommands[command] : undefined;
        if (!cmd) throw new Error ("Command |"+command+"| not defined");

        selected[command] ();
      }, // cbClick
    },
  }); // button[is=command-button]

  defineElement ({
    name: 'button',
    is: 'mode-button',
    props: {
      pcInit: function () {
        this.addEventListener ('click', () => this.mbClick ());

        this.getRootNode ().addEventListener ('pcModeChange', (ev) => {
          if (ev.mode !== this.name) return;
          
          var selector = this.getAttribute ('data-selector');
          var selected = document.querySelector (selector);
          if (!selected) return;
          if (selected !== ev.target) return;

          var name = this.name;
          if (!name) return;

          this.classList.toggle ('selected', selected[name] == this.value);
        });
        // XXX disconnect

        var selector = this.getAttribute ('data-selector');
        var selected = document.querySelector (selector);
        var name = this.name;
        if (selected && name) {
          this.classList.toggle ('selected', selected[name] == this.value);
        }
      }, // pcInit
      mbClick: function () {
        var selector = this.getAttribute ('data-selector');
        var selected = document.querySelector (selector);
        if (!selected) {
          throw new Error ("Selector |"+selector+"| does not match any element in the document");
        }

        var name = this.name;
        if (!name) {
          throw new Error ("The |mode-button| element has no name");
        }
        
        selected[name] = this.value;
      }, // mbClick
    },
  }); // button[is=mode-button]
  
  defineElement ({
    name: 'popup-menu',
    props: {
      pcInit: function () {
        this.addEventListener ('click', (ev) => this.pmClick (ev));
        var mo = new MutationObserver ((mutations) => {
          this.pmToggle (this.hasAttribute ('open'));
        });
        mo.observe (this, {attributes: true, attributeFilter: ['open']});
        setTimeout (() => this.pmLayout (), 100);
      }, // pcInit
      pmClick: function (ev) {
        var current = ev.target;
        var targetType = 'outside';
        while (current) {
          if (current === this) {
            targetType = 'this';
            break;
          } else if (current.localName === 'button') {
            if (current.parentNode === this) {
              targetType = 'button';
              break;
            } else {
              targetType = 'command';
              break;
            }
          } else if (current.localName === 'a') {
            targetType = 'command';
            break;
          } else if (current.localName === 'menu-main' &&
                     current.parentNode === this) {
            targetType = 'menu';
            break;
          }
          current = current.parentNode;
        } // current

        if (targetType === 'button') {
          this.toggle ();
        } else if (targetType === 'menu') {
          //
        } else {
          this.toggle (false);
        }
        ev.pmEventHandledBy = this;
      }, // pmClick

      toggle: function (show) {
        if (show === undefined) {
          show = !this.hasAttribute ('open');
        }
        if (show) {
          this.setAttribute ('open', '');
        } else {
          this.removeAttribute ('open');
        }
      }, // toggle
      pmToggle: function (show) {
        if (show) {
          if (!this.pmGlobalClickHandler) {
            this.pmGlobalClickHandler = (ev) => {
              if (ev.pmEventHandledBy === this) return;
              this.toggle (false);
            };
            window.addEventListener ('click', this.pmGlobalClickHandler);
            this.pmLayout ();
          }
        } else {
          if (this.pmGlobalClickHandler) {
            window.removeEventListener ('click', this.pmGlobalClickHandler);
            delete this.pmGlobalClickHandler;
          }
        }
      }, // pmToggle

      pmLayout: function () {
        if (!this.hasAttribute ('open')) return;
      
        var button = this.querySelector ('button');
        var menu = this.querySelector ('menu-main');
        if (!button || !menu) return;

        menu.style.top = 'auto';
        menu.style.left = 'auto';
        var menuWidth = menu.offsetWidth;
        var menuTop = menu.offsetTop;
        var menuHeight = menu.offsetHeight;
        if (getComputedStyle (menu).direction === 'rtl') {
          var parent = menu.offsetParent || document.documentElement;
          if (button.offsetLeft + menuWidth > parent.offsetWidth) {
            menu.style.left = button.offsetLeft + button.offsetWidth - menuWidth + 'px';
          } else {
            menu.style.left = button.offsetLeft + 'px';
          }
        } else {
          var right = button.offsetLeft + button.offsetWidth;
          if (right > menuWidth) {
            menu.style.left = (right - menuWidth) + 'px';
          } else {
            menu.style.left = 'auto';
          }
        }
      }, // pmLayout
    },
  }); // popup-menu

  defineElement ({
    name: 'tab-set',
    props: {
      pcInit: function () {
        new MutationObserver (() => this.tsInit ()).observe (this, {childList: true});
        Promise.resolve ().then (() => this.tsInit ());
      }, // pcInit
      tsInit: function () {
        var tabMenu = null;
        var tabSections = [];
        Array.prototype.forEach.call (this.children, function (f) {
          if (f.localName === 'section') {
            tabSections.push (f);
          } else if (f.localName === 'tab-menu') {
            tabMenu = f;
          }
        });
      
        if (!tabMenu) return;

        tabMenu.textContent = '';
        tabSections.forEach ((f) => {
          var header = f.querySelector ('h1');
          var a = document.createElement ('a');
          a.href = 'javascript:';
          a.onclick = () => this.tsShowTab (a.tsSection);
          a.textContent = header ? header.textContent : '§';
          a.tsSection = f;
          tabMenu.appendChild (a);
        });

        if (tabSections.length) this.tsShowTab (tabSections[0]);
      }, // tsInit
      tsShowTab: function (f) {
        var tabMenu = null;
        var tabSections = [];
        Array.prototype.forEach.call (this.children, function (f) {
          if (f.localName === 'section') {
            tabSections.push (f);
          } else if (f.localName === 'tab-menu') {
            tabMenu = f;
          }
        });

        tabMenu.querySelectorAll ('a').forEach ((g) => {
          g.classList.toggle ('active', g.tsSection === f);
        });
        tabSections.forEach ((g) => {
          g.classList.toggle ('active', f === g);
        });
        var ev = new Event ('show', {bubbles: true});
        Promise.resolve ().then (() => f.dispatchEvent (ev));
      }, // tsShowTab
    },
  }); // tab-set
  
  defs.loader.src = function (opts) {
    if (!this.hasAttribute ('src')) return {};
    var url = this.getAttribute ('src');
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
    }).then ((res) => res.json ()).then ((json) => {
      if (!this.hasAttribute ('key')) throw new Error ("|key| is not specified");
      json = json || {};
      return {
        data: json[this.getAttribute ('key')],
        prev: {ref: json.prev_ref, has: json.has_prev, limit: opts.limit},
        next: {ref: json.next_ref, has: json.has_next, limit: opts.limit},
      };
    });
  }; // loader=src

  defs.filter["default"] = function (data) {
    var list = data.data;
    if (!Array.isArray (list)) {
      list = Object.values (list);
    }
    // XXX sort=""
    return {
      data: list,
      prev: data.prev,
      next: data.next,
    };
  }; // filter=default

  defineElement ({
    name: 'list-container',
    pcActionStatus: true,
    props: {
      pcInit: function () {
        var selector = 'a.list-prev, a.list-next, button.list-prev, button.list-next, ' + this.lcGetListContainerSelector ();
      new MutationObserver ((mutations) => {
        mutations.forEach ((m) => {
          Array.prototype.forEach.call (m.addedNodes, (e) => {
            if (e.nodeType === e.ELEMENT_NODE) {
              if (e.matches (selector) || e.querySelector (selector)) {
                var listContainer = this.lcGetListContainer ();
                if (listContainer) listContainer.textContent = '';
                this.lcDataChanges.changed = true;
                this.lcRequestRender ();
              }
            }
          });
        });
      }).observe (this, {childList: true, subtree: true});

      this.addEventListener ('pctemplatesetupdated', (ev) => {
        this.lcTemplateSet = ev.pcTemplateSet;

        var listContainer = this.lcGetListContainer ();
        if (listContainer) listContainer.textContent = '';
        this.lcDataChanges.changed = true;
        this.lcRequestRender ();
      });
      this.load ({});
    }, // pcInit

      lcGetNextInterval: function (currentInterval) {
        if (!currentInterval) return 10 * 1000;
        var interval = currentInterval * 2;
        if (interval > 10*60*1000) interval * 10*60*1000;
        return interval;
      }, // lcGetNextInterval
      load: function (opts) {
        if (!opts.page || opts.replace) this.lcClearList ();
        return this.lcLoad (opts).then ((done) => {
          if (done) {
            this.lcDataChanges.scroll = opts.scroll;
            return this.lcRequestRender ();
          }
        }).then (() => {
          if (!this.hasAttribute ('autoreload')) return;
          var interval = this.lcGetNextInterval (opts.arInterval);
          clearTimeout (this.lcAutoReloadTimer);
          this.lcAutoReloadTimer = setTimeout (() => {
            this.load ({arInterval: interval});
          }, interval);
        }, (e) => {
          if (!this.hasAttribute ('autoreload')) return;
          var interval = this.lcGetNextInterval (opts.arInterval);
          clearTimeout (this.lcAutoReloadTimer);
          this.lcAutoReloadTimer = setTimeout (() => {
            this.load ({arInterval: interval});
          }, interval);
          throw e;
        });
      }, // load
      loadPrev: function (opts2) {
        var opts = {};
        Object.keys (this.lcPrev).forEach (_ => opts[_] = this.lcPrev[_]);
        Object.keys (opts2 || {}).forEach (_ => opts[_] = opts2[_]);
        return this.load (opts);
      }, // loadPrev
      loadNext: function (opts2) {
        var opts = {};
        Object.keys (this.lcNext).forEach (_ => opts[_] = this.lcNext[_]);
        Object.keys (opts2 || {}).forEach (_ => opts[_] = opts2[_]);
        return this.load (opts);
      }, // loadNext
    lcClearList: function () {
      this.lcData = [];
      this.lcDataChanges = {append: [], prepend: [], changed: false};
      this.lcPrev = {};
      this.lcNext = {};
      
      var listContainer = this.lcGetListContainer ();
      if (listContainer) listContainer.textContent = '';
    }, // lcClearList
    lcGetListContainerSelector: function () {
      var type = this.getAttribute ('type');
      if (type === 'table') {
        return 'tbody';
      } else {
        return 'list-main';
      }
    }, // lcGetListContainerSelector
    lcGetListContainer: function () {
      return this.querySelector (this.lcGetListContainerSelector ());
    }, // lcGetListContainer
    
      lcLoad: function (opts) {
        var resolve;
        var reject;
        this.loaded = new Promise ((a, b) => {
          resolve = a;
          reject = b;
        });
        this.loaded.catch ((e) => {}); // set [[handled]] true (the error is also reported by ActionStatus)
        var as = this.pcActionStatus ();
        as.start ({stages: ['loader', 'filter', 'render']});
        as.stageStart ('loader');
        this.querySelectorAll ('list-is-empty').forEach ((e) => {
          e.hidden = true;
        });
        return getDef ("loader", this.getAttribute ('loader') || 'src').then ((loader) => {
          return loader.call (this, opts);
        }).then ((result) => {
          as.stageEnd ('loader');
          as.stageStart ('filter');
          return getDef ("filter", this.getAttribute ('filter') || 'default').then ((filter) => {
            return filter.call (this, result);
          });
        }).then ((result) => {
          var newList = result.data || [];
          var prev = (opts.page === 'prev' ? result.next : result.prev) || {};
          var next = (opts.page === 'prev' ? result.prev : result.next) || {};
          prev = {
            has: prev.has,
            ref: prev.ref,
            limit: prev.limit,
            page: 'prev',
          };
          next = {
            has: next.has,
            ref: next.ref,
            limit: next.limit,
            page: 'next',
          };
          if (this.hasAttribute ('reverse')) {
            newList = newList.reverse ();
            if (opts.page === 'prev' && !opts.replace) {
              newList = newList.reverse ();
              this.lcData = newList.concat (this.lcData);
              this.lcDataChanges.append
                  = this.lcDataChanges.append.concat (newList);
              this.lcPrev = prev;
            } else if (opts.page === 'next' && !opts.replace) {
              this.lcData = this.lcData.concat (newList);
              this.lcDataChanges.prepend
                  = newList.concat (this.lcDataChanges.prepend);
              this.lcNext = next;
            } else {
              this.lcData = newList;
              this.lcDataChanges = {prepend: [], append: [], changed: true};
              this.lcPrev = prev;
              this.lcNext = next;
            }
          } else { // not reverse
            if (opts.page === 'prev' && !opts.replace) {
              newList = newList.reverse ();
              this.lcData = newList.concat (this.lcData);
              this.lcDataChanges.prepend
                  = newList.concat (this.lcDataChanges.prepend);
              this.lcPrev = prev;
            } else if (opts.page === 'next' && !opts.replace) {
              this.lcData = this.lcData.concat (newList);
              this.lcDataChanges.append
                  = this.lcDataChanges.append.concat (newList);
              this.lcNext = next;
            } else {
              this.lcData = newList;
              this.lcDataChanges = {prepend: [], append: [], changed: true};
              this.lcPrev = prev;
              this.lcNext = next;
            }
          }
          as.end ({ok: true});
          resolve ();
          return true;
        }).catch ((e) => {
          reject (e);
          as.end ({error: e});
          return false;
        });
      }, // lcLoad

      lcRequestRender: function () {
        clearTimeout (this.lcRenderRequestedTimer);
        this.lcRenderRequested = true;
        this.lcRenderRequestedTimer = setTimeout (() => {
          if (!this.lcRenderRequested) return;
          this.lcRender ();
          this.lcRenderRequested = false;
        }, 0);
      }, // lcRequestRender
      lcRender: function () {
        if (!this.lcTemplateSet) return;

        var listContainer = this.lcGetListContainer ();
        if (!listContainer) return;

        this.querySelectorAll ('a.list-prev, button.list-prev').forEach ((e) => {
          e.hidden = ! this.lcPrev.has;
          if (e.localName === 'a') {
            e.href = this.lcPrev.linkURL || 'javascript:';
          }
          e.onclick = () => { this.loadPrev ({
            scroll: e.getAttribute ('data-list-scroll'),
            replace: e.hasAttribute ('data-list-replace'),
          }); return false };
        });
        this.querySelectorAll ('a.list-next, button.list-next').forEach ((e) => {
          e.hidden = ! this.lcNext.has;
          if (e.localName === 'a') {
            e.href = this.lcNext.linkURL || 'javascript:';
          }
          e.onclick = () => { this.loadNext ({
            scroll: e.getAttribute ('data-list-scroll'),
            replace: e.hasAttribute ('data-list-replace'),
          }); return false };
        });
        this.querySelectorAll ('list-is-empty').forEach ((e) => {
          e.hidden = this.lcData.length > 0;
        });

      var tm = this.lcTemplateSet;
      var changes = this.lcDataChanges;
      this.lcDataChanges = {changed: false, prepend: [], append: []};
      var itemLN = {
        tbody: 'tr',
      }[listContainer.localName] || 'list-item';
      return Promise.resolve ().then (() => {
        if (changes.changed) {
          return $promised.forEach ((object) => {
            var e = tm.createFromTemplate (itemLN, object);
            listContainer.appendChild (e);
          }, this.lcData);
        } else {
          var scrollRef;
          var scrollRefTop;
          if (changes.scroll === 'preserve') {
            scrollRef = listContainer.firstElementChild;
          }
          if (scrollRef) scrollRefTop = scrollRef.offsetTop;
          var f = document.createDocumentFragment ();
          return Promise.all ([
            $promised.forEach ((object) => {
              var e = tm.createFromTemplate (itemLN, object);
              f.appendChild (e);
            }, changes.prepend).then (() => {
              listContainer.insertBefore (f, listContainer.firstChild);
            }),
            $promised.forEach ((object) => {
              var e = tm.createFromTemplate (itemLN, object);
              listContainer.appendChild (e);
            }, changes.append),
          ]).then (() => {
            if (scrollRef) {
              var delta = scrollRef.offsetTop - scrollRefTop;
              // XXX nearest scrollable area
              if (delta) document.documentElement.scrollTop += delta;
            }
          });
        }
        }).then (() => {
          this.dispatchEvent (new Event ('pcRendered', {bubbles: true}));
        });
      }, // lcRender
    },
    templateSet: true,
  }); // list-container

  defineElement ({
    name: 'form',
    is: 'save-data',
    pcActionStatus: true,
    props: {
      pcInit: function () {
        this.sdCheck ();
        this.addEventListener ('click', (ev) => {
          var e = ev.target;
          while (e) {
            if (e.localName === 'button') break;
            // |input| buttons are intentionally not supported
            if (e === this) {
              e = null;
              break;
            }
            e = e.parentNode;
          }
          this.sdClickedButton = e;
        });
        this.addEventListener ('change', (ev) => {
          this.setAttribute ('data-pc-modified', '');
        });
        this.onsubmit = function () {
          this.sdCheck ();

          if (this.hasAttribute ('data-confirm')) {
            if (!confirm (this.getAttribute ('data-confirm'))) return false;
          }
          
          var fd = new FormData (this);
          if (this.sdClickedButton) {
            if (this.sdClickedButton.name &&
                this.sdClickedButton.type === 'submit') {
              fd.append (this.sdClickedButton.name, this.sdClickedButton.value);
            }
            this.sdClickedButton = null;
          }

          var disabledControls = this.querySelectorAll
              ('input:enabled, select:enabled, textarea:enabled, button:enabled');
          var customControls = this.querySelectorAll ('[formcontrol]:not([disabled])');
          disabledControls.forEach ((_) => _.setAttribute ('disabled', ''));
          customControls.forEach ((_) => _.setAttribute ('disabled', ''));

          var validators = (this.getAttribute ('data-validator') || '')
              .split (/\s+/)
              .filter (function (_) { return _.length });
          var nextActions = (this.getAttribute ('data-next') || '')
              .split (/\s+/)
              .filter (function (_) { return _.length })
              .map (function (_) {
                return _.split (/:/);
              });

          var as = this.pcActionStatus ();
          
          $promised.forEach ((_) => {
            if (_.pcModifyFormData) {
              return _.pcModifyFormData (fd);
            } else {
              console.log (_, "No |pcModifyFormData| method");
              throw "A form control is not initialized";
            }
          }, customControls).then (() => {
            return $promised.forEach ((_) => {
              return getDef ("formvalidator", _).then ((handler) => {
                return handler.call (this, {
                  formData: fd,
                });
              });
            }, validators);
          }).then (() => {
            as.start ({stages: ['saver']});
            as.stageStart ('saver');
            return getDef ("saver", this.getAttribute ('data-saver') || 'form').then ((saver) => {
              return saver.call (this, fd);
            });
          }).then ((res) => {
            this.removeAttribute ('data-pc-modified');
            var p;
            var getJSON = function () {
              return p = p || res.json ();
            };
            return $promised.forEach ((_) => {
              return getDef ("formsaved", _[0]).then ((handler) => {
                return handler.call (this, {
                  args: _,
                  response: res,
                  json: getJSON,
                });
              });
            }, nextActions);
          }).then (() => {
            disabledControls.forEach ((_) => _.removeAttribute ('disabled'));
            customControls.forEach ((_) => _.removeAttribute ('disabled'));
            as.end ({ok: true});
          }).catch ((e) => {
            disabledControls.forEach ((_) => _.removeAttribute ('disabled'));
            customControls.forEach ((_) => _.removeAttribute ('disabled'));
            as.end ({error: e});
          });
          return false;
        }; // onsubmit
      }, // sdInit
      sdCheck: function () {
        if (!this.hasAttribute ('action')) {
          console.log (this, 'Warning: form[is=save-data] does not have |action| attribute');
        }
        if (this.method !== 'post') {
          console.log (this, 'Warning: form[is=save-data] does not have |method| attribute whose value is |POST|');
        }
        if (this.hasAttribute ('enctype') &&
            this.enctype !== 'multipart/form-data') {
          console.log (this, 'Warning: form[is=save-data] have |enctype| attribute which is ignored');
        }
        if (this.hasAttribute ('target')) {
          console.log (this, 'Warning: form[is=save-data] have a |target| attribute');
        }
        if (this.hasAttribute ('onsubmit')) {
          console.log (this, 'Warning: form[is=save-data] have an |onsubmit| attribute');
        }
      }, // sdCheck
    }, // props
  }); // <form is=save-data>

  defs.saver.form = function (fd) {
    return fetch (this.action, {
      credentials: 'same-origin',
      method: 'POST',
      referrerPolicy: 'same-origin',
      body: fd,
    }).then ((res) => {
      if (res.status !== 200) throw res;
      return res;
    });
  }; // form

  defs.formsaved.reset = function (args) {
    this.reset ();
  }; // reset

  defs.formsaved.go = function (args) {
    return args.json ().then ((json) => {
      location.href = $fill.string (args.args[1], json);
      return new Promise (() => {});
    });
  }; // go

  defineElement ({
    name: 'before-unload-check',
    props: {
      pcInit: function () {
        window.addEventListener ('beforeunload', (ev) => {
          if (document.querySelector ('form[data-pc-modified]')) {
            ev.returnValue = '!';
          }
        });
        // XXX on disconnect
      }, // pcInit
    },
  }); // <before-unload-check>

  defineElement ({
    name: 'input-tzoffset',
    props: {
      pcInit: function () {
        this.setAttribute ('formcontrol', '');
        
        new MutationObserver ((mutations) => {
          this.pcRender ();
        }).observe (this, {childList: true});
        this.pcRequestRender ();

        var value = this.value !== undefined ? this.value : parseFloat (this.getAttribute ('value'));
        if (!Number.isFinite (value)) {
          if (this.hasAttribute ('platformvalue')) {
            value = -(new Date).getTimezoneOffset () * 60;
          } else {
            value = 0;
          }
        }
        Object.defineProperty (this, 'value', {
          get: () => value,
          set: (newValue) => {
            newValue = parseFloat (newValue);
            if (Number.isFinite (newValue) && value !== newValue) {
              value = newValue;
              this.pcRequestRender ();
            }
          },
        });
      }, // pcInit
      pcRequestRender: function () {
        this.pcRenderTimer = setTimeout (() => this.pcRender (), 0);
      }, // pcRequestRender
      pcRender: function () {
        var value = this.value;
        this.querySelectorAll ('select').forEach (c => {
          c.value = value >= 0 ? '+1' : '-1';
          c.required = true;
          c.onchange = () => {
            var v = this.value;
            if (c.value === '+1') {
              if (v < 0) this.value = -v;
            } else {
              if (v > 0) this.value = -v;
            }
          };
        });
        this.querySelectorAll ('input[type=time]').forEach (c => {
          c.valueAsNumber = (value >= 0 ? value : -value)*1000;
          c.required = true;
          c.onchange = () => {
            this.value = (this.value >= 0 ? c.valueAsNumber : -c.valueAsNumber) / 1000;
          };
        });
        this.querySelectorAll ('time').forEach (t => {
          t.setAttribute ('data-tzoffset', value);
        });

        this.querySelectorAll ('enum-value[data-tzoffset-type=sign]').forEach (t => {
          t.setAttribute ('value', value >= 0 ? 'plus' : 'minus');
        });
        this.querySelectorAll ('unit-number[data-tzoffset-type=time]').forEach (t => {
          t.setAttribute ('value', value >= 0 ? value : -value);
        });
        
        var pfValue = -(new Date).getTimezoneOffset () * 60;
        var pfDelta = value - pfValue;
        this.querySelectorAll ('enum-value[data-tzoffset-type=platformdelta-sign]').forEach (t => {
          t.setAttribute ('value', pfDelta >= 0 ? 'plus' : 'minus');
        });
        this.querySelectorAll ('unit-number[data-tzoffset-type=platformdelta-time]').forEach (t => {
          t.setAttribute ('value', pfDelta >= 0 ? pfDelta : -pfDelta);
        });
      }, // pcRender
      pcModifyFormData: function (fd) {
        var name = this.getAttribute ('name');
        if (!name) return;
        fd.append (name, this.value);
      }, // pcModifyFormData
    },
  }); // <input-tzoffset>
  defs.filltype["input-tzoffset"] = 'idlattribute';

  defineElement ({
    name: 'input-datetime',
    props: {
      pcInit: function () {
        this.setAttribute ('formcontrol', '');
        
        new MutationObserver ((mutations) => {
          this.pcRender ();
        }).observe (this, {childList: true});
        this.pcRequestRender ();

        var mo = new MutationObserver (() => {
          var newValue = parseFloat (this.getAttribute ('tzoffset'));
          if (Number.isFinite (newValue) && newValue !== this.pcValueTZ) {
            var v = this.value;
            this.pcValueTZ = newValue;
            setValue (v);
          }
        });
        mo.observe (this, {attributes: true, attributeFilter: ['tzoffset']});

        this.pcValueTZ = parseFloat (this.getAttribute ('tzoffset'));
        if (!Number.isFinite (this.pcValueTZ)) {
          this.pcValueTZ = -(new Date).getTimezoneOffset () * 60;
        }
        var setValue = (newValue) => {
          var d = new Date ((newValue + this.pcValueTZ) * 1000);
          this.pcValueDate = Math.floor (d.valueOf () / (24 * 60 * 60 * 1000)) * 24 * 60 * 60;
          this.pcValueTime = d.valueOf () / 1000 - this.pcValueDate;
          this.pcRequestRender ();
        }; // setValue
        
        var value = this.value !== undefined ? this.value : parseFloat (this.getAttribute ('value'));
        if (!Number.isFinite (value)) {
          setValue ((new Date).valueOf () / 1000); // now
          this.pcValueTime = 0;
        } else {
          setValue (value);
        }
        
        Object.defineProperty (this, 'value', {
          get: () => this.pcValueDate + this.pcValueTime - this.pcValueTZ,
          set: (newValue) => {
            newValue = parseFloat (newValue);
            if (Number.isFinite (newValue)) {
              setValue (newValue);
            }
          },
        });
      }, // pcInit
      pcRequestRender: function () {
        this.pcRenderTimer = setTimeout (() => this.pcRender (), 0);
      }, // pcRequestRender
      pcRender: function () {
        this.querySelectorAll ('input[type=date]').forEach (c => {
          c.valueAsNumber = this.pcValueDate * 1000;
          c.required = true;
          c.onchange = () => {
            this.pcValueDate = Math.floor (c.valueAsNumber / 1000);
            this.pcRequestRender ();
          };
        });
        this.querySelectorAll ('input[type=time]').forEach (c => {
          c.valueAsNumber = this.pcValueTime * 1000;
          c.required = true;
          c.onchange = () => {
            this.pcValueTime = c.valueAsNumber / 1000;
            this.pcRequestRender ();
          };
        });
        var valueDate = new Date (this.value * 1000);
        this.querySelectorAll ('time').forEach (t => {
          t.setAttribute ('datetime', valueDate.toISOString ());
        });
        
        this.querySelectorAll ('button[data-dt-type]').forEach (t => {
          t.onclick = () => this.pcHandleButton (t);
        });
      }, // pcRender
      pcHandleButton: function (button) {
        var type = button.getAttribute ('data-dt-type');
        if (type === 'set') {
          this.value = button.value;
        } else if (type === 'set-now') {
          this.value = (new Date).valueOf () / 1000;
        } else if (type === 'set-today') {
          var now = new Date;
          var lDay = new Date (now.toISOString ().replace (/T.*/, 'T00:00'));
          var uDay = new Date (now.toISOString ().replace (/T.*/, 'T00:00Z'));
          var delta = -now.getTimezoneOffset () * 60 - this.pcValueTZ;
          var time = (now.valueOf () - lDay.valueOf ()) / 1000;
          if (time >= delta) {
            this.value = uDay.valueOf () / 1000 - this.pcValueTZ;
          } else {
            this.value = uDay.valueOf () / 1000 - this.pcValueTZ - 24*60*60;
          }
        } else {
          throw new Error ('Unknown type: button[data-dt-type="'+type+'"]');
        }
        setTimeout (() => {
          this.dispatchEvent (new Event ('change', {bubbles: true}));
        }, 0);
      }, // pcHandleButton
      pcModifyFormData: function (fd) {
        var name = this.getAttribute ('name');
        if (!name) return;
        fd.append (name, this.value);
      }, // pcModifyFormData
    },
  }); // <input-datetime>
  defs.filltype["input-datetime"] = 'idlattribute';
  
  defineElement ({
    name: 'image-editor',
    props: {
    pcInit: function () {
      this.ieResize ({resizeEvent: true});
      var mo = new MutationObserver ((mutations) => {
        var resized = false;
        mutations.forEach ((mutation) => {
          if (mutation.attributeName === 'width' ||
              mutation.attributeName === 'height') {
            if (!resized) {
              resized = true;
              this.ieResize ({resizeEvent: true, changeEvent: true});
            }
          }
        });
      });
      mo.observe (this, {attributes: true, attributeFilter: ['width', 'height']});

      new MutationObserver (function (mutations) {
        mutations.forEach (function (m) {
          Array.prototype.forEach.call (m.addedNodes, function (e) {
            if (e.nodeType === e.ELEMENT_NODE &&
                e.localName === 'image-layer') {
              upgrade (e);
            }
          });
        });
      }).observe (this, {childList: true});
      Array.prototype.slice.call (this.children).forEach ((e) => {
        if (e.localName === 'image-layer') {
          Promise.resolve (e).then (upgrade);
        }
      });

      if (this.hasAttribute ('data-onresize')) {
        this.setAttribute ('onresize', this.getAttribute ('data-onresize'));
      }
    }, // pcInit

    ieResize: function (opts) {
      var width = 0;
      var height = 0;
      var fixedWidth = parseFloat (this.getAttribute ('width'));
      var fixedHeight = parseFloat (this.getAttribute ('height'));
      if (!(fixedWidth > 0) || !(fixedHeight > 0)) {
        Array.prototype.slice.call (this.children).forEach ((e) => {
          var w = e.left + e.width;
          var h = e.top + e.height;
          if (w > width) width = w;
          if (h > height) height = h;
        });
        width = width || 300;
        height = height || 150;
      }
      if (fixedWidth > 0) width = fixedWidth;
      if (fixedHeight > 0) height = fixedHeight;
      var resize = opts.resizeEvent && (this.width !== width || this.height !== height);
      this.width = width;
      this.height = height;
      this.style.width = width + 'px';
      this.style.height = height + 'px';
      if (resize) {
        Promise.resolve ().then (() => {
          this.dispatchEvent (new Event ('resize', {bubbles: true}));
        });
      }
      if (opts.changeEvent) {
        Promise.resolve ().then (() => {
          this.dispatchEvent (new Event ('change', {bubbles: true}));
        });
      }
    }, // ieResize

    ieCanvasToBlob: function (type, quality) {
      return new Promise ((ok) => {
        var canvas = document.createElement ('canvas');
        canvas.width = Math.ceil (this.width);
        canvas.height = Math.ceil (this.height);
        var context = canvas.getContext ('2d');
        Array.prototype.slice.call (this.children).forEach ((e) => {
          if (e.localName === 'image-layer' && e.pcUpgraded) {
            context.drawImage (e.ieCanvas, e.left, e.top, e.width, e.height);
          }
        });
        if (canvas.toBlob) {
          return canvas.toBlob (ok, type, quality);
        } else {
          var decoded = atob (canvas.toDataURL (type, quality).split (',')[1]);
          var byteLength = decoded.length;
          var view = new Uint8Array (byteLength);
          for (var i = 0; i < byteLength; i++) {
            view[i] = decoded.charCodeAt (i);
          }
          ok (new Blob ([view], {type: type || 'image/png'}));
        }
      });
    }, // ieCanvasToBlob
    getPNGBlob: function () {
      return this.ieCanvasToBlob ('image/png');
    }, // getPNGBlob
    getJPEGBlob: function () {
      return this.ieCanvasToBlob ('image/jpeg');
    }, // getJPEGBlob
    },
  }); // image-editor

  defineElement ({
    name: 'image-layer',
    notTopLevel: true,
    props: {
    pcInit: function () {
      this.ieCanvas = document.createElement ('canvas');
      this.appendChild (this.ieCanvas);
      if (this.parentNode) {
        this.ieCanvas.width = this.parentNode.width;
        this.ieCanvas.height = this.parentNode.height;
      }
      this.ieTogglePlaceholder (true);

      // XXX not tested
      var mo = new MutationObserver (function (mutations) {
        mutations.forEach ((mutation) => {
          if (mutation.attributeName === 'movable' ||
              mutation.attributeName === 'useplaceholder') {
            this.ieTogglePlaceholder (null);
          }
        });
      });
      mo.observe (this, {attributes: true, attributeFilter: ['movable', 'useplaceholder']});

      this.top = 0;
      this.left = 0;
      this.ieScaleFactor = 1.0;
      this.width = this.ieCanvas.width /* * this.ieScalerFactor */;
      this.height = this.ieCanvas.height /* * this.ieScaleFactor */;
      if (this.parentNode && this.parentNode.ieResize) this.parentNode.ieResize ({});
      this.dispatchEvent (new Event ('resize', {bubbles: true}));
      this.dispatchEvent (new Event ('change', {bubbles: true}));
    }, // pcInit

    cbCommands: {
      startCaptureMode: {},
      endCaptureMode: {},
      selectImageFromCaptureModeAndEndCaptureMode: {},
      
      selectImageFromFile: {},

      rotateClockwise: {},
      rotateCounterclockwise: {},
    },

    ieSetClickMode: function (mode) {
      if (mode === this.ieClickMode) return;
      if (mode === 'selectImage') {
        this.ieClickMode = mode;
        // XXX We don't have tests of this behavior...
        this.ieClickListener = (ev) => this.selectImageFromFile ().catch ((e) => {
          var ev = new Event ('error', {bubbles: true});
          ev.exception = e;
          var notHandled = this.dispatchEvent (ev);
          if (notHandled) throw e;
        });
        this.addEventListener ('click', this.ieClickListener);
      } else if (mode === 'none') { 
        this.ieClickMode = mode;
        if (this.ieClickListener) {
          this.removeEventListener ('click', this.ieClickListener);
          delete this.ieClickListener;
        }
      } else {
        throw new Error ("Bad mode |"+mode+"|");
      }
    }, // ieSetClickMode
    ieSetDnDMode: function (mode) {
      if (this.ieDnDMode === mode) return;
      if (mode === 'selectImage') {
        this.ieDnDMode = mode;
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
        this.ieDnDdragenterHandler = (ev) => {
          targetted++;
          if (!setDropEffect (ev.dataTransfer)) {
            this.classList.add ('drop-target');
            ev.preventDefault ();
          }
        };
        this.ieDnDdragoverHandler = (ev) => {
          if (!setDropEffect (ev.dataTransfer)) ev.preventDefault ();
        };
        this.ieDnDdragleaveHandler = (ev) => {
          targetted--;
          if (targetted <= 0) {
            this.classList.remove ('drop-target');
          }
        };
        this.ieDnDdropHandler = (ev) => {
          this.classList.remove ('drop-target');
          targetted = 0;
        
          var file = ev.dataTransfer.files[0];
          if (file) {
            this.ieSetImageFile (file).catch ((e) => {
              var ev = new Event ('error', {bubbles: true});
              ev.exception = e;
              return Promise.resolve.then (() => {
                var notHandled = this.dispatchEvent (ev);
                if (notHandled) throw e;
              });
            });
          }
          ev.preventDefault ();
        };
        // XXX We don't have tests of DnD...
        this.addEventListener ('dragenter', this.ieDnDdragenterHandler);
        this.addEventListener ('dragover', this.ieDnDdragoverHandler);
        this.addEventListener ('dragleave', this.ieDnDdragleaveHandler);
        this.addEventListener ('drop', this.ieDnDdropHandler);
      } else if (mode === 'none') {
        this.ieDnDMode = mode;
        if (this.ieDnDdragenterHandler) {
          this.removeEventListener ('dragenter', this.ieDnDdragenterHandler);
          this.removeEventListener ('dragover', this.ieDnDdragoverHandler);
          this.removeEventListener ('dragleave', this.ieDnDdragleaveHandler);
          this.removeEventListener ('drop', this.ieDnDdropHandler);
          delete this.ieDnDdragenterHandler;
          delete this.ieDnDdragoverHandler;
          delete this.ieDnDdragleaveHandler;
          delete this.ieDnDdropHandler;
        }
      } else {
        throw new Error ("Bad mode |"+mode+"|");
      }
    }, // ieSetDnDMode
    ieSetMoveMode: function (mode) {
      if (this.ieMoveMode === mode) return;
      if (mode === 'editOffset') {
        this.ieMoveMode = mode;
        var dragging = null;
        this.ieMouseDownHandler = (ev) => {
          dragging = [this.left, this.top,
                      this.offsetLeft + ev.offsetX,
                      this.offsetTop + ev.offsetY];
        };
        this.ieMouseMoveHandler = (ev) => {
          if (dragging) {
            this.ieMove (
              dragging[0] + this.offsetLeft + ev.offsetX - dragging[2],
              dragging[1] + this.offsetTop + ev.offsetY - dragging[3],
            );
          }
        };
        this.ieMouseUpHandler = (ev) => dragging = null;
        this.ieKeyDownHandler = (ev) => {
          if (dragging) return;
          if (ev.keyCode === 38) {
            this.ieMove (this.left, this.top-1);
            ev.preventDefault ();
          } else if (ev.keyCode === 39) {
            this.ieMove (this.left+1, this.top);
            ev.preventDefault ();
          } else if (ev.keyCode === 40) {
            this.ieMove (this.left, this.top+1);
            ev.preventDefault ();
          } else if (ev.keyCode === 37) {
            this.ieMove (this.left-1, this.top);
            ev.preventDefault ();
          }
        };
        // XXX we don't have tests of dnd and keyboard operations
        var m = this.ieMoveContainer = this;
        m.addEventListener ('mousedown', this.ieMouseDownHandler);
        m.addEventListener ('mousemove', this.ieMouseMoveHandler);
        window.addEventListener ('mouseup', this.ieMouseUpHandler);
        m.addEventListener ('keydown', this.ieKeyDownHandler);
        m.tabIndex = 0;
      } else if (mode === 'none') {
        var m = this.ieMoveContainer;
        if (m) {
          m.removeEventListener ('mousedown', this.ieMouseDownHandler);
          m.removeEventListener ('mousemove', this.ieMouseMoveHandler);
          window.removeEventListener ('mouseup', this.ieMouseUpHandler);
          m.removeEventListener ('keydown', this.ieKeyDownHandler);
          delete this.ieMouseDownHandler;
          delete this.ieMouseMoveHandler;
          delete this.ieMouseUpHandler;
          delete this.ieKeyDownHandler;
          delete this.ieMoveContainer;
        }
      } else {
        throw new Error ("Bad mode |"+mode+"|");
      }
    }, // ieSetMoveMode

    // XXX not tested
    startCaptureMode: function () {
      if (this.ieEndCaptureMode) return;
      this.ieEndCaptureMode = () => {};

      var videoWidth = this.width;
      var videoHeight = this.height;
      var TimeoutError = function () {
        this.name = "TimeoutError";
        this.message = "Camera timeout";
      };
      var run = () => {
        return navigator.mediaDevices.getUserMedia ({video: {
          width: videoWidth, height: videoHeight,
          //XXX facingMode: opts.facingMode, // |user| or |environment|
        }, audio: false}).then ((stream) => {
          var video;
          var cancelTimer;
          this.ieEndCaptureMode = function () {
            stream.getVideoTracks ()[0].stop ();
            delete this.ieCaptureNow;
            if (video) video.remove ();
            clearTimeout (cancelTimer);
            delete this.ieEndCaptureMode;
          };

          return new Promise ((ok, ng) => {
            video = document.createElement ('video');
            video.classList.add ('capture');
            video.onloadedmetadata = (ev) => {
              if (!this.ieEndCaptureMode) return;

              video.play ();
              this.ieCaptureNow = function () {
                return this.ieSelectImageByElement (video, videoWidth, videoHeight);
              };
              ok ();
              clearTimeout (cancelTimer);
            };
            video.srcObject = stream;
            this.appendChild (video);
            cancelTimer = setTimeout (() => {
              ng (new TimeoutError);
              if (this.ieEndCaptureMode) this.ieEndCaptureMode ();
            }, 500);
          });
        });
      }; // run
      var tryCount = 0;
      var tryRun = () => {
        return run ().catch ((e) => {
          // Some browser with some camera device sometimes (but not
          // always) fails to fire loadedmetadata...
          if (e instanceof TimeoutError && tryCount++ < 10) {
            return tryRun ();
          } else {
            throw e;
          }
        });
      };
      tryRun ();
    }, // startCaptureMode
    endCaptureMode: function () {
      if (this.ieEndCaptureMode) this.ieEndCaptureMode ();
    }, // endCaptureMode

    ieTogglePlaceholder: function (newValue) {
      if (newValue === null) newValue = this.classList.contains ("placeholder");
      if (newValue) { // is placeholder
        this.classList.add ('placeholder');
        if (this.hasAttribute ('useplaceholderui')) {
          this.ieSetClickMode ('selectImage');
          this.ieSetDnDMode ('selectImage');
          this.ieSetMoveMode ('none');
        } else {
          this.ieSetClickMode ('none');
          this.ieSetDnDMode ('none');
          this.ieSetMoveMode (this.hasAttribute ('movable') ? 'editOffset' : 'none');
        }
      } else { // is image
        this.classList.remove ('placeholder');
        this.ieSetClickMode ('none');
        this.ieSetDnDMode ('none');
        this.ieSetMoveMode (this.hasAttribute ('movable') ? 'editOffset' : 'none');
      }
    }, // ieTogglePlaceholder      

    ieSelectImageByElement: function (element, width, height) {
      var ev = new Event ('pcImageSelect', {bubbles: true});
      ev.element = element;
      this.dispatchEvent (ev);

      this.ieCanvas.width = width;
      this.ieCanvas.height = height;
      var context = this.ieCanvas.getContext ('2d');
      context.drawImage (element, 0, 0, width, height);
      this.ieUpdateDimension ();
      this.ieTogglePlaceholder (false);
      return Promise.resolve ();
    }, // ieSelectImageByElement
    selectImageByURL: function (url) {
      return new Promise ((ok, ng) => {
        var img = document.createElement ('img');
        img.src = url;
        img.onload = function () {
          ok (img);
        };
        img.onerror = (ev) => {
          var e = new Error ('Failed to load the image <'+img.src+'>');
          e.name = 'ImageLoadError';
          ng (e);
        };
      }).then ((img) => {
        return this.ieSelectImageByElement (img, img.naturalWidth, img.naturalHeight);
      });
    }, // selectImageByURL
    ieSetImageFile: function (file) {
      var url = URL.createObjectURL (file);
      return this.selectImageByURL (url).then (() => {
        URL.revokeObjectURL (url);
      }, (e) => {
        URL.revokeObjectURL (url);
        throw e;
      });
    }, // ieSetImageFile
    // XXX We don't have tests of this method >_<
    selectImageFromFile: function () {
      if (this.ieFileCancel) this.ieFileCancel ();
      return new Promise ((ok, ng) => {
        var input = document.createElement ('input');
        input.type = 'file';
        input.accept = 'image/*';
        this.ieFileCancel = () => {
          ng (new DOMException ("The user does not choose a file", "AbortError"));
          delete this.ieFileCancel;
        };
        input.onchange = () => {
          if (input.files[0]) {
            ok (input.files[0]);
          } else {
            // This is unlikely called.  There is no way to hook on "cancel".
            this.ieFileCancel ();
          }
        };
        input.click ();
      }).then ((file) => {
        return this.ieSetImageFile (file);
      });
    }, // selectImageFromFile
    // XXX not tested
    selectImageFromCaptureModeAndEndCaptureMode: function () {
      if (!this.ieCaptureNow) {
        return Promise.reject (new Error ("Capturing is not available"));
      }
      return this.ieCaptureNow ().then (() => {
        this.endCaptureMode ();
      });
    }, // selectImageFromCaptureModeAndEndCaptureMode


    ieRotateByDegree: function (degree) {
      var canvas = document.createElement ('canvas');
      canvas.width = this.ieCanvas.height;
      canvas.height = this.ieCanvas.width;
      var context = canvas.getContext ('2d');
      context.translate (canvas.width / 2, canvas.height / 2);
      context.rotate (degree * 2 * Math.PI / 360);
      context.drawImage (this.ieCanvas, -canvas.height / 2, -canvas.width / 2);
      context.resetTransform ();
      this.replaceChild (canvas, this.ieCanvas);
      this.ieCanvas = canvas;
      this.ieUpdateDimension ();
    }, // ieRotateByDegree
    rotateClockwise: function () {
      return this.ieRotateByDegree (90);
    }, // rotateClockwise
    rotateCounterclockwise: function () {
      return this.ieRotateByDegree (-90);
    }, // rotateCounterclockwise

    ieMove: function (x, y) {
      this.left = x;
      this.top = y;
      this.style.left = this.left + "px";
      this.style.top = this.top + "px";
      if (!this.ieMoveTimer) {
        this.ieMoveTimer = setTimeout (() => {
          if (this.parentNode && this.parentNode.ieResize) this.parentNode.ieResize ({resizeEvent: true, changeEvent: true});
          this.ieMoveTimer = null;
        }, 100);
      }
    }, // ieMove
    ieUpdateDimension: function () {
      var oldWidth = this.width;
      var oldHeight = this.height;
      if (this.getAttribute ('anchorpoint') === 'center') {
        var x = this.left + this.width / 2;
        var y = this.top + this.height / 2;
        this.width = this.ieCanvas.width * this.ieScaleFactor;
        this.height = this.ieCanvas.height * this.ieScaleFactor; 
        this.left = x - this.width / 2;
        this.top = y - this.height / 2;
        this.style.left = this.left + "px";
        this.style.top = this.top + "px";
      } else {
        this.width = this.ieCanvas.width * this.ieScaleFactor;
        this.height = this.ieCanvas.height * this.ieScaleFactor;
      }
      this.ieCanvas.style.width = this.width + "px";
      this.ieCanvas.style.height = this.height + "px";
      if (oldWidth !== this.width || oldHeight !== this.height) {
        if (this.parentNode && this.parentNode.ieResize) this.parentNode.ieResize ({});

        this.dispatchEvent (new Event ('resize', {bubbles: true}));
      }
      this.dispatchEvent (new Event ('change', {bubbles: true}));
    }, // ieUpdateDimension

    setScale: function (newScale) {
      if (this.ieScaleFactor === newScale) return;
      this.ieScaleFactor = newScale;
      this.ieUpdateDimension ();
    }, // setScale
    },
  }); // image-layer

  (document.currentScript.getAttribute ('data-export') || '').split (/\s+/).filter ((_) => { return _.length }).forEach ((name) => {
    self[name] = exportable[name];
  });
}) ();

/*

Copyright 2017-2019 Wakaba <wakaba@suikawiki.org>.

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
function TER (c) {
  this.container = c;
  this._initialize ();
} // TER

(function () {

  /* Based on HTML Standard's definition of "global date and time
     string", but allows Unicode 5.1.0 White_Space where it was
     allowed in earlier drafts of HTML5. */
  var globalDateAndTimeStringPattern = /^([0-9]{4,})-([0-9]{2})-([0-9]{2})(?:[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]+(?:T[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]*)?|T[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]*)([0-9]{2}):([0-9]{2})(?::([0-9]{2})(?:\.([0-9]+))?)?[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]*(?:Z|([+-])([0-9]{2}):([0-9]{2}))$/;

  /* HTML Standard's definition of "date string" */
  var dateStringPattern = /^([0-9]{4,})-([0-9]{2})-([0-9]{2})$/;

  function parseTimeElement (el) {
    var datetime = el.getAttribute ('datetime');
    if (datetime === null) {
      datetime = el.textContent;

      /* Unicode 5.1.0 White_Space */
      datetime = datetime.replace
                     (/^[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]+/, '')
                         .replace
                     (/[\u0009-\u000D\u0020\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]+$/, '');
    }

    if (m = datetime.match (globalDateAndTimeStringPattern)) {
      if (m[1] < 100) {
        return new Date (NaN);
      } else if (m[8] && (m[9] > 23 || m[9] < -23)) {
        return new Date (NaN);
      } else if (m[8] && m[10] > 59) {
        return new Date (NaN);
      }
      var d = new Date (Date.UTC (m[1], m[2] - 1, m[3], m[4], m[5], m[6] || 0));
      if (m[1] != d.getUTCFullYear () ||
          m[2] != d.getUTCMonth () + 1 ||
          m[3] != d.getUTCDate () ||
          m[4] != d.getUTCHours () ||
          m[5] != d.getUTCMinutes () ||
          (m[6] || 0) != d.getUTCSeconds ()) {
        return new Date (NaN); // bad date error.
      }
      if (m[7]) {
        var ms = (m[7] + "000").substring (0, 3);
        d.setMilliseconds (ms);
      }
      if (m[9] != null) {
        var offset = parseInt (m[9], 10) * 60 + parseInt (m[10], 10);
        offset *= 60 * 1000;
        if (m[8] == '-') offset *= -1;
        d = new Date (d.valueOf () - offset);
      }
      d.hasDate = true;
      d.hasTime = true;
      d.hasTimezone = true;
      return d;
    } else if (m = datetime.match (dateStringPattern)) {
      if (m[1] < 100) {
        return new Date (NaN);
      }
      /* For old browsers (which don't support the options parameter
         of `toLocaleDateString` method) the time value is set to
         12:00, so that most cases are covered. */
      var d = new Date (Date.UTC (m[1], m[2] - 1, m[3], 12, 0, 0));
      if (m[1] != d.getUTCFullYear () ||
          m[2] != d.getUTCMonth () + 1 ||
          m[3] != d.getUTCDate ()) {
        return new Date (NaN); // bad date error.
      }
      d.hasDate = true;
      return d;
    } else {
      return new Date (NaN);
    }
  } // parseTimeElement

  function setDateContent (el, date) {
    if (!el.getAttribute ('title')) {
      el.setAttribute ('title', el.textContent);
    }
    if (!el.getAttribute ('datetime')) {
      var r = '';
      r = date.getUTCFullYear (); // JS does not support years 0001-0999
      r += '-' + ('0' + (date.getUTCMonth () + 1)).slice (-2);
      r += '-' + ('0' + date.getUTCDate ()).slice (-2);
      el.setAttribute ('datetime', r);
    }
    el.textContent = date.toLocaleDateString (navigator.language, {"timeZone": "UTC"});
  } // setDateContent

  function setMonthDayDateContent (el, date) {
    if (!el.getAttribute ('title')) {
      el.setAttribute ('title', el.textContent);
    }
    if (!el.getAttribute ('datetime')) {
      var r = '';
      r = date.getUTCFullYear (); // JS does not support years 0001-0999
      r += '-' + ('0' + (date.getUTCMonth () + 1)).slice (-2);
      r += '-' + ('0' + date.getUTCDate ()).slice (-2);
      el.setAttribute ('datetime', r);
    }

    var lang = navigator.language;
    if (new Date ().toLocaleString (lang, {timeZone: 'UTC', year: "numeric"}) ===
        date.toLocaleString (lang, {timeZone: 'UTC', year: "numeric"})) {
      el.textContent = date.toLocaleDateString (lang, {
        "timeZone": "UTC",
        month: "numeric",
        day: "numeric",
      });
    } else {
      el.textContent = date.toLocaleDateString (lang, {
        "timeZone": "UTC",
      });
    }
  } // setDateContent

  function setDateTimeContent (el, date) {
    if (!el.getAttribute ('title')) {
      el.setAttribute ('title', el.textContent);
    }
    if (!el.getAttribute ('datetime')) {
      // XXX If year is outside of 1000-9999, ...
      el.setAttribute ('datetime', date.toISOString ());
    }

    var tzoffset = el.getAttribute ('data-tzoffset');
    if (tzoffset !== null) {
      tzoffset = parseFloat (tzoffset);
      el.textContent = new Date (date.valueOf () + date.getTimezoneOffset () * 60 * 1000 + tzoffset * 1000).toLocaleString (navigator.language, {
        year: "numeric",
        month: "numeric",
        day: "numeric",
        hour: "numeric",
        minute: "numeric",
        second: "numeric",
      });
    } else {
      el.textContent = date.toLocaleString ();
    }
  } // setDateTimeContent

  function setAmbtimeContent (el, date) {
    if (!el.getAttribute ('title')) {
      el.setAttribute ('title', el.textContent);
    }
    if (!el.getAttribute ('datetime')) {
      // XXX If year is outside of 1000-9999, ...
      el.setAttribute ('datetime', date.toISOString ());
    }

    var text = TER.Delta.prototype.text;
    var dateValue = date.valueOf ();
    var nowValue = new Date ().valueOf ();

    var diff = dateValue - nowValue;
    if (diff < 0) diff = -diff;

    if (diff == 0) {
      el.textContent = text.now ();
      return;
    }

    var v;
    diff = Math.floor (diff / 1000);
    if (diff < 60) {
      v = text.second (diff);
    } else {
      var f = diff;
      diff = Math.floor (diff / 60);
      if (diff < 60) {
        v = text.minute (diff);
        f -= diff * 60;
        if (f > 0) v += text.sep () + text.second (f);
      } else {
        f = diff;
        diff = Math.floor (diff / 60);
        if (diff < 50) {
          v = text.hour (diff);
          f -= diff * 60;
          if (f > 0) v += text.sep () + text.minute (f);
        } else {
          f = diff;
          diff = Math.floor (diff / 24);
          if (diff < 100) {
            v = text.day (diff);
            f -= diff * 24;
            if (f > 0) v += text.sep () + text.hour (f);
          } else {
            return setDateTimeContent (el, date);
          }
        }
      }
    }

    if (dateValue < nowValue) {
      v = text.before (v);
    } else {
      v = text.after (v);
    }
    el.textContent = v;
  } // setAmbtimeContent

TER.prototype._initialize = function () {
  if (this.container.localName === 'time') {
    this._initTimeElement (this.container);
  } else {
    var els = this.container.getElementsByTagName ('time');
    var elsL = els.length;
    for (var i = 0; i < elsL; i++) {
      var el = els[i];
      if (!el) break; /* If <time> is nested */
      this._initTimeElement (el);
    }
  }
}; // TER.prototype._initialize

  TER.prototype._initTimeElement = function (el) {
    if (el.terUpgraded) return;
    el.terUpgraded = true;
    
    var self = this;
    this._replaceTimeContent (el);
    new MutationObserver (function (mutations) {
      self._replaceTimeContent (el);
    }).observe (el, {attributeFilter: ['data-tzoffset']});
  }; // _initTimeElement

  TER.prototype._replaceTimeContent = function (el) {
    var date = parseTimeElement (el);
    if (isNaN (date.valueOf ())) return;
    if (date.hasTimezone) { /* full date */
      setDateTimeContent (el, date);
    } else if (date.hasDate) {
      setDateContent (el, date);
    }
  }; // _replaceTimeContent

  TER.Delta = function (c) {
    TER.apply (this, [c]);
  }; // TER.Delta
  TER.Delta.prototype = new TER (document.createElement ('time'));

  TER.Delta.prototype._replaceTimeContent = function (el) {
    var date = parseTimeElement (el);
    if (isNaN (date.valueOf ())) return;
    if (date.hasTimezone) { /* full date */
      setAmbtimeContent (el, date);
    } else if (date.hasDate) {
      setDateContent (el, date);
    }
  }; // _replaceTimeContent

  (function (selector) {
    if (!selector) return;

    var replaceContent = function (el) {
      var date = parseTimeElement (el);
      if (isNaN (date.valueOf ())) return;
      var format = el.getAttribute ('data-format');
      if (format === 'datetime') {
        setDateTimeContent (el, date);
      } else if (format === 'date') {
        setDateContent (el, date);
      } else if (format === 'monthday') {
        setMonthDayDateContent (el, date);
      } else if (format === 'ambtime') {
        setAmbtimeContent (el, date);
      } else { // auto
        if (date.hasTimezone) { /* full date */
          setDateTimeContent (el, date);
        } else if (date.hasDate) {
          setDateContent (el, date);
        }
      }
    }; // replaceContent
    
    var op = function (el) {
      if (el.terUpgraded) return;
      el.terUpgraded = true;

      replaceContent (el);
      new MutationObserver (function (mutations) {
        replaceContent (el);
      }).observe (el, {attributeFilter: ['datetime', 'data-tzoffset']});
    }; // op
    
    var mo = new MutationObserver (function (mutations) {
      mutations.forEach (function (m) {
        Array.prototype.forEach.call (m.addedNodes, function (e) {
          if (e.nodeType === e.ELEMENT_NODE) {
            if (e.matches && e.matches (selector)) op (e);
            Array.prototype.forEach.call (e.querySelectorAll (selector), op);
          }
        });
      });
    });
    mo.observe (document, {childList: true, subtree: true});
    Array.prototype.forEach.call (document.querySelectorAll (selector), op);

  }) (document.currentScript.getAttribute ('data-time-selector') ||
      document.currentScript.getAttribute ('data-selector') /* backcompat */);
}) ();

TER.Delta.Text = {};

TER.Delta.Text.en = {
  day: function (n) {
    return n + ' day' + (n == 1 ? '' : 's');
  },
  hour: function (n) {
    return n + ' hour' + (n == 1 ? '' : 's');
  },
  minute: function (n) {
    return n + ' minute' + (n == 1 ? '' : 's');
  },
  second: function (n) {
    return n + ' second' + (n == 1 ? '' : 's');
  },
  before: function (s) {
    return s + ' ago';
  },
  after: function (s) {
    return 'in ' + s;
  },
  now: function () {
    return 'just now';
  },
  sep: function () {
    return ' ';
  }
};

TER.Delta.Text.ja = {
  day: function (n) {
    return n + '日';
  },
  hour: function (n) {
    return n + '時間';
  },
  minute: function (n) {
    return n + '分';
  },
  second: function (n) {
    return n + '秒';
  },
  before: function (s) {
    return s + '前';
  },
  after: function (s) {
    return s + '後';
  },
  now: function () {
    return '今';
  },
  sep: function () {
    return '';
  }
};

(function () {
  var lang = navigator.language;
  if (lang.match (/^[jJ][aA](?:-|$)/)) {
    TER.Delta.prototype.text = TER.Delta.Text.ja;
  } else {
    TER.Delta.prototype.text = TER.Delta.Text.en;
  }
})();

if (window.TEROnLoad) {
  TEROnLoad ();
}

/*

Usage:

Just insert:

  <script src="path/to/time.js" data-time-selector="time" async></script>

... where the |data-time-selector| attribute value is a selector that
only matches with |time| elements that should be processed.  Then any
|time| element matched with the selector when the script is executed,
as well as any |time| element matched with the selector inserted after
the script's execution, is processed appropriately.  E.g.:

  <time>2008-12-20T23:27+09:00</time>
  <!-- Will be rendered as a date and time in the user's locale
       dependent format, such as "20 December 2008 11:27 PM" -->

  <time>2008-12-20</time>
  <time data-format=date>2008-12-20T23:27+09:00</time>
  <!-- Will be rendered as a date in the user's locale dependent
       format, such as "20 December 2008" -->

  <time>2008-12-20</time>
  <time data-format=date>2008-12-20T23:27+09:00</time>
  <!-- Will be rendered as a date in the user's locale dependent
       format, such as "20 December 2008" but the year component is
       omitted if it is same as this year, such as "December 20" in
       case it's 2008. -->

  <time data-format=ambtime>2008-12-20T23:27+09:00</time>
  <!-- Will be rendered as an "ambtime" in English or Japanese
       depending on the user's language preference, such as "2 hours
       ago" -->

When the |time| element's |datetime| or |data-tzoffset| attribute
value is changed, the element's content is updated appropriately.
(Note that the element's content's mutation is ignored.)

For backward compatibility with previous versions of this script, if
there is no |data-time-selector| or |data-selector| attribute, the
script does nothing by default, except for defining the |TER| global
property.  By invoking |new TER (/element/)| or |new TER.Delta
(/element/)| constructor, where /element/ is an element node, any
|time| element in the /element/ subtree (or /element/ itself if it is
a |time| element) is processed appropriately.  The |TER| constructor
is equivalent to no |data-format| attribute and the |TER.Delta|
constructor is equivalent to |data-format=ambtime|.

Repository:

Latest version of this script is available in Git repository
<https://github.com/wakaba/timejs>.

Specification:

HTML Standard <https://html.spec.whatwg.org/#the-time-element>.

This script interprets "global date and time string" using older
parsing rules as defined in previous versions of the HTML spec, which
is a willful violation to the current HTML Living Standard.

*/

/* ***** BEGIN LICENSE BLOCK *****
 *
 * Copyright 2008-2019 Wakaba <wakaba@suikawiki.org>.  All rights reserved.
 *
 * Copyright 2017 Hatena <http://hatenacorp.jp/>.  All rights reserved.
 *
 * This program is free software; you can redistribute it and/or 
 * modify it under the same terms as Perl itself.
 *
 * Alternatively, the contents of this file may be used 
 * under the following terms (the "MPL/GPL/LGPL"), 
 * in which case the provisions of the MPL/GPL/LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of the MPL/GPL/LGPL, and not to allow others to
 * use your version of this file under the terms of the Perl, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the MPL/GPL/LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the Perl or the MPL/GPL/LGPL.
 *
 * "MPL/GPL/LGPL":
 *
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * <https://www.mozilla.org/MPL/>
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is TER code.
 *
 * The Initial Developer of the Original Code is Wakaba.
 * Portions created by the Initial Developer are Copyright (C) 2008
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *   Wakaba <wakaba@suikawiki.org>
 *   Hatena <http://hatenacorp.jp/>
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the LGPL or the GPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */
