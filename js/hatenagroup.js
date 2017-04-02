
self.HatenaGroup = {};

(function () {
  HatenaGroup.get = function (gName, path, type) {
    var fd = new FormData;
    fd.append ('group_name', gName);
    fd.append ('path', path);
    return fetch ('/import/hatenagroup/' + type, {
      method: 'POST',
      body: fd,
      credentials: "same-origin",
      referrerPolicy: 'origin',
    }).then (function (res) {
      if (res.status === 200) {
        if (type === 'feed') {
          return res.json ();
        } else {
          return res.text ();
        }
      } else if (res.status === 400 &&
                 (res.headers.get ('content-type') || '').toLowerCase ().match (/^application\/json\s*;\s*charset="?utf-8"?$/)) {
        return res.json ();
      } else {
        throw res;
      }
    });
  }; // get

  HatenaGroup.keywordlist = function (gName) {
    var result = [];
    // /keywordlist?mode=rss does not support paging :-<
    var getPage = function (url) {
      return HatenaGroup.get (gName, url, 'bare').then (function (html) {
        if (html.status) throw html;
        var doc = document.implementation.createHTMLDocument ();
        var base = doc.createElement ('base');
        base.href = 'https://' + gName + '.g.hatena.ne.jp';
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

  HatenaGroup.diarylist = function (gName) {
    var result = [];
    // /diarylist?mode=rss does not support paging :-<
    var getPage = function (url) {
      return HatenaGroup.get (gName, url, 'bare').then (function (html) {
        if (html.status) throw html;
        var doc = document.implementation.createHTMLDocument ();
        var base = doc.createElement ('base');
        base.href = 'https://' + gName + '.g.hatena.ne.jp';
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

  // throws {status: 302} if gName is not found or not accessible
  // throws {status: 403} if uName is not a group member or not accessible
  HatenaGroup.diary = function (gName, uName) {
    var result = [];
    var getPage = function (of) {
      var url = '/' + uName + '/rss?of=' + of;
      return HatenaGroup.get (gName, url, 'feed').then (function (rss) {
        if (rss.status) throw rss;
        if (rss.entries.length === 0) return;
        var found = {};
        rss.entries.map (function (e) {
          result.push (e);
          var m = e.page_url.match (/\/\/[^\/]+\/[^\/]+\/([^\/]+)/);
          if (!found[m[1]]) {
            of++;
            found[m[1]] = true;
          }
        });
        return getPage (of);
      });
    }; // getPage
    return getPage (0).then (function () {
      return result;
    });
  }; // diary

}) ();