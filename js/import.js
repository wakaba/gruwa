function Importer () { }

Importer.getImported = function (site) {
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

Importer.createIndex = function (site, page, imported, opts) {
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

// XXX cancel
Importer.run = function (sourceId, statusContainer, opts) {
  var as = getActionStatus (statusContainer);
  var mapTable = statusContainer.querySelector ('.mapping-table');
  mapTable.querySelector ('table').hidden = false;
  mapTable.clearObjects ();
  statusContainer.scrollIntoViewIfNeeded ();

  var needKeywordlogs = false;
  var keywordIndexId;

  var hatenaHtmlStartTag = function (opts) {
    var startTag = document.createElement ('br');
    if (opts.starMap) {
      startTag.setAttribute ('starmap', Object.keys (opts.starMap).map (function (u) {
        return u + ' ' + opts.starMap[u];
      }).join (' '));
    }
    if (opts.imported) startTag.setAttribute ('imported', '');
    if (keywordIndexId) startTag.setAttribute ('keywordindexid', keywordIndexId);
    if (opts.base) startTag.setAttribute ('base', opts.base);
    return startTag.outerHTML.replace (/^<br/, '<hatena-html');
  }; // hatenaHtmlStartTag

  var importKeyword = function (group, keyword, indexId, imported, site) {
    if (needKeywordlogs) return Promise.resolve ();

    var page = group.getKeywordPageURL (keyword.title);
    var current = imported[page];
    if (current && current.type == 2 /* object */) {
      var currentTimestamp = parseFloat (current.sync_info.timestamp);
      current.hasLatestData = (
        Number.isFinite (currentTimestamp) &&
        currentTimestamp >= keyword.updated.valueOf () / 1000
      );
      if (current.hasLatestData &&
          current.sync_info.source_type === 'keywordlog') {
        return Promise.resolve ();
      }
    }

    var createObject = function () {
      if (current && current.type == 2 /* object */) {
        return Promise.resolve (current.dest_id);
      }

      var fd = new FormData;
      fd.append ('source_site', site);
      fd.append ('source_page', page);
      return gFetch ('o/create.json', {post: true, formData: fd}).then (function (json) {
        return json.object_id;
      });
    }; // createObject

    return group.keywordHistory (keyword.title).then (function (historys) {
      return createObject ().then (function (objectId) {
        var currentRevTS = parseFloat (current && current.sync_info.rev_timestamp);
        return $promised.forEach (function (history) {
          if (history.date &&
              Number.isFinite (currentRevTS) &&
              history.date.valueOf () / 1000 <= currentRevTS) return;

          return group.keywordlog (history.url.replace (/^https?:/, '')).then (function (r) {
            var fd = new FormData;
            fd.append ('source_type', 'keywordlog');
            fd.append ('revision_author_hatena_id', history.author.url_name);
            if (history.date) {
              var ts = history.date.valueOf () / 1000;
              fd.append ('revision_timestamp', ts);
              fd.append ('source_timestamp', ts);
              fd.append ('source_rev_timestamp', ts);
            }
            fd.append ('revision_imported_url', history.url);
            fd.append ('edit_index_id', 1);
            fd.append ('index_id', indexId);
            fd.append ('title', keyword.title);
            fd.append ('body_type', 1); // html
            fd.append ('body_source_type', 3); // hatena
            var hatena = '>' + hatenaHtmlStartTag ({base: page}) + "<\n\n" + r.bodyHatena + '\n\n></hatena-html><';
            fd.append ('body_source', hatena);
            return Formatter.hatena (hatena).then (function (body) {
              fd.append ('body', body);
            }).then (function () {
              return gFetch ('o/' + objectId + '/edit.json', {post: true, formData: fd});
            });
          });
        }, historys.reverse ());
      });
    }).catch (function (e) {
      if (e && e.isResponse && e.status === 0) {
        // network error (redirect cancelled) = not exportable
      } else if (/^Failed to obtain list of revisions of keyword /.test (e)) {
        needKeywordlogs = true;
        return Promise.resolve ();
      } else {
        throw e;
      }

      if (current && current.hasLatestData) {
        return Promise.resolve ();
      }
      
      var cO = createObject ();
      return group.keywordhtml (keyword.title).then (function (html) {
        return cO.then (function (objectId) {
          var fd = new FormData;
          fd.append ('edit_index_id', 1);
          fd.append ('index_id', indexId);
          fd.append ('title', keyword.title);
          fd.append ('body_type', 1); // html
          fd.append ('body', hatanaHtmlStartTag ({imported: true}) + html + '</hatena-html>');
          var ts = keyword.updated.valueOf () / 1000;
          fd.append ('revision_timestamp', ts);
          fd.append ('source_timestamp', ts);
          if (current && current.sync_info.rev_timestamp) {
            fd.append ('source_rev_timestamp', current.sync_info.rev_timestamp);
          }
          fd.append ('source_type', 'html');
          fd.append ('revision_imported_url', page);
          return gFetch ('o/' + objectId + '/edit.json', {post: true, formData: fd});
        });
      });
    });
  }; // importKeyword

  var importFromKeywordlogs = function (group, indexId, imported, site) {
    var importById = function (id) {
      return group.keywordlog ('/keywordlog?klid=' + id).then (function (r) {
        if (!r) return false;

        var page = group.getKeywordPageURL (r.title);
        var current = imported[page];
        if (current && current.type == 2 /* object */) {
          var currentTimestamp = parseFloat (current.sync_info.timestamp);
          current.hasLatestData = (
            Number.isFinite (currentTimestamp) &&
            currentTimestamp >= r.date.valueOf () / 1000
          );
          if (current.hasLatestData &&
              current.sync_info.source_type === 'keywordlog') {
            return true;
          }
        }

        var createObject = function () {
          if (current && current.type == 2 /* object */) {
            return Promise.resolve (current.dest_id);
          }

          var fd = new FormData;
          fd.append ('source_site', site);
          fd.append ('source_page', page);
          return gFetch ('o/create.json', {post: true, formData: fd}).then (function (json) {
            imported[page] = {type: 2, sync_info: {}, dest_id: json.object_id};
            return json.object_id;
          });
        }; // createObject

        return createObject ().then (function (objectId) {
          var currentRevTS = parseFloat (current && current.sync_info.rev_timestamp);
          if (r.date &&
              Number.isFinite (currentRevTS) &&
              r.date.valueOf () / 1000 <= currentRevTS) return;

          var fd = new FormData;
          fd.append ('source_type', 'keywordlog');
          fd.append ('revision_author_hatena_id', r.author.url_name);
          if (r.date) {
            var ts = r.date.valueOf () / 1000;
            fd.append ('revision_timestamp', ts);
            fd.append ('source_timestamp', ts);
            fd.append ('source_rev_timestamp', ts);
          }
          fd.append ('revision_imported_url', r.url);
          fd.append ('edit_index_id', 1);
          fd.append ('index_id', indexId);
          fd.append ('title', r.title);
          fd.append ('body_type', 1); // html
          fd.append ('body_source_type', 3); // hatena
          var hatena = '>' + hatenaHtmlStartTag ({base: page}) + "<\n\n" + r.bodyHatena + '\n\n></hatena-html><';
          fd.append ('body_source', hatena);
          return Formatter.hatena (hatena).then (function (body) {
            fd.append ('body', body);
          }).then (function () {
            return gFetch ('o/' + objectId + '/edit.json', {post: true, formData: fd});
          });
        }).then (function () {
          return true;
        });
      });
    }; // importById

    var nextId = 1;
    var runNext = function () {
      return importById (nextId).then (function (result) {
        if (!result) return;
        nextId++;
        return runNext ();
      });
    }; // runNext
    return runNext ();
  }; // importFromKeywordlogs

  var divide = function (array, n) {
    var list = [];
    var i = 0;
    var length = array.length;
    while (i + n < length) {
      list.push (array.slice (i, i + n));
      i += n;
    }
    if (i < length) list.push (array.slice (i, length));
    return list;
  }; // divide

  var importDayStars = function (group, client, imported, site, page, data, gotObjectId, setStarMap) {
    var sectionNames = [];
    if (data.source_type === 'html') {
      var div = Formatter.html (data.body);
      sectionNames = $$ (div, 'div.section h3.title a[name]').map (function (a) {
        return a.name;
      });
    } else if (data.source_type === 'export') {
      sectionNames = (data.bodyHatena.match (/^\*[^*\s]+\*/gm) || []).map (function (_) {
        return _.replace (/^\*/, '').replace (/\*$/, '');
      });
    }

    var starMap = {};
    if (!sectionNames.length) {
      setStarMap (starMap);
      return Promise.resolve ();
    }

    var starURLs = {};
    var starLists = {};
    sectionNames.forEach (function (id) {
      var here = page + '/' + id;
      starURLs[page + '#' + id] = here;
      starURLs[page + '/' + id] = here;
      starURLs[page.replace (/^https:/, 'http:') + '#' + id] = here;
      starURLs[page.replace (/^https:/, 'http:') + '/' + id] = here;
      starLists[here] = [];
      starLists[here].id = id;
    });
    var comments = [];

    var starURLSets = divide (Object.keys (starURLs), 20);
    return $promised.forEach (function (starURLs) {
      return client.sendCommand ({
        type: "hatenaStar",
        starURLs: starURLs,
      }).then (function (json) {
        json.entries.forEach (function (entry) {
          var url = starURLs[entry.uri];

          var stars = starLists[url];
          (entry.stars || []).forEach (function (star) {
            stars.push ([star.name, 0, parseInt (star.count || 1), star.quote]);
          });
          (entry.colored_stars || []).forEach (function (_) {
            var type = {
              green: 1,
              red: 2,
              blue: 3,
              purple: 4,
            }[_.color];
            (_.stars || []).forEach (function (star) {
              stars.push ([star.name, type, parseInt (star.count || 1), star.quote]);
            });
          });

          (entry.comments || []).forEach (function (comment) {
            comment.section_id = stars.id;
            comments.push (comment);
          });
        });
      });
    }, starURLSets).then (function () {
      return $promised.forEach (function (url) {
        var starPage = new URL (site + '#star:' + encodeURIComponent (url)).toString ();
        var stars = {};
        starLists[url].forEach (function (star) {
          var key = [star[0], star[1], star[3]].join (",");
          if (stars[key]) {
            stars[key][2] += star[2];
          } else {
            stars[key] = star;
          }
        });
        stars = Object.values (stars).sort (function (a, b) {
          return ((a[0] < b[0] ? -1 : a[0] > b[0] ? +1 : 0) ||
                  (a[1] - b[1]) ||
                  (a[3] < b[3] ? -1 : a[3] > b[3] ? +1 : 0));
        });

        var sha = sha1 (stars.toString ());
        var current = imported[starPage];
        if (current && current.type == 2 /* object */) {
          if (current.sync_info.sha === sha) {
            starMap[starLists[url].id] = current.dest_id;
            return;
          }
        }

        var fd = new FormData;
        fd.append ('source_site', site);
        fd.append ('source_page', starPage);
        return gFetch ('o/create.json', {
          post: true,
          formData: fd,
        }).then (function (json) {
          starMap[starLists[url].id] = json.object_id;
          return gotObjectId.then (function (parentObjectId) {
            var fd = new FormData;
            fd.append ('parent_object_id', parentObjectId);
            fd.append ('source_sha', sha);
            fd.append ('timestamp', 0);
            fd.append ('body_type', 3); // data
            fd.append ('body_data', JSON.stringify ({hatena_star: stars}));
            return gFetch ('o/' + json.object_id + '/edit.json', {
              post: true,
              formData: fd,
            });
          });
        });
      }, Object.keys (starLists)).then (function () {
        setStarMap (starMap);
      });
    }).then (function () {
      return $promised.forEach (function (comment) {
        var commentPage = new URL (site + '#starcomment:' + encodeURIComponent (comment.id)).toString ();

        var current = imported[commentPage];
        if (current && current.type == 2 /* object */) {
          return;
        }

        var fd = new FormData;
        fd.append ('source_site', site);
        fd.append ('source_page', commentPage);
        return gFetch ('o/create.json', {
          post: true,
          formData: fd,
        }).then (function (json) {
          return gotObjectId.then (function (parentObjectId) {
            var fd = new FormData;
            fd.append ('parent_object_id', parentObjectId);
            fd.append ('body_type', 2); // plain text
            fd.append ('author_name', comment.name);
            fd.append ('author_hatena_id', comment.name);
            fd.append ('body', comment.body);
            fd.append ('parent_section_id', comment.section_id);
            return gFetch ('o/' + json.object_id + '/edit.json', {
              post: true,
              formData: fd,
            });
          });
        });
      }, comments);
    });
  }; // importDayStars

  var importDay = function (group, client, indexId, imported, site, page, urlName, data) {
    var setObjectId;
    var gotObjectId = new Promise (function (_) { setObjectId = _ });
    var setStarMap;
    var gotStarMap = new Promise (function (_) { setStarMap = _ });
    var starPromise = importDayStars (group, client, imported, site, page, data, gotObjectId, setStarMap);

    var sha = data.source_type === 'html' ? sha1 ([data.title, data.body].join ("\n")) : null;
    var sourceSha = data.source_type === 'export' ? sha1 ([data.title, data.bodyHatena].join ("\n")) : null;
    var current = imported[page];
    if (current && current.type == 2 /* object */) {
      if (sourceSha && current.sync_info.source_sha === sourceSha) {
        setObjectId (imported[page].dest_id);
        return starPromise.then (function () {
          return {objectId: imported[page].dest_id};
        });
      }
      if (sha && current.sync_info.sha === sha) {
        setObjectId (imported[page].dest_id);
        return starPromise.then (function () {
          return {objectId: imported[page].dest_id};
        });
      }
      sha = sha || current.sync_info.sha || null;
      sourceSha = sourceSha || current.sync_info.source_sha || null;
    }

    return Promise.resolve ().then (function () {
      if (imported[page] && imported[page].type == 2 /* object */) {
        setObjectId (imported[page].dest_id);
        return {objectId: imported[page].dest_id, new: false};
      }

      var fd = new FormData;
      fd.append ('source_site', site);
      fd.append ('source_page', page);
      return gFetch ('o/create.json', {post: true, formData: fd}).then (function (json) {
        setObjectId (json.object_id);
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
      return gotStarMap.then (function (starMap) {
        if (sha) fd.append ('source_sha', sha);
        if (sourceSha) fd.append ('source_source_sha', sourceSha);
        fd.append ('source_type', data.source_type);
        fd.append ('revision_imported_url', page);
        fd.append ('author_name', urlName);
        fd.append ('author_hatena_id', urlName);
        fd.append ('body_type', 1); // html
        if (data.bodyHatena) {
          fd.append ('body_source_type', 3); // hatena
          var hatena = '>' + hatenaHtmlStartTag ({starMap: starMap, base: page}) + "<\n\n" + data.bodyHatena + '\n\n></hatena-html><';
          fd.append ('body_source', hatena);
          return Formatter.hatena (hatena).then (function (body) {
            fd.append ('body', body);
          });
        } else { // HTML
          fd.append ('body', hatenaHtmlStartTag ({imported: true, starMap: starMap, base: page}) + data.body + '</hatena-html>');
          return;
        }
      }).then (function () {
        return gFetch ('o/' + info.objectId + '/edit.json', {post: true, formData: fd});
      }).then (function () {
        return starPromise;
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
            (current.sync_info.source_type === 'export' && c.source === 'export')) {
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
        fd.append ('revision_timestamp', c.timestamp);
        fd.append ('body_type', 2); // text
        fd.append ('body', c.body);
        fd.append ('revision_imported_url', c.url);
        fd.append ('author_name', c.author.name);
        fd.append ('revision_author_name', c.author.name);
        if (c.author.url_name) {
          fd.append ('author_hatena_id', c.author.url_name);
          fd.append ('revision_author_hatena_id', c.author.url_name);
        }
        fd.append ('source_type', c.source);
        return gFetch ('o/' + json.object_id + '/edit.json', {post: true, formData: fd});
      });
    }, comments);
  }; // importDayComments

  var importFile = function (group, client, file, indexId, imported, site, as) {
    file.canonURL = file.url.replace (/^http:/, 'https:')
        /*
          URL here contains an extension ("." followed by three
          characters).  The "file syntax" used to link to the file in
          a Hatena syntax text, such as "[file:9a5f8b9717bb1281]" does
          not contain the extension but is expanded to a link to a URL
          with the extension (by looking up the database in Hatena
          Group).  To decouple Hatena syntax - HTML convertion from
          the database, we strip the extension here.  The URL can then
          be looked up later by exact match without extension.  The
          extension part of the URL can be restored from the file name
          later, if necessary.
        */
        .replace (/\.[^\.]+$/, '');
    var current = imported[file.canonURL];
    if (current && current.type == 2 /* object */) {
      var currentTimestamp = parseFloat (current.sync_info.timestamp);
      current.hasLatestData = (
        Number.isFinite (currentTimestamp) &&
        currentTimestamp >= (file.date ? file.date.valueOf () / 1000 : 0)
      );
      if (current.hasLatestData) {
        return Promise.resolve ();
      }
    }

    return client.fetchBlob (file.url.replace (/^https?:/, '')).then (function (blob) {
      return uploadFile (blob, {
        file_name: file.name,
        file_size: file.size,
        mime_type: file.type, // or null
        timestamp: file.date ? file.date.valueOf () / 1000 : null,
        index_id: indexId,
        sourceSite: site,
        sourcePage: file.canonURL,
        sourceTimestamp: file.date ? file.date.valueOf () / 1000 : null,
      }, as);
    });
  }; // importFile

    as.start ({stages: ['getimported',
                        'getkeywordlist',
                        'createkeywordwiki',
                        'createkeywordobjects',
                        'getdiarylist',
                        'creatediary',
                        'getfilelist',
                        'createfileuploader',
                        'getfiles']});
    return Importer.createClient (sourceId).then (function (client) {
      var group = new Importer.HatenaGroup (client);
      var site = group.getSiteURL ();
      as.stageStart ('getimported');
      var gI = opts.forceUpdate ? Promise.resolve ({}) : Importer.getImported (site);
      return gI.then (function (imported) {
        as.stageEnd ('getimported');

      as.stageStart ('getkeywordlist');
      return group.keywordlist ().then (function (keywords) {
        as.stageEnd ('getkeywordlist');
        if (keywords.length === 0) return;
        as.stageStart ('createkeywordwiki');
        keywords = keywords.reverse ();
        var page = group.getKeywordTopPageURL ();
        var title = keywords.title + 'のキーワード';
        return Importer.createIndex (site, page, imported, {
          indexType: 2, // wiki
          title: title,
        }).then (function (index) {
          index.itemCount = keywords.length;
          index.originalTitle = title;
          keywordIndexId = index.index_id;
          return mapTable.showObjects ([index], {}).then (function (re) {
            as.stageEnd ('createkeywordwiki');
            as.stageStart ('createkeywordobjects');
            var subAs = getActionStatus (re.items[0]);
            subAs.start ({stages: ['objects']});
            subAs.stageStart ('objects');
            var c = 0;
            return $promised.forEach (function (keyword) {
              as.stageProgress ('createkeywordobjects', c, keywords.length);
              subAs.stageProgress ('objects', c, keywords.length);
              c++;
              return importKeyword (group, keyword, index.index_id, imported, site);
            }, keywords).then (function () {
              if (needKeywordlogs) {
                return importFromKeywordlogs (group, index.index_id, imported, site);
              }
            }).then (function () {
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
            return Importer.createIndex (site, page, imported, {
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
                  fillFields (re.items[0], re.items[0], re.items[0], index, {});
                  var v = 0;
                  return $promised.forEach (function (day) {
                    subAs.stageProgress ('object', v++, index.itemCount);
                    var page = group.getDiaryDayURLByDate (diary.url_name, day.date);
                    return importDay (group, client, index.index_id, imported, site, page, diary.url_name, day).then (function (d) {
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
                    fillFields (re.items[0], re.items[0], re.items[0], index, {});
                    var v = 0;
                    return $promised.forEach (function (dayURL) {
                      subAs.stageProgress ('object', v++, index.itemCount);
                      return group.diaryDay (dayURL).then (function (r) {
                        return importDay (group, client, index.index_id, imported, site, dayURL.replace (/^http:/, 'https:'), diary.url_name, r).then (function (d) {
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
      }).then (function () {
        as.stageStart ('getfilelist');
        return group.filelist ().then (function (files) {
          as.stageEnd ('getfilelist');
          as.stageStart ('createfileuploader');
          var page = group.getFileTopPageURL ();
          return Importer.createIndex (site, page, imported, {
            indexType: 6, // uploader
            title: files.title,
          }).then (function (index) {
            index.itemCount = files.length;
            index.originalTitle = files.title;
            if (index.itemCount === 0) return;
            return mapTable.showObjects ([index], {}).then (function (re) {
              var subAs = getActionStatus (re.items[0]);
              subAs.start ({stages: ['objects']});
              subAs.stageStart ('objects');
              as.stageEnd ('createfileuploader');
              as.stageStart ('getfiles');
              var c = 0;
              return $promised.forEach (function (file) {
                as.stageProgress ('getfiles', c, files.length);
                subAs.stageProgress ('objects', c, files.length);
                c++;
                var nullAs = getActionStatus (null);
                nullAs.start ({stages: []});
                return importFile (group, client, file, index.index_id, imported, site, nullAs);
              }, files.reverse ()).then (function () {
                subAs.stageEnd ('objects');
                subAs.end ({ok: true});
                as.stageEnd ('getfiles');
              });
            });
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

$with ('Loaders').then (function (Loaders) {
  Loaders.define ('import', function () {
    return Importer.getImportSources ().then (function (results) {
      return {sources: results};
    });
  }); // import
});

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
      console.log ("Error received", ev.data);
      if (ev.data.response) {
        ev.data.response.toString = function () {
          return this.type + ' ' + this.status + ' ' + this.statusText;
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

Importer.Client.prototype.fetchBlob = function (url) {
  var client = this;
  return client.sendCommand ({type: "fetch", url: url, resultType: "blob"});
}; // fetchBlob

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
  return this.getSiteURL () + this.getKeywordPagePath (k);
}; // getKeywordPageURL

Importer.HatenaGroup.prototype.getKeywordPagePath = function (k) {
  return '/keyword/' + encodeURIComponent (k).replace (/%2F/g, '/');
}; // getKeywordPagePath

Importer.HatenaGroup.prototype.getDiaryTopPageURL = function (u) {
  return this.getSiteURL () + '/' + u + '/';
}; // getDiaryTopPageURL

Importer.HatenaGroup.prototype.getDiaryDayURLByDate = function (u, d) {
  return this.getSiteURL () + '/' + u + '/' + d.replace (/-/g, '');
}; // getDiaryDayURLByDate

Importer.HatenaGroup.prototype.getFileTopPageURL = function () {
  return this.getSiteURL () + '/filelist';
}; // getFileTopPageURL

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
  return client.fetchHTML (this.getKeywordPagePath  (keyword)).then (function (div) {
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

Importer.HatenaGroup.prototype.keywordHistory = function (keyword) {
  var client = this.client;
  return client.fetchHTML (this.getKeywordPagePath (keyword) + '?mode=edit').then (function (div) {
    var historys = $$ (div, '.day .refererlist li').map (function (li) {
      var history = {author: {}};
      var link = li.querySelector ('a');
      history.url = link.href.replace (/^http:/, 'https:');
      var m = ((link.nextSibling || {}).data || '').match
          (/([0-9]+\/[0-9]+\/[0-9]+\s+[0-9]+:[0-9]+:[0-9]+)/);
      if (m) history.date = new Date (m[1].replace (/\s+/, 'T').replace (/\//g, '-') + '+09:00');

      var userLink = li.querySelector ('a.hatena-id-icon');
      if (userLink) {
        var m = userLink.pathname.match (/^\/([^\/]+)\//);
        if (m) history.author.url_name = m[1];
      }

      return history;
    });
    if (historys.length === 0) {
      // Keyword not found or the user has no right to edit the keyword.
      throw "Failed to obtain list of revisions of keyword " + keyword;
    }
    return historys;
  });
}; // keywordHistory

Importer.HatenaGroup.prototype.keywordlog = function (url) {
  var client = this.client;
  return client.fetchHTML (url).then (function (div) {
    var container = div.querySelector ('.day');
    if (!container) return null;

    var log = {
      url: new URL (url, client.getOrigin ()).toString ().replace (/^http:/, 'https:'),
      title: div.querySelector ('.day h2 .title').textContent,
      author: {},
      bodyHatena: '',
    };

    // If the body is empty, there is no textarea.
    var body = div.querySelector ('.day .body textarea[name=body]');
    if (body) log.bodyHatena = body.value;

    var m = ((div.querySelector ('.day .body .footnote .footnote') || {}).textContent || "").match
          (/([0-9]+\/[0-9]+\/[0-9]+\s+[0-9]+:[0-9]+:[0-9]+)/);
    if (m) log.date = new Date (m[1].replace (/\s+/, 'T').replace (/\//g, '-') + '+09:00');

    var userLink = div.querySelector ('.day .body .footnote a');
    if (userLink) {
      var m = userLink.pathname.match (/^\/([^\/]+)\//);
      if (m) log.author.url_name = m[1];
    }

    return log;
  });
}; // keywordlog

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
          source_type: 'export',
        };

        var body = e.querySelector ('body');
        day.bodyHatena = body ? body.textContent : '';

        $$ (e, 'comment').forEach (function (f) {
          var comment = {author: {}, source: 'export'};
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

Importer.HatenaGroup.prototype.filelist = function () {
  var client = this.client;
  var files = [];
  var getPage = function (url, page) {
    return client.fetchXML (url + '&page=' + page).then (function (doc) {
      files.title = ($$ (doc, 'rss > channel > title')[0] || {}).textContent;

      var items = $$ (doc, 'item');
      if (!items.length) return;

      items.forEach (function (item) {
        var file = {};
        Array.prototype.forEach.call (item.children, function (e) {
          if (e.localName === 'title') {
            file.name = e.textContent;
          } else if (e.localName === 'pubDate') {
            var date = new Date (e.textContent);
            if (Number.isFinite (date.valueOf ())) {
              file.date = date;
            }
          } else if (e.localName === 'enclosure') {
            file.size = parseInt (e.getAttribute ('length'));
            file.type = e.getAttribute ('type') || '';
            file.url = e.getAttribute ('url');
            if (file.type === '') delete file.type;
          }
        });
        files.push (file);
      });

      return getPage (url, page + 1);
    });
  }; // getPage
  return getPage ('/filelist?mode=rss', 1).then (function () {
    return files;
  });
}; // filelist

Importer.BitBucket = function () {

}; // Importer.BitBucket

Importer.BitBucket.prototype.getAccessToken = function (opts) {
  if (!this._accessTokenPromise) {
    this._accessTokenPromise = new Promise (function (ok, ng) {
      if (opts.as) opts.as.stageStart ('auth');
      var windowName = 'gruwabboauth' + Math.random ();
      var childWindow = window.open ('https://bitbucket.org/site/oauth2/authorize?client_id=' + encodeURIComponent (document.documentElement.getAttribute ('data-bb-clientid')) + '&response_type=token', windowName);
      var receiveMessage = function (ev) {
        if (ev.origin === location.origin &&
            ev.data.name === windowName) {
          var accessToken = null;
          ev.data.hash.replace (/^#/, '').split (/&/).forEach (function (_) {
            var v = _.split (/=/, 2);
            if (v[0] === 'access_token') {
              accessToken = decodeURIComponent (v[1]);
            }
          });
          ok (accessToken); // or null
          window.removeEventListener ('message', receiveMessage);
          childWindow.close ();
          if (opts.as) opts.as.stageEnd ('auth');
        }
      }; // receiveMessage
      window.addEventListener ('message', receiveMessage);
    }); // promise
  }
  return this._accessTokenPromise;
}; // getAccessToken

Importer.BitBucket.prototype.apiFetch = function (opts) {
  return this.getAccessToken ({as: opts.as}).then (function (token) {
    var url = 'https://api.bitbucket.org/2.0/' + opts.path.map (function (_) {
      return encodeURIComponent (_);
    }).join ('/');
    if (opts.page) {
      url += '?page=' + encodeURIComponent (opts.page);
    }
    return fetch (url, {headers: {
      authorization: "Bearer " + token,
    }}).then (function (res) {
      if (res.status !== 200) throw res;
      return res.json ();
    });
  }).then (function (json) {
    return json;
  });
}; // apiFetch

Importer.BitBucket.prototype.apiFetchPages = function (opts) {
  var self = this;
  var result = [];
  opts.page = 1;
  var run = function () {
    return self.apiFetch (opts).then (function (json) {
      result = result.concat (json.values);
      if (json.values.length && ! (opts.page > 100)) {
        opts.page++;
        return run ();
      }
      return result;
    });
  }; // run
  return run ();
}; // apiFetchPages

Importer.BitBucket.prototype.currentUser = function (opts) {
  return this.apiFetch ({path: ['user'], as: opts.as});
  /*
    created_on
    display_name username uuid
    location website
  */
}; // currentUser

Importer.BitBucket.prototype.currentUserRepositories = function (opts) {
  var self = this;
  return self.currentUser ({as: opts.as}).then (function (user) {
    return self.apiFetchPages ({path: ['repositories', user.uuid], as: opts.as});
  });
  /*
    Array of
      created_on updated_on
      description language website
      fork_policy has_issues has_wiki is_private
      mainbranch.name scm
      size
      full_name slug uuid name
      owner
  */
}; // currentUserRepositories

$with ('Loaders').then (function (Loaders) {
  Loaders.define ('bitbucket-repos', function () {
    var bb = new Importer.BitBucket;
    return bb.currentUserRepositories ({}).then (function (_) {
      return {repos: _.filter (function (_) { return _.has_issues })};
    });
  }); // bitbucket-repos
});

Importer.BitBucket.prototype.issues = function (name, repo, opts) {
  return this.apiFetchPages ({path: ['repositories', name, repo, 'issues'], as: opts.as});
  /*
    Array of:
      assignee reporter
      component
      content
      created_on edited_on updated_on
      id
      kind priority state
      milestone version
      title
      votes watches
  */
}; // issues

Importer.BitBucket.prototype.issueComments = function (name, repo, issueId, opts) {
  return this.apiFetchPages ({path: ['repositories', name, repo, 'issues', issueId, 'comments'], as: opts.as});
  /*
    Array of:
      content
      created_on updated_on
      id
      user
  */
}; // issueComments

Importer.BitBucket.prototype.run = function (name, repo, statusContainer, opts) {
  var self = this;

  var as = getActionStatus (statusContainer);
  var mapTable = statusContainer.querySelector ('.mapping-table');
  mapTable.querySelector ('table').hidden = false;
  mapTable.clearObjects ();
  as.start ({stages: ['auth', 'getimported', 'createtodo', 'getissuelist',
                      'createissueobjects']});
  statusContainer.scrollIntoViewIfNeeded ();

  var getIssues = self.issues (name, repo, {as: as});

  var site = "https://bitbucket.org/" + name + "/" + repo;

  as.stageStart ('getimported');
  var gI = opts.forceUpdate ? Promise.resolve ({}) : Importer.getImported (site);
  return gI.then (function (imported) {
    as.stageEnd ('getimported');

    as.stageStart ('createtodo');
    var page = site + "/issues";
    var title = name + " / " + repo + " / issues"; // as in <title>
    return Importer.createIndex (site, page, imported, {
      indexType: 3, // TODO
      title: title,
    }).then (function (index) {
      as.stageEnd ('createtodo');
      as.stageStart ('getissuelist');

      return getIssues.then (function (list) {
        as.stageEnd ('getissuelist');

        index.itemCount = list.length;
        index.originalTitle = title;
        if (index.itemCount === 0) return;
        return mapTable.showObjects ([index], {}).then (function (re) {
          var subAs = getActionStatus (re.items[0]);
          subAs.start ({stages: ['objects']});
          subAs.stageStart ('objects');
          as.stageStart ('createissueobjects');

          var c = 0;
          return $promised.forEach (function (issue) {
            as.stageProgress ('createissueobjects', c, list.length);
            subAs.stageProgress ('objects', c, list.length);
            c++;

            var page = site + "/issues/" + issue.id;
            var issueTimestamp = new Date (issue.updated_on || issue.created_on).valueOf () / 1000;

            var current = imported[page];
            if (current && current.type == 2 /* object */) {
              var currentTimestamp = parseFloat (current.sync_info.timestamp);
              if (issueTimestamp === currentTimestamp) {
                return; // nothing to do for this issue
              }
            }

            var createObject = function (page) {
              var current = imported[page];
              if (current && current.type == 2 /* object */) {
                return Promise.resolve (current.dest_id);
              }

              var fd = new FormData;
              fd.append ('source_site', site);
              fd.append ('source_page', page);
              return gFetch ('o/create.json', {post: true, formData: fd}).then (function (json) {
                imported[page] = {type: 2, sync_info: {}, dest_id: json.object_id};
                return json.object_id;
              });
            }; // createObject

            var getComments = self.issueComments (name, repo, issue.id, {as: as});

            var parentObjectId;
            return createObject (page).then (function (objectId) {
              parentObjectId = objectId;
              var fd = new FormData;
              fd.append ('source_type', 'api');
              fd.append ('revision_timestamp', issueTimestamp);
              fd.append ('source_timestamp', issueTimestamp);
              fd.append ('source_rev_timestamp', issueTimestamp);
              fd.append ('timestamp', new Date (issue.created_on).valueOf () / 1000);
              fd.append ('edit_index_id', 1);
              fd.append ('index_id', index.index_id);
              fd.append ('title', issue.title);
              fd.append ('body_type', 1); // html
              fd.append ('body_source_type', 2); // markdown (issue.content.markup === "markdown")
              fd.append ('body_source', issue.content.raw || "");
              fd.append ('body', "<markdown-bitbucket>" + issue.content.html + "</markdown-bitbucket>");
              fd.append ('author_bb_username', issue.reporter.username);
              if (issue.assignee) {
                fd.append ('assignee_bb_username', issue.assignee.username);
              }
              fd.append ('todo_bb_priority', issue.priority);
              fd.append ('todo_bb_kind', issue.kind);
              fd.append ('todo_bb_state', issue.state);
              if (issue.state === "resolved" ||
                  issue.state === "invalid" ||
                  issue.state === "duplicate" ||
                  issue.state === "wontfix" ||
                  issue.state === "closed") {
                fd.append ('todo_state', 2); // closed
              } else { // "new" "open" "on hold"
                fd.append ('todo_state', 1); // open
              }
              return gFetch ('o/' + objectId + '/edit.json', {post: true, formData: fd});
            }).then (function () {
              return getComments;
            }).then (function (list) {
              return $promised.forEach (function (comment) {
                var page = site + "/issues/" + issue.id + '#comment-' + comment.id;
                var commentTimestamp = new Date (comment.updated_on || comment.created_on).valueOf () / 1000;

                var current = imported[page];
                if (current && current.type == 2 /* object */) {
                  var currentTimestamp = parseFloat (current.sync_info.timestamp);
                  if (commentTimestamp === currentTimestamp) {
                    return; // nothing to do for this issue comment
                  }
                }

                return createObject (page).then (function (objectId) {
                  var fd = new FormData;
                  fd.append ('parent_object_id', parentObjectId);
                  fd.append ('source_type', 'api');
                  fd.append ('revision_timestamp', commentTimestamp);
                  fd.append ('source_timestamp', commentTimestamp);
                  fd.append ('source_rev_timestamp', commentTimestamp);
                  fd.append ('timestamp', new Date (comment.created_on).valueOf () / 1000);
                  if (comment.content.raw || comment.content.html) {
                    fd.append ('body_type', 1); // html
                    fd.append ('body_source_type', 2); // markdown (issue.content.markup === "markdown")
                    fd.append ('body_source', comment.content.raw || "");
                    fd.append ('body', "<markdown-bitbucket>" + comment.content.html + "</markdown-bitbucket>");
                  } else {
                    fd.append ('body_type', 3); // data
                    fd.append ('body_data', '{}');
                  }
                  fd.append ('author_bb_username', comment.user.username);
                  return gFetch ('o/' + objectId + '/edit.json', {post: true, formData: fd});
                });
              }, list); // forEach
            });
          }, list.reverse ()).then (function () { // forEach
            subAs.end ({ok: true});
            as.stageEnd ('createissueobjects');
          });
        });
      });
    });
  }).then (function () {
    as.end ({ok: true});
  }, function (e) {
    as.end ({error: e});
  });
}; // run

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
