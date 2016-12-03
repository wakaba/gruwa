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
  }
} // handleMessage

function sendToParent (data) {
  if (!parentPort) return;
  parentPort.postMessage (data);
} // sendToParent

function sendHeight () {
  sendToParent ({type: "height", value: document.documentElement.offsetHeight});
} // sendHeight

onfocus = function () {
  sendToParent ({type: "focus"});
};

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

sendHeight ();
