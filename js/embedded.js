/* This script is executed within an external origin, imported
   by HTML script element as a classic script. */

(function () {
  var doc = this.document;

  var gIframe = doc.createElement ('iframe');
  gIframe.style.width = '1px';
  gIframe.style.height = '1px';
  gIframe.style.visibility = 'hidden';
  (doc.body || doc.head || doc.documentElement || doc).appendChild (gIframe);
  var global = gIframe.contentWindow;

  var Server = function (port) {
    this.port = port;
    var self = this;
    port.onmessage = function (ev) {
      var port = ev.ports[0];
      if (ev.data.type && self[ev.data.type]) {
        self[ev.data.type] (ev.data).then (function (result) {
          port.postMessage ({result: result});
          port.close ();
        }, function (error) {
          if (error instanceof global.Response) {
            port.postMessage ({error: true,
                               message: "Response error " + error.status,
                               response: {status: error.status,
                                          statusText: error.statusText}});
            port.close ();
          } else {
            port.postMessage ({error: true, message: "" + error});
            port.close ();
          }
        });
      } else {
        port.postMessage ({
          error: true,
          message: "Message type |" + ev.data.type + "| is not supported",
        });
        port.close ();
      }
    };
  }; // Server

  Server.prototype.fetch = function (args) {
    return global.fetch (args.url, {
      method: args.method || 'GET',
      credentials: args.credentials || 'same-origin',
      redirect: args.redirect || 'manual',
    }).then (function (res) {
      if (res.status !== 200) throw res;
      if (args.resultType === 'json') {
        return res.json ();
      } else {
        return res.text ();
      }
    });
  }; // fetch

  var iframe = doc.createElement ('iframe');
  iframe.style.width = '1px';
  iframe.style.height = '1px';
  iframe.style.visibility = 'hidden';
  var url = doc.currentScript.src;
  var m = url.match (/^(https?:\/\/[^\/]+)/);
  if (!m) throw "Bad script URL: " + url;
  var origin = m[1];
  iframe.src = origin + '/import/embedded?' + Math.random (); // XXX
  iframe.onload = function () {
    var channel = new global.MessageChannel;
    this.contentWindow.postMessage ({}, origin, [channel.port2]);
    channel.port1.onmessage = function (ev) {
      var c = new global.MessageChannel;
      var server = new Server (c.port1);
      this.postMessage ({}, [c.port2]);
    };
  }; // onload
  (doc.body || doc.head || doc.documentElement || doc).appendChild (iframe);
}) ();

/*

License:

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
License along with this program, see <https://www.gnu.org/licenses/>.

*/