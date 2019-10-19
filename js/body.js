var parentPort = null;

onmessage = function (ev) {
  if (ev.ports.length && !parentPort) {
    parentPort = ev.ports[0];
    parentPort.onmessage = handleMessage;
  }
  handleMessage (ev);
}; // onmessage

function handleMessage (ev) {
  if (ev.data.type === 'getCurrentValue') {
    var div = document.body.cloneNode (true);
    Array.prototype.slice.call (div.querySelectorAll ('[contenteditable]')).forEach (function (e) {
      e.removeAttribute ('contenteditable');
    });
    sendToParent ({type: "currentValue", value: div.innerHTML});
  } else if (ev.data.type === 'setCurrentValue') {
    document.body.textContent = '';
    document.body.setAttribute ('data-source-type', ev.data.valueSourceType || 0);
    var fragment = document.createElement ('div');
    fragment.innerHTML = ev.data.value;
    var imported = ev.data.importedSites || [];
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
    }
    $$ (fragment, 'object-ref').forEach (function (e) {
      e.setAttribute ('contenteditable', 'false');
      upgradeObjectRef (e);
    });
    document.gruwaHatenaStarMap = {};
    $$ (fragment, 'hatena-html[starmap]').forEach (function (e) {
      var values = e.getAttribute ('starmap').split (/\s+/);
      while (values.length) {
        var id = values.shift ();
        var objectId = values.shift ();
        document.gruwaHatenaStarMap[id] = objectId;
      }
    });
    $$ (fragment, 'hatena-html .section > h3.title > a[name], hatena-html .section > h3[id], hatena-html section > h1[data-hatena-timestamp]').forEach (function (a) {
      if (a.localName === 'a') { // Hatena group's HTML
        var h = a.parentNode;
        upgradeHatenaTitle (h, a.name);
      } else { // Hatena blog's HTML
        upgradeHatenaTitle (a, a.id);
      }
    });
    Array.prototype.slice.call (fragment.childNodes).forEach (function (_) {
      document.body.appendChild (_);
    });
    sendHeight ();
  } else if (ev.data.type === 'getHeight') {
    sendHeight ();
  } else if (ev.data.type === 'execCommand') {
    document.execCommand (ev.data.command, ev.data.value);
    selectChanged ();
  } else if (ev.data.type === 'setBlock') {
    setBlock (ev.data.value);
  } else if (ev.data.type === 'indent') {
    indent ();
  } else if (ev.data.type === 'outdent') {
    outdent ();
  } else if (ev.data.type === 'insertSection') {
    insertSection ();
  } else if (ev.data.type === 'insertControl') {
    if (ev.data.value === 'checkbox') {
      document.execCommand ('inserthtml', false, '<input type=checkbox>');
    } else {
      throw "Bad |value| " + ev.data.value;
    }
  } else if (ev.data.type === 'insertImage') {
    insertImage (ev.data.value);
  } else if (ev.data.type === 'insertFile') {
    insertFile (ev.data.value);
  } else if (ev.data.type === 'link') {
    if (ev.data.command === 'wiki-name') {
      insertLink ({wikiName: ev.data.value, textContent: ev.data.value,
                   command: ev.data.command});
    } else if (ev.data.command === 'url') {
      insertLink ({url: ev.data.value, textContent: ev.data.value});
    } else {
      throw "Bad |command| " + ev.data.command;
    }
  } else if (ev.data.type === 'change') {
    var data = ev.data.value;
    Array.prototype.forEach.call (document.querySelectorAll ('input[type=checkbox]'), function (e) {
      if (e.name === data.name) {
        e.checked = e.defaultChecked = data.value;
        changeChecked (e);
      }
    });
  } else if (ev.data === 'reloadStylesheets') { // for debug tools
    document.querySelectorAll ('link[rel~=stylesheet]').forEach (el => {
      var url = new URL (el.href);
      url.search = "?r=local-" + Math.random ();
      el.href = url;
    });
  } else {
    console.log ('Unknown message', ev.data);
  }
} // handleMessage

function sendToParent (data) {
  if (!parentPort) return;
  parentPort.postMessage (data);
} // sendToParent

function sendPrompt (opts) {
  var c = new MessageChannel;
  parentPort.postMessage ({type: "prompt", value: opts}, [c.port1]);
  var ok;
  var p = new Promise (function (x) { ok = x });
  c.port2.onmessage = function (ev) {
    ok (ev.data);
    c.port2.close ();
  };
  return p;
} // sendPrompt

