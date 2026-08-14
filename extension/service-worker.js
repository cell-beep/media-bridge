// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

const NATIVE_HOST = "com.media_bridge.helper";
const REQUEST_TIMEOUT_MS = 30_000;

let nativePort = null;
let requestSequence = 0;
const pendingRequests = new Map();

function rejectPending(error) {
  for (const { reject, timer } of pendingRequests.values()) {
    clearTimeout(timer);
    reject(error);
  }
  pendingRequests.clear();
}

function connectHelper() {
  if (nativePort) return nativePort;
  const port = chrome.runtime.connectNative(NATIVE_HOST);
  nativePort = port;

  port.onMessage.addListener((message) => {
    const pending = pendingRequests.get(message.requestId);
    if (!pending) return;
    clearTimeout(pending.timer);
    pendingRequests.delete(message.requestId);
    if (message.ok) pending.resolve(message.data);
    else pending.reject(new Error(message.error || "Media Bridge Helper returned an error."));
  });

  port.onDisconnect.addListener(() => {
    const detail = chrome.runtime.lastError?.message || "Media Bridge Helper is not installed.";
    nativePort = null;
    rejectPending(new Error(detail));
  });
  return port;
}

function callHelper(action, payload = {}) {
  return new Promise((resolve, reject) => {
    const requestId = `${Date.now()}-${++requestSequence}`;
    const timer = setTimeout(() => {
      pendingRequests.delete(requestId);
      reject(new Error("Media Bridge Helper did not respond in time."));
    }, REQUEST_TIMEOUT_MS);
    pendingRequests.set(requestId, { resolve, reject, timer });
    try {
      connectHelper().postMessage({ requestId, action, payload });
    } catch (error) {
      clearTimeout(timer);
      pendingRequests.delete(requestId);
      reject(error);
    }
  });
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message?.target !== "media-bridge-helper") return false;
  callHelper(message.action, message.payload)
    .then((data) => sendResponse({ ok: true, data }))
    .catch((error) => sendResponse({ ok: false, error: error.message }));
  return true;
});
