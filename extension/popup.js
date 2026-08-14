// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

const elements = {
  audioFormat: document.querySelector("#audio-format"),
  audioFormatWrap: document.querySelector("#audio-format-wrap"),
  appVersion: document.querySelector("#app-version"),
  backendStatus: document.querySelector("#backend-status"),
  dismissSponsor: document.querySelector("#dismiss-sponsor"),
  downloadButton: document.querySelector("#download-button"),
  jobMessage: document.querySelector("#job-message"),
  jobPanel: document.querySelector("#job-panel"),
  mediaCard: document.querySelector("#media-card"),
  mediaDetails: document.querySelector("#media-details"),
  mediaTitle: document.querySelector("#media-title"),
  message: document.querySelector("#message"),
  mode: document.querySelector("#mode"),
  openFolderButton: document.querySelector("#open-folder-button"),
  probeButton: document.querySelector("#probe-button"),
  progressBar: document.querySelector("#progress-bar"),
  quality: document.querySelector("#quality"),
  qualityWrap: document.querySelector("#quality-wrap"),
  rights: document.querySelector("#rights-confirmation"),
  sponsorAction: document.querySelector("#sponsor-action"),
  sponsorCard: document.querySelector("#sponsor-card"),
  sponsorLabel: document.querySelector("#sponsor-label"),
  sponsorText: document.querySelector("#sponsor-text"),
  sponsorTitle: document.querySelector("#sponsor-title"),
  thumbnail: document.querySelector("#thumbnail"),
  url: document.querySelector("#media-url"),
};

let backendOnline = false;
let activeJobTimer = null;

function setMessage(text = "", type = "") {
  elements.message.textContent = text;
  elements.message.className = `message ${type}`.trim();
}

function refreshDownloadState() {
  elements.downloadButton.disabled = !(backendOnline && elements.rights.checked && elements.url.value.trim());
}

function formatDuration(seconds) {
  if (!Number.isFinite(seconds)) return "Duration unknown";
  const minutes = Math.floor(seconds / 60);
  const remainder = Math.floor(seconds % 60).toString().padStart(2, "0");
  return `${minutes}:${remainder}`;
}

async function helper(action, payload = {}) {
  const response = await chrome.runtime.sendMessage({
    target: "media-bridge-helper",
    action,
    payload,
  });
  if (!response?.ok) throw new Error(response?.error || "Media Bridge Helper is unavailable.");
  return response.data;
}

async function checkBackend() {
  try {
    const health = await helper("health");
    backendOnline = Boolean(health.ffmpeg && health.javascript_runtime);
    elements.backendStatus.textContent = !health.ffmpeg
      ? "No FFmpeg"
      : !health.javascript_runtime
        ? "Update Helper"
        : "Ready";
    elements.backendStatus.className = backendOnline ? "status status-online" : "status status-offline";
    elements.openFolderButton.classList.remove("hidden");
    if (!health.ffmpeg) {
      setMessage("Install FFmpeg for merging video and converting audio.");
    } else if (!health.javascript_runtime) {
      setMessage("Update Media Bridge Helper for current YouTube support.", "error");
    }
  } catch {
    backendOnline = false;
    elements.backendStatus.textContent = "Offline";
    elements.backendStatus.className = "status status-offline";
    elements.openFolderButton.classList.add("hidden");
    setMessage("Install or update Media Bridge Helper, then restart the browser.", "error");
  }
  refreshDownloadState();
}

async function openDownloadsFolder() {
  elements.openFolderButton.disabled = true;
  try {
    await helper("open_downloads");
    setMessage("Downloads folder opened.", "success");
  } catch (error) {
    setMessage(error.message, "error");
  } finally {
    elements.openFolderButton.disabled = false;
  }
}

async function inspectMedia() {
  const url = elements.url.value.trim();
  if (!url) return;
  setMessage("Inspecting media…");
  elements.probeButton.disabled = true;
  try {
    const media = await helper("probe", { url });
    elements.mediaTitle.textContent = media.title || "Untitled media";
    elements.mediaDetails.textContent = [media.extractor, formatDuration(media.duration)].filter(Boolean).join(" · ");
    elements.mediaCard.classList.remove("hidden");
    if (media.thumbnail) {
      elements.thumbnail.src = media.thumbnail;
      elements.thumbnail.classList.remove("hidden");
    } else {
      elements.thumbnail.classList.add("hidden");
    }
    setMessage("Media is supported.", "success");
  } catch (error) {
    elements.mediaCard.classList.add("hidden");
    setMessage(error.message, "error");
  } finally {
    elements.probeButton.disabled = false;
  }
}

