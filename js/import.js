function Importer () { }

// XXX cancel
Importer.run = function (sourceId, statusContainer, opts) {
  var as = getActionStatus (statusContainer);
  var mapTable = statusContainer.querySelector ('.mapping-table');
  mapTable.querySelector ('table').hidden = false;
  mapTable.clearObjects ();

  var createIndex = function (site, page, imported, opts) {
    if (imported[page] && imported[page].type == 1 /* index */) {
      return Promise.resolve ({index_id: imported[page].dest_id});
    }

    var fd = new FormData;
    fd.append ('index_type', opts.indexType);
    fd.append ('title', opts.title);
    fd.append ('source_site', site);
    fd.append ('source_page', page);
    return gFetch ('i/create.json', {post: true, formData: fd}).then (function (json) {
      return {index_id: json.index_id, title: opts.title};
    });
  }; // createIndex

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

  var importDay = function (group, indexId, imported, site, page, data) {
    var sha = data.source_type === 'html' ? sha1 ([data.title, data.body].join ("\n")) : null;
    var sourceSha = data.source_type === 'xml' ? sha1 ([data.title, data.body].join ("\n")) : null;
    var current = imported[page];
    if (current && current.type == 2 /* object */) {
      if (sourceSha && current.sync_info.source_sha === sourceSha) {
        return Promise.resolve ({objectId: imported[page].dest_id});
      }
      if (sha && current.sync_info.sha === sha) {
        return Promise.resolve ({objectId: imported[page].dest_id});
      }
      sha = sha || current.sync_info.sha || null;
      sourceSha = sourceSha || current.sync_info.source_sha || null;
    }

    return Promise.resolve ().then (function () {
      if (imported[page] && imported[page].type == 2 /* object */) {
        return {objectId: imported[page].dest_id, new: false};
      }

      var fd = new FormData;
      fd.append ('source_site', site);
      fd.append ('source_page', page);
      return gFetch ('o/create.json', {post: true, formData: fd}).then (function (json) {
        return {objectId: json.object_id, new: true};
      });
    }).then (function (info) {
      var fd = new FormData;
      if (info.new) {
        fd.append ('edit_index_id', 1);
        fd.append ('index_id', indexId);
        var m = page.match (/([0-9]{4})([0-9]{2})([0-9]{2})$/);
        var date = new Date (m[1] + "-" + m[2] + "-" + m[3]);
        var ts = date.valueOf () / 1000;
        if (Number.isFinite (ts)) fd.append ('timestamp', ts);
      }
      if (data.title) fd.append ('title', data.title);
      return Promise.resolve ().then (function () {
        if (sha) fd.append ('source_sha', sha);
        if (sourceSha) fd.append ('source_source_sha', sourceSha);
        fd.append ('source_type', data.source_type);
        fd.append ('body_type', 1); // html
        if (data.bodyHatena) {
          fd.append ('body_source_type', 3); // hatena
          fd.append ('body_source', data.bodyHatena);
          return Formatter.hatena (data.bodyHatena).then (function (body) {
            fd.append ('body', '<hatena-html>' + body + '</hatena-html>');
          });
        } else {
          fd.append ('body', '<hatena-html imported>' + data.body + '</hatena-html>');
          return;
        }
      }).then (function () {
        return gFetch ('o/' + info.objectId + '/edit.json', {post: true, formData: fd});
      }).then (function () {
        return {objectId: info.objectId};
      });
    });
  }; // importDay

  var importDayComments = function (group, imported, site, parentObjectId, comments) {
    return $promised.forEach (function (c) {
      var current = imported[c.url];
      if (current && current.type == 2 /* object */) {
        if (current.sync_info.source_type === 'html' ||
            (current.sync_info.source_type === 'xml' && c.source === 'xml')) {
          return Promise.resolve ();
        }
      }

      var fd = new FormData;
      fd.append ('source_site', site);
      fd.append ('source_page', c.url);
      return gFetch ('o/create.json', {post: true, formData: fd}).then (function (json) {
        var fd = new FormData;
        fd.append ('parent_object_id', parentObjectId);
        fd.append ('timestamp', c.timestamp);
        fd.append ('body_type', 2); // text
        fd.append ('body', c.body);
        fd.append ('author_name', c.author.name);
        if (c.author.url_name) {
          fd.append ('author_hatena_id', c.author.url_name);
        }
        fd.append ('source_type', c.source);
        return gFetch ('o/' + json.object_id + '/edit.json', {post: true, formData: fd});
      });
    }, comments);
  }; // importDayComments

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
                        'createkeywordobjects',
                        'getdiarylist',
                        'creatediary']});
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
        keywords = keywords.reverse ();
        var page = group.getKeywordTopPageURL ();
        var title = keywords.title + 'のキーワード';
        return createIndex (site, page, imported, {
          indexType: 2, // wiki
          title: title,
        }).then (function (index) {
          index.itemCount = keywordCount;
          index.originalTitle = title;
          return mapTable.showObjects ([index], {}).then (function (re) {
            as.stageEnd ('createkeywordwiki');
            as.stageStart ('createkeywordobjects');
            var subAs = getActionStatus (re.items[0]);
            subAs.start ({stages: ['objects']});
            subAs.stageStart ('objects');
            var nextItem; nextItem = function () {
              if (keywords.length === 0) return;
              as.stageProgress ('createkeywordobjects', keywordCount - keywords.length, keywordCount);
              subAs.stageProgress ('objects', keywordCount - keywords.length, keywordCount);
              var keyword = keywords.shift ();
              return importKeyword (group, keyword, index.index_id, imported, site).then (nextItem);
            }; // nextItem
            return nextItem ().then (function () {
              subAs.stageEnd ('objects');
              subAs.end ({ok: true});
            });
          });
        }).then (function () {
          as.stageEnd ('createkeywordobjects');

          as.stageStart ('getdiarylist');
          return group.diarylist ();
        }).then (function (diarys) {
          as.stageEnd ('getdiarylist');
          as.stageStart ('creatediary');
          var diaryCount = diarys.length;
          var diaryI = 0;
          return $promised.forEach (function (diary) {
            var page = group.getDiaryTopPageURL (diary.url_name);
            return createIndex (site, page, imported, {
              indexType: 1, // diary
              title: diary.title,
            }).then (function (index) {
              index.originalTitle = diary.title;
              return mapTable.showObjects ([index], {}).then (function (re) {
                var subAs = getActionStatus (re.items[0]);
                subAs.start ({stages: ['object']});
                subAs.stageStart ('object');
                return group.diaryExport (diary.url_name).then (function (days) {
                  index.itemCount = days.length;
                  fillFields (re.items[0], re.items[0], re.items[0], index);
                  var v = 0;
                  return $promised.forEach (function (day) {
                    subAs.stageProgress ('object', v++, index.itemCount);
                    var page = group.getDiaryDayURLByDate (diary.url_name, day.date);
                    return importDay (group, index.index_id, imported, site, page, day).then (function (d) {
                      day.comments.forEach (function (c) {
                        c.url = page + '#c' + c.timestamp;
                      });
                      return importDayComments (group, imported, site, d.objectId, day.comments);
                    });
                  }, days);
                }).catch (function (e) {
                  if (e && e.isResponse && e.status === 0) {
                    // network error (redirect cancelled) = not exportable
                  } else {
                    throw e;
                  }
                  return group.diaryDayList (diary.url_name).then (function (days) {
                    index.itemCount = days.length;
                    fillFields (re.items[0], re.items[0], re.items[0], index);
                    var v = 0;
                    return $promised.forEach (function (dayURL) {
                      subAs.stageProgress ('object', v++, index.itemCount);
                      return group.diaryDay (dayURL).then (function (r) {
                        return importDay (group, index.index_id, imported, site, dayURL.replace (/^http:/, 'https:'), r).then (function (d) {
                          return importDayComments (group, imported, site, d.objectId, r.comments);
                        });
                      });
                    }, days);
                  });
                }).then (function () {
                  subAs.stageEnd ('object');
                  subAs.end ({ok: true});
                }, function (e) {
                  subAs.end ({error: e});
                  if (e && e.isResponse && e.status === 403) {
                    // private mode
                  } else {
                    throw e;
                  }
                });
              });
            }).then (function () {
              as.stageProgress ('creatediary', ++diaryI, diaryCount);
            });
          }, diarys).then (function () {
            as.stageEnd ('creatediary');
          });
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
      if (ev.data.response) {
        ev.data.response.toString = function () {
          return this.status + ' ' + this.statusText;
        };
        ev.data.response.isResponse = true;
        ng (ev.data.response);
      } else {
        ng (ev.data.message);
      }
    } else {
      ok (ev.data.result);
    }
    this.close ();
  };
  this.port.postMessage (args, [mc.port1]);
  return p;
}; // sendCommand

