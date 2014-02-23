var selectorMap = {
  "playPause": "button[data-id=play-pause]",
  "previous": "button[data-id=rewind]",
  "next": "button[data-id=forward]"
};

var eventPage = chrome.runtime.connect();

eventPage.onDisconnect.addListener(function() {
  console.warn("Media button relay event page disconnected.");
});

eventPage.onMessage.addListener(function(message) {
  console.log("Button press: " + message.button);
  var selector = selectorMap[message.button];
  var element = document.querySelector(selector);
  var clickEvent = new MouseEvent("click", {
    "view": window, "bubbles": true, "cancelable": true
  });
  element.dispatchEvent(clickEvent);
});