function sendGetObjectWithSearchData (objectId) {
  var c = new MessageChannel;
  parentPort.postMessage ({type: "getObjectWithSearchData", value: objectId}, [c.port1]);
  var ok;
  var p = new Promise (function (x) { ok = x });
  c.port2.onmessage = function (ev) {
    ok (ev.data);
    c.port2.close ();
  };
  return p;
} // sendGetObjectWithSearchData

function sendGetHatenaStarData (id) {
  var c = new MessageChannel;
  parentPort.postMessage ({type: "getHatenaStarData", value: id}, [c.port1]);
  var ok;
  var p = new Promise (function (x) { ok = x });
  c.port2.onmessage = function (ev) {
    ok (ev.data);
    c.port2.close ();
  };
  return p;
} // sendGetHatenaStarData

function sendHeight () {
  sendToParent ({type: "height", value: document.documentElement.offsetHeight});
} // sendHeight

onfocus = function () {
  sendToParent ({type: "focus"});
}; // onfocus

document.onpaste = function (ev) {
  var text = ev.clipboardData.getData ('text/plain');
  if (text && /^\s*(?:[Hh][Tt][Tt][Pp][Ss]?|[Ff][Tt][Pp]):\/\/\S+\s*$/.test (text)) {
    text = text.replace (/^\s+/, '').replace (/\s+$/, '');
    ev.clipboardData.items.clear ();
    insertLink ({url: text, textContent: text});
    return false;
  }
}; // onpaste

onmouseover = function (ev) {
  if (!ev.target.isContentEditable) return;
  var e = ev.target;
  while (e) {
    if (e.localName === 'a') {
      showContextToolbar ({context: e, template: 'link-edit-template'});
      break;
    }
    e = e.parentNode;
  }
}; // mouseover

onmouseout = function (ev) {
  if (!ev.target.isContentEditable) { // within UI
    if (ev.relatedTarget && ev.relatedTarget.isContentEditable) {
      if (ev.relatedTarget.localName !== 'a') {
        showContextToolbar ({void: true});
      }
    }
  } else {
    if (ev.target.localName === 'a' &&
        !(ev.relatedTarget && !ev.relatedTarget.isContentEditable)) {
      showContextToolbar ({void: true});
    }
  }
};

onchange = function (ev) {
  if (ev.target.type === 'checkbox') {
    if (ev.target.checked !== ev.target.defaultChecked) {
      ev.target.defaultChecked = ev.target.checked;
      sendToParent ({type: "changed",
                     name: ev.target.name, value: ev.target.checked});
      changeChecked (ev.target);
    }
  }
}; // onchange

(function () {
  var over = false;
  onmouseover = function (ev) {
    var parent = ev.target;
    while (parent) {
      if (parent.localName === 'a') {
        break;
      } else {
        parent = parent.parentNode;
      }
    }
    if (parent && parent.localName === 'a') {
      sendToParent ({
        type: "linkSelected", url: ev.target.href,
        top: ev.target.offsetTop, left: ev.target.offsetLeft,
        width: ev.target.offsetWidth, height: ev.target.offsetHeight,
      });
      over = true;
    } else {
      if (over) {
        sendToParent ({type: "linkSelected", url: null});
        over = false;
      }
    }
  }; // onmouseover
}) ();

var UsedControlNames = {
  "": true, "0": true, "null": true, "undefined": true,
};
var mo = new MutationObserver (function (records) {
  records.forEach (function (record) {
    Array.prototype.forEach.call (record.addedNodes, function (n) {
      if (n.localName === 'input' && n.type === 'checkbox') {
        if (UsedControlNames[n.name]) {
          n.name = Math.random ();
          UsedControlNames[n.name] = true;
        }
        changeChecked (n);
      } else if (n.localName === 'a') {
        initAElement (n);
      } else {
        Array.prototype.forEach.call (document.querySelectorAll ('input[type=checkbox]'), function (n) {
          if (UsedControlNames[n.name]) {
            n.name = Math.random ();
            UsedControlNames[n.name] = true;
          }
          changeChecked (n);
        });
        Array.prototype.forEach.call (document.querySelectorAll ('a'), function (n) {
          initAElement (n);
        });
      }
    });
  });
});
mo.observe (document.documentElement, {childList: true, subtree: true});