Importer.Client.prototype.fetchHTML = function (url) {
  var client = this;
  return client.sendCommand ({type: "fetch", url: url, resultType: "text"}).then (function (html) {
    var doc = document.implementation.createHTMLDocument ();
    var base = doc.createElement ('base');
    base.href = client.getOrigin ();
    doc.head.appendChild (base);
    var div = doc.createElement ('div');
    div.innerHTML = html;
    return div;
  });
}; // fetchHTML

Importer.Client.prototype.fetchXML = function (url) {
  var client = this;
  return client.sendCommand ({type: "fetch", url: url, resultType: "text"}).then (function (xml) {
    var parser = new DOMParser;
    var doc = parser.parseFromString (xml, "text/xml");
    // if (doc.querySelector ('parseerror') not well-formed
    return doc;
  });
}; // fetchXML

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

Importer.HatenaGroup.prototype.getDiaryTopPageURL = function (u) {
  return this.getSiteURL () + '/' + u + '/';
}; // getDiaryTopPageURL

Importer.HatenaGroup.prototype.getDiaryDayURLByDate = function (u, d) {
  return this.getSiteURL () + '/' + u + '/' + d.replace (/-/g, '');
}; // getDiaryDayURLByDate

Importer.HatenaGroup.prototype.keywordlist = function () {
  var client = this.client;
  var result = [];
  // /keywordlist?mode=rss does not support paging :-<
  var getPage = function (url) {
    return client.fetchHTML (url).then (function (div) {
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
  return client.fetchHTML ('/keyword/' + encodeURIComponent (keyword)).then (function (div) {
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
    return client.fetchHTML (url).then (function (div) {
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

Importer.HatenaGroup.prototype.diaryDayList = function (urlName) {
  var client = this.client;
  return client.fetchHTML ('/' + urlName + '/archive').then (function (div) {
    var monthURLList = $$ (div, '#archive-calendar-top a.month').map (function (e) {
      return e.href;
    });
    var dayURLList = [];
    return $promised.forEach (function (url) {
      return client.fetchHTML (url).then (function (div) {
        $$ (div, '.day .body .archive-date a[href]').forEach (function (e) {
          dayURLList.push (e.href);
        });
      });
    }, monthURLList.reverse ()).then (function () {
      return dayURLList;
    });
  });
}; // diaryDayList

Importer.HatenaGroup.prototype.diaryDay = function (url) {
  var client = this.client;
  return client.fetchHTML (url).then (function (div) {
    var title = div.querySelector ('.day h2 .title');

    var body = div.querySelector ('.day .body');
    $$ (body, 'a[href]:not([href^="http:"]):not([href^="https:"])').forEach (function (e) {
      e.href = e.href;
    });
    $$ (body, 'img[src]:not([src^="http:"]):not([src^="https:"])').forEach (function (e) {
      e.src = e.src;
    });

    var comments = $$ (div, '.comment .commentshort').map (function (e) {
      var comment = {author: {}, source: 'html'};

      var user = e.querySelector ('.commentator');
      comment.author.name = user.textContent;
      var userLink = user.querySelector ('a.hatena-id-icon');
      if (userLink) {
        var m = userLink.pathname.match (/^\/([^\/]+)\//);
        comment.author.url_name = m[1];
      }

      var ts = e.querySelector ('.timestamp a');
      comment.url = ts.href.replace (/^http:/, 'https:');
      comment.timestamp = ts.name.replace (/^c/, '');
      comment.body = e.querySelector ('.commentbody').textContent;

      return comment;
    });

    return {title: title ? title.textContent : null, body: body.innerHTML,
            comments: comments, source_type: 'html'};
  });
}; // diaryDay

Importer.HatenaGroup.prototype.diaryExport = function (urlName) {
  var client = this.client;
  return client.fetchXML ('/' + urlName + '/export').then (function (doc) {
    var days = [];
    Array.prototype.forEach.call ((doc.documentElement || {children: []}).children, function (e) {
      if (e.localName === 'day') {
        var day = {
          date: e.getAttribute ('date') || '',
          title: e.getAttribute ('title') || '',
          comments: [],
          source_type: 'xml',
        };

        var body = e.querySelector ('body');
        day.bodyHatena = body ? body.textContent : '';

        $$ (e, 'comment').forEach (function (f) {
          var comment = {author: {}, source: 'xml'};
          var g = f.querySelector ('username');
          if (g) comment.author.name = g.textContent;
          var h = f.querySelector ('body');
          comment.body = h ? h.textContent : '';
          var i = f.querySelector ('timestamp');
          comment.timestamp = i.textContent;
          day.comments.push (comment);
        });

        days.push (day);
      }
    });
    return days;
  });
}; // diaryExport

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
