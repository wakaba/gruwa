function Importer () { }

// XXX cancel
Importer.run = function (sourceId, statusContainer, opts) {
  var as = getActionStatus (statusContainer);
  var mapTable = statusContainer.querySelector ('.mapping-table');
  mapTable.hidden = false;

        var createWiki = function (site, page, groupTitle) {
          var title = groupTitle ? groupTitle + 'のキーワード' : 'キーワード';
          var fd = new FormData;
          fd.append ('index_type', 2); // wiki
          fd.append ('title', title);
          fd.append ('source_site', site);
          fd.append ('source_page', page);
          return gFetch ('i/create.json', {post: true, formData: fd}).then (function (json) {
            return {index_id: json.index_id, title: title};
          });
        }; // createWiki

        var importKeyword = function (group, keyword, indexId, imported, site) {
          var page = group.getKeywordPageURL (keyword.title);
          if (imported[page] && imported[page].type == 2 /* object */) {
            var currentTimestamp = imported[page].sync_info.timestamp;
            if (currentTimestamp &&
                parseFloat (currentTimestamp) >= keyword.updated.valueOf () / 1000) {
              return Promise.resolve ();
            }
          }

          return group.keywordhtml (keyword.title).then (function (html) {
            var objectId;
            var fd = new FormData;
            fd.append ('source_site', site);
            fd.append ('source_page', page);
            return gFetch ('o/create.json', {post: true, formData: fd}).then (function (json) {
              objectId = json.object_id;
              var fd = new FormData;
              fd.append ('edit_index_id', 1);
              fd.append ('index_id', indexId);
              fd.append ('title', keyword.title);
              fd.append ('body_type', 1); // html
              fd.append ('body', '<hatena-html>' + html + '</hatena-html>');
              fd.append ('source_timestamp', keyword.updated.valueOf () / 1000);
              return gFetch ('o/' + objectId + '/edit.json', {post: true, formData: fd});
            });
          });
        }; // importKeyword

        var getImported = function (site) {
          var pageToItem = {};
          var get; get = function (ref) {
            return gFetch ('imported/' + encodeURIComponent (site) + '/list.json?' + (ref ? 'ref=' + encodeURIComponent (ref) : null), {}).then (function (json) {
              json.items.forEach (function (item) {
                pageToItem[item.source_page] = item;
              });
              if (json.has_next) return get (json.next_ref);
            });
          }; // get
          return get ().then (function () { return pageToItem });
        }; // getImported

        as.start ({stages: ['getimported',
                            'getkeywordlist',
                            'createkeywordwiki',
                            'createkeywordobjects']});
        return Importer.createClient (sourceId).then (function (client) {
          var group = new Importer.HatenaGroup (client);
          var site = group.getSiteURL ();
          as.stageStart ('getimported');
          var gI = opts.forceUpdate ? Promise.resolve ({}) : getImported (site);
          return gI.then (function (imported) {
            as.stageEnd ('getimported');
            as.stageStart ('getkeywordlist');
            return group.keywordlist ().then (function (keywords) {
              as.stageEnd ('getkeywordlist');
              var keywordCount = keywords.length;
              if (keywordCount === 0) return;

              as.stageStart ('createkeywordwiki');
              var page = group.getKeywordTopPageURL ();
              var getIndexId;
              if (imported[page] && imported[page].type == 1 /* index */) {
                getIndexId = Promise.resolve ({index_id: imported[page].dest_id});
              } else {
                getIndexId = createWiki (site, page, keywords.title);
              }
              return getIndexId.then (function (index) {
                index.count = keywordCount;
                $$ (mapTable, '.keywords-info').forEach (function (e) {
                  e.hidden = false;
                  fillFields (e, e, e, index);
                });
                as.stageEnd ('createkeywordwiki');
                as.stageStart ('createkeywordobjects');
                var nextItem; nextItem = function () {
                  if (keywords.length === 0) return;
                  as.stageProgress ('createkeywordobjects', keywordCount - keywords.length, keywordCount);
                  var keyword = keywords.shift ();
                  return importKeyword (group, keyword, index.index_id, imported, site).then (nextItem);
                }; // nextItem
                return nextItem ();
              }).then (function () {
                as.stageEnd ('createkeywordobjects');
              });
            });
          }).then (function () {
            client.close ();
          }, function (e) {
            client.close ();
            throw e;
          });
        }).then (function () {
          as.end ({ok: true});
        }, function (e) {
          as.end ({error: e});
        });
}; // run

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

Importer.Client.prototype.close = function () {
  this.port.close ();
}; // close

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

Importer.HatenaGroup.prototype.getSiteURL = function () {
  return this.client.getOrigin ().replace (/^http:/, 'https:');
}; // getSiteURL

Importer.HatenaGroup.prototype.getKeywordTopPageURL = function () {
  return this.getSiteURL () + '/keywordlist';
}; // getKeywordTopPageURL

Importer.HatenaGroup.prototype.getKeywordPageURL = function (k) {
  return this.getSiteURL () + '/keyword/' + encodeURIComponent (k);
}; // getKeywordPageURL

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
      var header = $$ (div, 'h1')[0];
      if (header) {
        result.title = header.textContent.replace (/のキーワード一覧\s*$/, '');
      }
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

Importer.HatenaGroup.prototype.keywordhtml = function (keyword) {
  var client = this.client;
  return client.sendCommand ({type: "fetch", "url": '/keyword/' + encodeURIComponent (keyword), "resultType": "text"}).then (function (html) {
    var doc = document.implementation.createHTMLDocument ();
    var base = doc.createElement ('base');
    base.href = client.getOrigin ();
    doc.head.appendChild (base);
    var div = doc.createElement ('div');
    div.innerHTML = html;
    var container = div.querySelector ('.hatena-body .body');
    if (!container) return null;
    $$ (container, 'a[href]:not([href^="http:"]):not([href^="https:"])').forEach (function (e) {
      e.href = e.href;
    });
    $$ (container, 'img[src]:not([src^="http:"]):not([src^="https:"])').forEach (function (e) {
      e.src = e.src;
    });
    Array.prototype.slice.call (container.children).forEach (function (e) {
      if (e.localName === 'script') e.remove ();
    });
    return container.innerHTML;
  });
}; // keywordhtml

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