var selChangedTimer;
document.onselectionchange = function () {
  clearTimeout (selChangedTimer);
  selChangedTimer = setTimeout (selectChanged, 500);
};

function selectChanged () {
  clearTimeout (selChangedTimer);
  var data = {};
  ["bold", "italic", "underline", "strikethrough",
   "superscript", "subscript"].forEach (function (key) {
    data[key] = document.queryCommandState (key);
  });
  sendToParent ({type: "currentState", value: data});
} // selectChanged

function changeChecked (e) {
  var value = e.checked;
  while (e) {
    if (e.localName === 'li') {
      break;
    }
    e = e.parentNode;
  }
  if (e) {
    if (value) {
      e.setAttribute ('data-checked', '');
    } else {
      e.removeAttribute ('data-checked');
    }
  }
} // changeChecked

var BlockElements = {
  div: true, p: true,
  li: true,
  ul: true, ol: true,
};
var ContainerElements = {
  section: true, article: true, figure: true, blockquote: true,
  h1: true, main: true,
  html: true, head: true, body: true,
};
var AdjacentMergeableElements = {
  ul: true, ol: true,
};
var InlineContentOnlyElements = {
  h1: true, section: true,
};

var TypeToLocalName = {
  ul: "li", ol: "li",
};
var TypeToParentLocalName = {
  ul: "ul", ol: "ol",
  h1: "section",
};

function copyAttrs (newNode, node) {
  for (var i = 0; i < node.attributes.length; i++) {
    var attr = node.attributes[i];
    newNode.setAttriute (attr.name, attr.value);
  }
} // copyAttrs

function getNearestBlock () {
  var isBlock = false;
  var node = getSelection ().anchorNode;
  TRUE: while (true) {
    if (BlockElements[node.localName]) {
      isBlock = true;
      break;
    } else if (!node.parentNode) {
      break;
    } else if (ContainerElements[node.parentNode.localName]) {
      break;
    } else {
      var list = node.parentNode.children;
      for (var i = 0; i < list.length; i++) {
        if (BlockElements[list[i].localName]) {
          break TRUE;
        }
      }
      node = node.parentNode;
    }
  }
  return {node: node, isBlock: isBlock};
} // getNearestBlock

function splitParentAt (node) {
  var before = node.parentNode;
  var after = document.createElement (before.localName);
  while (node.nextSibling) {
    after.appendChild (node.nextSibling);
  }
  before.parentNode.insertBefore (after, before.nextSibling);
  before.parentNode.insertBefore (node, after);

  if (!before.hasChildNodes ()) {
    copyAttrs (after, before);
    before.remove ();
  }
  if (!after.hasChildNodes ()) after.remove ();
  return {before: before, after: after};
} // splitParentAt

function mergeWithSiblings (node) {
  if (AdjacentMergeableElements[node.localName]) {
    if (node.nextSibling &&
        node.nextSibling.localName === node.localName) {
      while (node.nextSibling.firstChild) {
        node.appendChild (node.nextSibling.firstChild);
      }
      node.nextSibling.remove ();
    }
    if (node.previousSibling &&
        node.previousSibling.localName === node.localName) {
      while (node.firstChild) {
        node.previousSibling.appendChild (node.firstChild);
      }
      node.remove ();
    }
  }
} // mergeWithSiblings

function wrapNodesBy (node, type) {
  var para = [node];
  var current = node.nextSibling;
  while (true) {
    if (current && !(BlockElements[current.localName] ||
                     ContainerElements[current.localName])) {
      para.push (current);
      current = current.nextSibling;
    } else {
      break;
    }
  }
  current = node.previousSibling;
  while (true) {
    if (current && !(BlockElements[current.localName] ||
                     ContainerElements[current.localName])) {
      para.unshift (current);
      current = current.previousSibling;
    } else {
      break;
    }
  }
  var newNode = document.createElement (type);
  node.parentNode.insertBefore (newNode, node);
  para.forEach (function (n) {
    newNode.appendChild (n);
  });
  return newNode;
} // wrapNodesBy

