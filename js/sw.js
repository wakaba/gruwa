addEventListener ('push', (ev) => {

  // XXX use push payload data
  ev.waitUntil (fetch ('/my/calls.json?limit=1', {
    credentials: 'same-origin',
    referrerPolicy: 'same-origin',
  }).then ((res) => {
    if (res.status !== 200) throw res;
    return res.json ();
  }).then ((json) => {
    var _ = json.items[0];

    // XXX
    var text = 'グループの記事で呼ばれました';
    var url = '/g/' + _.group_id + '/o/' + _.object_id + '/';
    var iconURL = '/g/' + _.group_id + '/icon';

    return self.registration.showNotification ('Gruwa', {
      body: text,
      icon: iconURL,
      //tag:
      //badge:
      data: {url: url},
    });
  }));
});

addEventListener ('notificationclick', (ev) => {
  ev.notification.close ();
  var url = ev.notification.data.url || '/dashboard/calls';
  ev.waitUntil (clients.openWindow (url));
});

/*

License:

Copyright 2019 Wakaba <wakaba@suikawiki.org>.

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
