function Importer () { }

Importer.getImportSources = function () {
  var found;
  var failed;
  var p = new Promise (function (ok, ng) { found = ok; failed = ng });

  if (!self.SharedWorker) return failed ("SharedWorker not supported");
  var worker = new SharedWorker ('/js/shared.js?3');
  var c = new MessageChannel;
  worker.port.postMessage ({type: 'createReceiver'}, [c.port1]);
  c.port2.onmessage = function (ev) {
    var receiver = ev.ports[0];
    var results = [];
    receiver.onmessage = function (ev) {
      results.push (ev.data.data);
    };
    setTimeout (function () {
      found (results);
      receiver.postMessage ({type: 'close'});
      receiver.close ();
    }, 1000);
    var bc = new BroadcastChannel ('sources');
    bc.postMessage ({type: 'requestSourceData',
                     receiverId: ev.data.receiverId});
    this.close ();
  };

  return p;
} // getImportSources

Importer.createClient = function (sourceId) {
  var found;
  var failed;
  var p = new Promise (function (ok, ng) { found = ok; failed = ng });

  if (!self.SharedWorker) return failed ("SharedWorker not supported");
  var worker = new SharedWorker ('/js/shared.js?3');
  var c = new MessageChannel;
  worker.port.postMessage ({type: 'createReceiver'}, [c.port1]);
  c.port2.onmessage = function (ev) {
    var receiver = ev.ports[0];
    var cancel = setTimeout (function () {
      failed ("Source " + sourceId + " not found");
      receiver.postMessage ({type: 'close'});
      receiver.close ();
    }, 1000);
    receiver.onmessage = function (ev) {
      found (new Importer.Client (ev.data.data, ev.ports[0]));
      receiver.postMessage ({type: 'close'});
      receiver.close ();
      clearTimeout (cancel);
    };
    var bc = new BroadcastChannel ('sources');
    bc.postMessage ({type: 'requestSourcePort',
                     receiverId: ev.data.receiverId,
                     sourceId: sourceId});
    this.close ();
  };

  return p;
} // createClient

Importer.Client = function (data, port) {
  this.data = data;
  this.port = port;
}; // Client

Importer.Client.prototype.getOrigin = function () {
  return this.data.origin;
}; // getOrigin

Importer.Client.prototype.sendCommand = function (args) {
  var ok;
  var ng;
  var p = new Promise (function (x, y) { ok = x; ng = y });
  var mc = new MessageChannel;
  mc.port2.onmessage = function (ev) {
    if (ev.data.error) {
      ng (ev.data.message);
    } else {
      ok (ev.data.result);
    }
    this.close ();
  };
  this.port.postMessage (args, [mc.port1]);
  return p;
}; // sendCommand

Importer.HatenaGroup = function (client) {
  this.client = client;
}; // HatenaGroup

Importer.HatenaGroup.prototype.keywordlist = function () {
  var client = this.client;
  var result = [];
  // /keywordlist?mode=rss does not support paging :-<
  var getPage = function (url) {
    return client.sendCommand ({type: "fetch", "url": url, "resultType": "text"}).then (function (html) {
      var doc = document.implementation.createHTMLDocument ();
      var base = doc.createElement ('base');
      base.href = client.getOrigin ();
      doc.head.appendChild (base);
      var div = doc.createElement ('div');
      div.innerHTML = html;
      $$ (div, '.refererlist ul a[href]').forEach (function (link) {
        var d = link.previousSibling && link.previousSibling.data &&
                link.previousSibling.data.match (/(\d+[-\/]\d+[-\/]\d+\s+\d+:\d+:\d+)/);
        var date = d ? new Date (d[1].replace (/\//g, '-').replace (/\s+/, 'T') + '+09:00') : null;
        result.push ({title: link.textContent,
                      updated: date});
      });
      var nextLink = $$ (div, 'a[href][rel~=next]')[0];
      if (nextLink) {
        return getPage (nextLink.pathname + nextLink.search);
      }
    });
  }; // getPage
  return getPage ('/keywordlist').then (function () {
    return result;
  });
}; // keywordlist

Importer.HatenaGroup.prototype.diarylist = function () {
  var client = this.client;
  var result = [];
  // /diarylist?mode=rss does not support paging :-<
  var getPage = function (url) {
    return client.sendCommand ({type: "fetch", url: url}).then (function (html) {
      var doc = document.implementation.createHTMLDocument ();
      var base = doc.createElement ('base');
      base.href = client.getOrigin ();
      doc.head.appendChild (base);
      var div = doc.createElement ('div');
      div.innerHTML = html;
      $$ (div, '.refererlist ul a[href]').forEach (function (link) {
        var d = link.previousSibling && link.previousSibling.data &&
                link.previousSibling.data.match (/(\d+-\d+-\d+\s+\d+:\d+:\d+)/);
        var date = d ? new Date (d[1].replace (/\s+/, 'T') + '+09:00') : null;
        var m = link.pathname.match (/^\/([^\/]+)\//);
        result.push ({url_name: m[1],
                      title: link.textContent,
                      updated: date});
      });
      var nextLink = $$ (div, 'a[href][rel~=next]')[0];
      if (nextLink) {
        return getPage (nextLink.pathname + nextLink.search);
      }
    });
  }; // getPage
  return getPage ('/diarylist').then (function () {
    return result;
  });
}; // diarylist

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
