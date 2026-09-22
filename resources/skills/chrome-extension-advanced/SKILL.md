---
name: chrome-extension-advanced
description: "Advanced Chrome Extension MV3 engineering: declarativeNetRequest rulesets, offscreen documents, side panel APIs, WebSocket persistence in service workers, and cross-context messaging. Use when building complex Manifest V3 browser extensions."
---

# Advanced Chrome Extension MV3 Engineering

Production engineering standards for complex browser extensions utilizing the full capabilities of Manifest V3.

## Core Rules

1. **Service Worker Lifecycle & Persistence**:
   - Manifest V3 background service workers are ephemeral and terminate after ~30 seconds of inactivity.
   - Never store in-memory state inside global service worker variables. Persist state in `chrome.storage.local` or `chrome.storage.session`.
   - For continuous tasks (audio playback, DOM parsing, long-lived WebSockets), spin up an Offscreen Document (`chrome.offscreen.createDocument`).

2. **Network Modification (`declarativeNetRequest`)**:
   - Replace deprecated blocking `webRequest` APIs with declarative rulesets defined in `manifest.json`.
   - Use dynamic rules (`chrome.declarativeNetRequest.updateDynamicRules`) only for user-customizable URL filters.
   - Scope regex filters tightly to minimize CPU overhead on the browser process.

3. **Multi-Context Messaging Architecture**:
   - Establish strongly-typed message envelopes (`{ action: string, payload: unknown }`) between popup, options, sidepanel, content scripts, and service workers.
   - Use long-lived connections (`chrome.runtime.connect` / `Port`) for streaming updates or chat-like interactions.
   - Handle connection disconnects gracefully (`port.onDisconnect.addListener`).

4. **Security & Content Scripts**:
   - Avoid injecting inline code; use external script bundles declared in `manifest.json`.
   - Sanitize all DOM insertions in content scripts with DOMPurify to guard against XSS.
   - Restrict `host_permissions` to the exact domains required; avoid broad `<all_urls>` whenever possible.