function setBlock (type) {
  var x = getNearestBlock ();
  var node = x.node;
  var isBlock = x.isBlock;

  // Unlikely, and nothing we can do.
  if (!node.parentNode) return;

  if (InlineContentOnlyElements[node.localName]) return;

  // Wrapping
  if (ContainerElements[node.localName]) {
    var newNode = document.createElement ('div');
    while (node.firstChild) {
      newNode.appendChild (node.firstChild);
    }
    node.appendChild (newNode);
    node = newNode;
    isBlock = true;
  } else if (!isBlock) {
    node = wrapNodesBy (node, 'div');
  }

  // Rewrite the block's local name
  var localName = TypeToLocalName[type] || type;
  if (localName !== node.localName) {
    var newNode = document.createElement (localName);
    node.parentNode.insertBefore (newNode, node);
    while (node.firstChild) newNode.appendChild (node.firstChild);
    copyAttrs (newNode, node);
    node.remove ();
    node = newNode;
  }

  var toBeSelected = node;

  // Insert parent node, if necessary
  var needReparent = true;
  var parentLocalName = TypeToParentLocalName[type];
  if (parentLocalName) {
    if (!AdjacentMergeableElements[parentLocalName] ||
        node.parentNode.localName !== parentLocalName) {
      var parent = document.createElement (parentLocalName);
      node.parentNode.insertBefore (parent, node);
      parent.appendChild (node);
      node = parent;
    } else {
      needReparent = false;
    }
  }

  // Break parent block, if any
  if (needReparent &&
      node.parentNode &&
      BlockElements[node.parentNode.localName] &&
      node.parentNode.parentNode) {
    splitParentAt (node);
  }

  mergeWithSiblings (node);

  getSelection ().selectAllChildren (toBeSelected);
} // setBlock

function insertSection () {
  var node = getSelection ().anchorNode;
  while (true) {
    if (!node.parentNode) {
      break;
    } else if (ContainerElements[node.parentNode.localName]) {
      break;
    } else {
      node = node.parentNode;
    }
  }
  if (InlineContentOnlyElements[node.localName]) return;

  var section = document.createElement ('section');
  section.setAttribute ('contenteditable', 'false');
  var h1 = document.createElement ('h1');
  h1.setAttribute ('contenteditable', '');
  section.appendChild (h1);
  var main = document.createElement ('main');
  main.setAttribute ('contenteditable', '');
  section.appendChild (main);
  node.parentNode.insertBefore (section, node.nextSibling);
  h1.focus ();
} // insertSection

function indent () {
  var x = getNearestBlock ();

  if (x.node.localName !== 'li' &&
      x.node.parentNode &&
      x.node.parentNode.localName === 'li') {
    x.node = wrapNodesBy (x.node, 'li');
  }

  if (!x.node.parentNode) return;

  if (x.node.localName === 'li') {
    if (x.node.previousSibling &&
        x.node.previousSibling.localName === 'li') {
      var listType = x.node.parentNode.localName === 'ol' ? 'ol' : 'ul';
      if ((x.node.previousSibling.lastChild || {}).localName === listType) {
        x.node.previousSibling.lastChild.appendChild (x.node);
      } else {
        var list = document.createElement (listType);
        x.node.previousSibling.appendChild (list);
        list.appendChild (x.node);
      }
    } else if (x.node.parentNode &&
               (x.node.parentNode.localName === 'ul' ||
                x.node.parentNode.localName === 'ol')) {
      var list = document.createElement (x.node.parentNode.localName);
      var li = document.createElement ('li');
      li.appendChild (list);
      x.node.parentNode.insertBefore (li, x.node);
      list.appendChild (x.node);
    } else if (x.node.nextSibling &&
               (x.node.nextSibling.localName === 'ul' ||
                x.node.nextSibling.localName === 'ol') &&
               x.node.parentNode.localName === 'li' &&
               x.node.parentNode.parentNode &&
               x.node.parentNode.parentNode.localName === x.node.nextSibling.localName) {
      x.node.nextSibling.insertBefore (x.node, x.node.nextSibling.firstChild);
    } else {
      if (x.node.parentNode.localName === 'li' &&
          x.node.parentNode.parentNode &&
          x.node.parentNode.parentNode.localName === 'ol') {
        var list = document.createElement ('ol');
      } else {
        var list = document.createElement ('ul');
      }
      x.node.parentNode.insertBefore (list, x.node);
      list.appendChild (x.node);
    }

    var item = x.node.parentNode.parentNode;
    var prevItem = item.previousSibling;
    if (item &&
        prevItem &&
        !x.node.parentNode.previousSibling &&
        item.localName === 'li' &&
        prevItem.localName === 'li') {
      while (item.firstChild) {
        prevItem.appendChild (item.firstChild);
        mergeWithSiblings (prevItem.lastChild);
      }
      item.remove ();
    }

    var item = x.node;
    var nextItem = item.nextSibling;
    if (nextItem &&
        nextItem.localName === 'li' &&
        nextItem.firstChild &&
        (nextItem.firstChild.localName === 'ul' ||
         nextItem.firstChild.localName === 'ol')) {
      while (nextItem.firstChild) {
        item.appendChild (nextItem.firstChild);
        mergeWithSiblings (item.lastChild);
      }
      nextItem.remove ();
    }
  }

  getSelection ().selectAllChildren (x.node);
} // indent

