---
name: chrome-extension
description: "Chrome Extension development using Manifest V3: service workers, content scripts, popup/options UI, and WebExtension APIs. Use when building, modifying, or debugging browser extensions."
---

# Chrome Extension Development (Manifest V3)

Production best practices for developing secure, performant browser extensions on Chrome Manifest V3.

## Core Rules

1. **Manifest V3 Conformance**:
   - Strictly use `"manifest_version": 3`.
   - Background scripts MUST run as ephemeral service workers (`"background": { "service_worker": "background.js", "type": "module" }`).
   - Never store global in-memory state in the service worker; persist state to `chrome.storage.local` or `chrome.storage.session` as service workers terminate when idle.
2. **Content Script Isolation & Messaging**:
   - Use `chrome.runtime.sendMessage` and `chrome.runtime.onMessage` for cross-context communication between content scripts, service workers, and popup pages.
   - Sanitize all data received across messaging boundaries.
3. **Permissions & Security**:
   - Request minimum necessary permissions (`"permissions"`, `"optional_permissions"`, `"host_permissions"`).
   - Never inject arbitrary unsanitized HTML into web pages (`innerHTML` is forbidden; use `textContent` or trusted DOM nodes).
   - Content Security Policy (CSP): Remotely hosted code is strictly forbidden in Manifest V3; bundle all dependencies locally.
4. **Modern Tooling & TypeScript**:
   - Build using modern bundlers (Vite / WXT) with TypeScript for typed `chrome.*` API declarations.