function renderJob(job) {
  const percent = Number.isFinite(job.progress) ? Math.max(0, Math.min(100, job.progress)) : 0;
  elements.jobPanel.classList.remove("hidden");
  elements.progressBar.style.width = `${percent}%`;
  elements.jobMessage.textContent = job.message || job.status;
  if (["queued", "starting", "downloading"].includes(job.status)) setMessage("");
}

async function pollJob(jobId) {
  clearTimeout(activeJobTimer);
  try {
    const job = await helper("job", { id: jobId });
    renderJob(job);
    if (job.status === "finished") {
      elements.downloadButton.disabled = false;
      setMessage(`Saved to ${job.output_dir}`, "success");
      return;
    }
    if (job.status === "failed") {
      elements.downloadButton.disabled = false;
      setMessage(job.error || "Download failed.", "error");
      return;
    }
    activeJobTimer = setTimeout(() => pollJob(jobId), 900);
  } catch (error) {
    elements.downloadButton.disabled = false;
    setMessage(error.message, "error");
  }
}

async function startDownload() {
  if (!elements.rights.checked) return;
  elements.downloadButton.disabled = true;
  setMessage("Creating download job…");
  try {
    const payload = {
      url: elements.url.value.trim(),
      mode: elements.mode.value,
      max_height: Number(elements.quality.value),
      audio_format: elements.audioFormat.value,
    };
    const job = await helper("download", payload);
    setMessage("");
    renderJob(job);
    await pollJob(job.id);
  } catch (error) {
    elements.downloadButton.disabled = false;
    setMessage(error.message, "error");
  }
}

function updateMode() {
  const audio = elements.mode.value === "audio";
  elements.audioFormatWrap.classList.toggle("hidden", !audio);
  elements.qualityWrap.classList.toggle("hidden", audio);
  chrome.storage.local.set({ mode: elements.mode.value });
}

async function initializeSponsor() {
  const sponsor = globalThis.MEDIA_BRIDGE_CONFIG?.sponsor;
  if (!sponsor?.enabled) return;
  const saved = await chrome.storage.local.get(["sponsorDismissedUntil"]);
  if (Number(saved.sponsorDismissedUntil) > Date.now()) return;
  elements.sponsorLabel.textContent = sponsor.label || "SPONSOR";
  elements.sponsorTitle.textContent = sponsor.title || "";
  elements.sponsorText.textContent = sponsor.text || "";
  if (sponsor.cta && sponsor.url) {
    elements.sponsorAction.textContent = sponsor.cta;
    elements.sponsorAction.classList.remove("hidden");
    elements.sponsorAction.addEventListener("click", () => chrome.tabs.create({ url: sponsor.url }));
  }
  elements.sponsorCard.classList.remove("hidden");
}

async function initialize() {
  elements.appVersion.textContent = `v${chrome.runtime.getManifest().version}`;
  const saved = await chrome.storage.local.get(["mode", "quality", "audioFormat"]);
  if (saved.mode) elements.mode.value = saved.mode;
  if (saved.quality) elements.quality.value = saved.quality;
  if (saved.audioFormat) elements.audioFormat.value = saved.audioFormat;
  updateMode();

  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (tab?.url?.startsWith("http")) elements.url.value = tab.url;
  refreshDownloadState();
  await initializeSponsor();
  await checkBackend();
}

elements.mode.addEventListener("change", updateMode);
elements.openFolderButton.addEventListener("click", openDownloadsFolder);
elements.quality.addEventListener("change", () => chrome.storage.local.set({ quality: elements.quality.value }));
elements.audioFormat.addEventListener("change", () => chrome.storage.local.set({ audioFormat: elements.audioFormat.value }));
elements.rights.addEventListener("change", refreshDownloadState);
elements.url.addEventListener("input", refreshDownloadState);
elements.probeButton.addEventListener("click", inspectMedia);
elements.downloadButton.addEventListener("click", startDownload);
elements.dismissSponsor.addEventListener("click", async () => {
  const dismissedUntil = Date.now() + 24 * 60 * 60 * 1000;
  await chrome.storage.local.set({ sponsorDismissedUntil: dismissedUntil });
  elements.sponsorCard.classList.add("hidden");
});

initialize().catch((error) => setMessage(error.message, "error"));