function outdent () {
  var x = getNearestBlock ();

  if (x.node.localName !== 'li' &&
      x.node.parentNode &&
      x.node.parentNode.localName === 'li' &&
      x.node.parentNode.parentNode &&
      (x.node.parentNode.parentNode.localName === 'ul' ||
       x.node.parentNode.parentNode.localName === 'ol')) {
    x.node = wrapNodesBy (x.node, 'li');
    splitParentAt (x.node);
  }

  if (!x.node.parentNode) return;

  if (x.node.localName === 'li') {
    var parentType = x.node.parentNode.localName;
    if (parentType === 'ul' || parentType === 'ol') {
      if (x.node.parentNode.parentNode &&
          x.node.parentNode.parentNode.localName === 'li') {
        splitParentAt (x.node);
        var z = splitParentAt (x.node);
        while (z.after.firstChild) {
          x.node.appendChild (z.after.firstChild);
        }
        z.after.remove ();
        if (x.node.parentNode && x.node.parentNode.localName !== parentType) {
          var list = document.createElement (parentType);
          x.node.parentNode.insertBefore (list, x.node);
          list.appendChild (x.node);
          if (list.parentNode.parentNode) splitParentAt (list);
        }
      }      
    }
  }

  getSelection ().selectAllChildren (x.node);
} // outdent

function insertLink (args) {
  var isWikiName = false;

  var p;
  if (args.wikiName) {
    p = Promise.resolve ({result: args.wikiName});
    isWikiName = true;
  } else if (args.url) {
    p = Promise.resolve ({result: args.url});
  } else if (args.command === 'wiki-name') {
    isWikiName = true;
    var name = getSelection ().toString ();
    if (name) {
      p = Promise.resolve ({result: name});
    } else {
      p = sendPrompt ({prompt: document.querySelector ('#edit-texts').getAttribute ('data-link-wiki-name-prompt')});
    }
  } else {
    p = sendPrompt ({prompt: document.querySelector ('#edit-texts').getAttribute ('data-link-url-prompt')});
  }

  p.then (function (_) {
    if (_.result == null) return;

    var link = document.createElement ('a');
    var hasSelected = link.firstChild;
    if (args.textContent) link.textContent = args.textContent;

    if (isWikiName) {
      link.setAttribute ('data-wiki-name', _.result);
    } else {
      link.href = _.result;
    }
    if (!link.firstChild) link.textContent = _.result;

    replaceSelectionBy (link, hasSelected);    
  });
} // insertLink

function insertImage (url) {
  var a = document.createElement ('a');
  a.href = url;
  var img = document.createElement ('img');
  img.src = url + '/image';
  a.appendChild (img);
  replaceSelectionBy (a, false);
} // insertImage

function insertFile (url) {
  var iframe = document.createElement ('iframe');
  iframe.className = 'embed';
  iframe.src = url + '/embed';
  replaceSelectionBy (iframe, false);
} // insertFile

function replaceSelectionBy (node, hasSelected) {
  var sel = getSelection ();
  sel.getRangeAt (0).deleteContents ();
  sel.getRangeAt (0).insertNode (node);
  sel.selectAllChildren (node);
  if (!hasSelected) sel.collapseToEnd ();
} // replaceSelectionBy

function initAElement (a) {
  var wikiName = a.getAttribute ('data-wiki-name');
  if (wikiName) {
    a.setAttribute ('href', document.documentElement.getAttribute ('data-group-url') + '/wiki/' + encodeURIComponent (wikiName));
  }
} // initAElement

