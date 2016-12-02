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

sendHeight ();
