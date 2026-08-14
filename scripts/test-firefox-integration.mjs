// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import { connect } from "../.tools/web-ext/node_modules/web-ext/lib/firefox/remote.js";

const port = Number(process.argv[2]);
const addonId = process.argv[3] || "{d6c3a4cc-8b7b-4f97-a669-7f41c39a6ac8}";
const probeUrl = process.argv[4];

if (!Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error("Usage: node scripts/test-firefox-integration.mjs <debug-port> [addon-id]");
}

const remote = await connect(port);

async function evaluate(consoleActor, text) {
  let resultId;
  const queued = [];
  let resolveEvent;
  let rejectEvent;
  const eventPromise = new Promise((resolve, reject) => {
    resolveEvent = resolve;
    rejectEvent = reject;
  });
  const timer = setTimeout(() => rejectEvent(new Error("Firefox evaluation timed out.")), 10_000);
  const acceptEvent = (event) => {
    if (event.type !== "evaluationResult") return;
    if (!resultId) queued.push(event);
    else if (event.resultID === resultId) resolveEvent(event);
  };
  const listener = (event) => acceptEvent(event);
  const errorListener = (error) => {
    const prefix = "Unexpected RDP message received: ";
    const message = String(error?.message || "");
    if (!message.startsWith(prefix)) return;
    try {
      acceptEvent(JSON.parse(message.slice(prefix.length)));
    } catch {
      // Ignore unrelated malformed debugger messages.
    }
  };
  remote.client.on("unsolicited-event", listener);
  remote.client.on("error", errorListener);
  try {
    const started = await remote.client.request({
      to: consoleActor,
      type: "evaluateJSAsync",
      text,
    });
    resultId = started.resultID;
    const early = queued.find((event) => event.resultID === resultId);
    if (early) resolveEvent(early);
    const event = await eventPromise;
    if (event.hasException) {
      throw new Error(event.exceptionMessage || "Firefox evaluation failed.");
    }
    return event.result?.value ?? event.result;
  } finally {
    clearTimeout(timer);
    remote.client.removeListener("unsolicited-event", listener);
    remote.client.removeListener("error", errorListener);
  }
}

try {
  const addon = await remote.getInstalledAddon(addonId);
  const listedTabs = await remote.client.request("listTabs");
  if (!listedTabs.tabs?.length) throw new Error("Firefox has no test tab.");

  const popupUrl = addon.manifestURL.replace("manifest.json", "popup.html");
  await remote.client.request({
    to: listedTabs.tabs[0].actor,
    type: "navigateTo",
    url: popupUrl,
    waitForLoad: true,
  });

  const refreshedTabs = await remote.client.request("listTabs");
  const target = await remote.client.request({
    to: refreshedTabs.tabs[0].actor,
    type: "getTarget",
  });

  let state;
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const serialized = await evaluate(
      target.frame.consoleActor,
      `JSON.stringify({
        status: document.querySelector("#backend-status")?.textContent,
        message: document.querySelector("#message")?.textContent,
        version: document.querySelector("#app-version")?.textContent,
        popupUrl: location.href
      })`,
    );
    state = JSON.parse(serialized);
    if (state.status && state.status !== "Checking\u2026") break;
    await new Promise((resolve) => setTimeout(resolve, 500));
  }

  let probe;
  if (probeUrl && state?.status === "Ready") {
    await evaluate(
      target.frame.consoleActor,
      `(() => {
        const input = document.querySelector("#media-url");
        input.value = ${JSON.stringify(probeUrl)};
        input.dispatchEvent(new Event("input", { bubbles: true }));
        document.querySelector("#probe-button").click();
        return true;
      })()`,
    );
    for (let attempt = 0; attempt < 60; attempt += 1) {
      const serialized = await evaluate(
        target.frame.consoleActor,
        `JSON.stringify({
          message: document.querySelector("#message")?.textContent,
          messageClass: document.querySelector("#message")?.className,
          title: document.querySelector("#media-title")?.textContent,
          details: document.querySelector("#media-details")?.textContent,
          probeDisabled: document.querySelector("#probe-button")?.disabled
        })`,
      );
      probe = JSON.parse(serialized);
      if (!probe.probeDisabled) break;
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
  }

  const result = {
    addon: {
      id: addon.id,
      name: addon.name,
      backgroundScriptStatus: addon.backgroundScriptStatus,
      temporarilyInstalled: addon.temporarilyInstalled,
      warnings: addon.warnings,
    },
    popup: state,
    probe,
  };
  console.log(JSON.stringify(result, null, 2));
  if (state?.status !== "Ready") process.exitCode = 1;
  if (probeUrl && probe?.message !== "Media is supported.") process.exitCode = 1;
} finally {
  remote.disconnect();
}
