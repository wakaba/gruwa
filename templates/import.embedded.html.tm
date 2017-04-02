<html t:params=$app>
<title>Gruwa</title>
<meta name=referrer content=no-referrer>
<link rel=stylesheet href=/css/common.css>
<meta name="viewport" content="width=device-width,initial-scale=1">

<script>
  var outerOrigin = null;
  var outerPort = null;
  var innerDate = new Date;
  var innerId = "" + Math.random ();

  onmessage = function (ev) {
    outerOrigin = ev.origin;
    outerPort = ev.ports[0];
    this.onmessage = null;
  }; // onmessage

  var bc = new BroadcastChannel ('sources');
  bc.onmessage = function (ev) {
    if (ev.data.type === 'requestSourceData') {
      var worker = new SharedWorker ('/js/shared.js?3');
      worker.port.postMessage
          ({type: 'provideSourceData',
            receiverId: ev.data.receiverId,
            data: {origin: outerOrigin,
                   date: innerDate,
                   sourceId: innerId}});
    } else if (ev.data.type === 'requestSourcePort') {
      if (ev.data.sourceId === innerId) {
        var worker = new SharedWorker ('/js/shared.js?3');
        createClientPort ().then (function (port) {
          worker.port.postMessage
              ({type: 'provideSourcePort',
                receiverId: ev.data.receiverId,
                data: {origin: outerOrigin,
                       date: innerDate,
                       sourceId: innerId}}, [port]);
        });
      }
    }
  }; // onmessage

  function createClientPort () {
    if (!outerPort) throw "Server is not available";
    var got;
    var p = new Promise (function (g) { got = g });
    outerPort.onmessage = function (ev) {
      var port = ev.ports[0];
      got (ev.ports[0]);
      this.onmessage = null;
    };
    outerPort.postMessage ({});
    return p;
  } // createClientPort
</script>

<!--

License:

Copyright 2017 Wakaba <wakaba@suikawiki.org>.

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

-->
