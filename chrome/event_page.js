var clients = [];
var nativePort = null;

chrome.runtime.onConnect.addListener(function(client) {
  console.log("Client connected from " + client.sender.url + ".");
  clients.push(client);
  client.onDisconnect.addListener(function() {
    var index = clients.indexOf(client);
    if (index < 0) {
      console.error("Client tried to disconnect, but was not connected.");
      return;
    }
    console.log("Client disconnected from " + client.sender.url + ".");
    clients.splice(index, 1);

    if (nativePort && clients.length == 0) {
      console.log("Last client disconnected from event page.");
      nativePort.disconnect();
      nativePort = null;
    }
  });

  if (!nativePort) {
    nativePort = chrome.runtime.connectNative("com.jeremyroman.mediabuttonrelay");
    nativePort.onDisconnect.addListener(function() {
      console.warn("Native port disconnected.");
      nativePort = null;
    });

    nativePort.onMessage.addListener(function(message) {
      console.log("Button press: " + message.button);
      if (clients.length == 0) {
        console.error("No clients are connected. Native port should be disconnected.");
        return;
      }

      // Only the first client gets the message.
      clients[0].postMessage(message);
    });
  }
});
