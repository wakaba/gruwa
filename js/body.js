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
    sendToParent ({type: "currentValue", value: document.body.innerHTML});
  } else if (ev.data.type === 'getHeight') {
    sendHeight ();
  } else if (ev.data.type === 'execCommand') {
    document.execCommand (ev.data.command, ev.data.value);
    selectChanged ();
  } else if (ev.data.type === 'setBlock') {
    setBlock (ev.data.value);
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
  while (true) {
    if (BlockElements[node.localName]) {
      isBlock = true;
      break;
    } else if (!node.parentNode) {
      break;
    } else if (ContainerElements[node.parentNode.localName]) {
      break;
    } else {
      node = node.parentNode;
    }
  }
  return {node: node, isBlock: isBlock};
} // getNearestBlock

function setBlock (type) {
  var x = getNearestBlock ();
  var node = x.node;
  var isBlock = x.isBlock;

  // Unlikely, and nothing we can do.
  if (!node.parentNode) return;

  if (InlineContentOnlyElements[node.localName]) return;

  // Wrapping
  if (!isBlock) {
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
    var newNode = document.createElement ('div');
    node.parentNode.insertBefore (newNode, node);
    para.forEach (function (n) {
      newNode.appendChild (n);
    });
    sel.selectAllChildren (newNode);
    node = newNode;
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
  }

  // Mergeable with siblings, if possible
  if (AdjacentMergeableElements[node.localName]) {
    if (node.nextSibling && node.nextSibling.localName === node.localName) {
      while (node.nextSibling.firstChild) {
        node.appendChild (node.nextSibling.firstChild);
      }
      node.nextSibling.remove ();
    }
    if (node.previousSibling && node.previousSibling.localName === node.localName) {
      while (node.firstChild) {
        node.previousSibling.appendChild (node.firstChild);
      }
      node.remove ();
    }
  }

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

sendHeight ();