var contextToolbar;
function showContextToolbar (args) {
  if (contextToolbar) contextToolbar.remove ();
  contextToolbar = null;

  if (args.void) return;

  var template = document.querySelector ('#' + args.template);

  contextToolbar = document.createElement ('menu');
  contextToolbar.className = 'context';
  contextToolbar.setAttribute ('contenteditable', 'false');
  contextToolbar.style.top = args.context.offsetTop + args.context.offsetHeight + 'px';
  contextToolbar.style.left = args.context.offsetLeft + 'px';
  contextToolbar.appendChild (template.content.cloneNode (true));

  var updated = function () {
    var isWikiName = args.context.hasAttribute ('data-wiki-name');
    Array.prototype.forEach.call (contextToolbar.querySelectorAll ('[data-field=host]'), function (e) {
      e.hidden = isWikiName;
      e.textContent = args.context.host;
    });
    Array.prototype.forEach.call (contextToolbar.querySelectorAll ('[data-title-field=href]'), function (e) {
      e.title = args.context.href;
    });
    Array.prototype.forEach.call (contextToolbar.querySelectorAll ('[data-href-field=href]'), function (e) {
      e.href = args.context.href;
    });
    Array.prototype.forEach.call (contextToolbar.querySelectorAll ('[data-field=wikiName]'), function (e) {
      e.textContent = args.context.getAttribute ('data-wiki-name');
      e.hidden = !isWikiName;
    });
  }; // updated
  updated ();
  Array.prototype.forEach.call (contextToolbar.querySelectorAll ('.edit-button'), function (e) {
    e.onclick = function () {
      var isWikiName = args.context.hasAttribute ('data-wiki-name');
      sendPrompt ({prompt: e.getAttribute (isWikiName ? 'data-wiki-name-prompt' : 'data-url-prompt'),
                   default: isWikiName ? args.context.getAttribute ('data-wiki-name') : args.context.href}).then (function (_) {
        if (_.result != null) {
          if (isWikiName) {
            args.context.setAttribute ('data-wiki-name', _.result);
            initAElement (args.context);
          } else {
            args.context.href = _.result;
          }
          updated ();
        }
      });
    };
  });

  document.body.appendChild (contextToolbar);
} // showContextToolbar

function upgradeObjectRef (e) {
  if (e.upgraded) return;
  e.upgraded = true;

  if (document.body.isContentEditable) {
    e.onclick = function () { return false };
  }

  if (! e.attachShadow) return; // old browsers

  var objectId = e.getAttribute ('value');
  return sendGetObjectWithSearchData (objectId).then (function (object) {
    var f = document.createElement ('object-ref-content');
    f.appendChild (document.querySelector ('#object-ref-template').content.cloneNode (true));
    $grfill (f, object);
  
    var sr = e.attachShadow ({mode: 'open'});

    $$ (document.head, 'link[rel~=stylesheet]').forEach (function (g) {
      sr.appendChild (g.cloneNode (true));
    });
    sr.appendChild (f);

    sendHeight ();
  });
} // upgradeObjectRef

function upgradeHatenaTitle (e, name) {
  if (e.upgraded) return;
  e.upgraded = true;

  if (! e.attachShadow) return; // old browsers

  var sr = e.attachShadow ({mode: 'open'});
  $$ (document.head, 'link[rel~=stylesheet]').forEach (function (g) {
    sr.appendChild (g.cloneNode (true));
  });

  sr.appendChild (document.createElement ('slot'));
  var f = document.createElement ('hatena-star');
  f.setAttribute ('name', name);
  if (document.body.isContentEditable) {
    f.onclick = function () { return false };
  }
  sr.appendChild (f);
  upgradeHatenaStar (f);
} // upgradeHatenaTitle

function upgradeHatenaStar (e) {
  if (e.upgraded) return;
  e.upgraded = true;

  var objectId = document.gruwaHatenaStarMap[e.getAttribute ('name')];
  if (!objectId) return;

  // in fact search data is not used
  return sendGetObjectWithSearchData (objectId).then (function (data) {
    data.data.body_data.hatena_star.sort (function (a, b) {
      return b[1] - a[1] || b[2] - a[2];
    }).forEach (function (star) {
      var item = document.createElement ('list-item');
      item.appendChild (document.querySelector ('#hatena-star-template').content.cloneNode (true));
      $grfill (item, {name: star[0], name2: star[0].substring (0, 2),
                    type: star[1],
                    count: star[2],
                    quote: star[3]});
      e.appendChild (item);
    });

    sendHeight ();
  });
} // upgradeHatenaStar

sendHeight ();

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
