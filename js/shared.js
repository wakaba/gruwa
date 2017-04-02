/* This script is executed as a classic shared worker script. */

var receivers = {};

onconnect = function (ev) {
  ev.ports[0].onmessage = function (ev) {
    if (ev.data.type === 'createReceiver') {
      var id = Math.random ();
      var mc = new MessageChannel;
      receivers[id] = mc.port1;
      ev.ports[0].postMessage ({receiverId: id}, [mc.port2]);
      mc.port1.onmessage = function (ev) {
        if (ev.data.type === 'close') {
          delete receivers[id];
          this.close ();
        }
      };
      this.close ();
    } else if (ev.data.type === 'provideSourceData') {
      var receiver = receivers[ev.data.receiverId];
      if (receiver) {
        receiver.postMessage ({type: 'provideSourceData',
                               data: ev.data.data});
      } else {
        console.log ("Receiver " + ev.data.receiverId + " not found");
      }
      this.close ();
    } else if (ev.data.type === 'provideSourcePort') {
      var receiver = receivers[ev.data.receiverId];
      if (receiver) {
        receiver.postMessage ({type: 'provideSourcePort',
                               data: ev.data.data}, [ev.ports[0]]);
      } else {
        console.log ("Receiver " + ev.data.receiverId + " not found");
      }
      this.close ();
    } else {
      console.log ('Bad message type ' + ev.data.type);
      this.close ();
    }
  }; // onmessage
}; // onconnect

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
