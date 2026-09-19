---
name: release-notes
title: Release Notes
type: Log
description: Changelog and release notes guideline based on Semantic Versioning (SemVer 2.0.0) and Conventional Commits.
tags: [releases, log]
timestamp: 2026-06-18T07:01:04Z
---

# Semantic Versioning (SemVer) Release Notes Guideline

This document defines the standard steps and rules for writing Release Notes for the project, based on [Semantic Versioning 2.0.0 (semver.org)](https://semver.org/).

## 1. Core Rules of SemVer (X.Y.Z)

Every release version must follow the **MAJOR.MINOR.PATCH** format (e.g., `1.4.2`). You must increment the respective element based on the scope of changes:

*   **MAJOR (X):** Increment when you make **incompatible API changes** (Breaking changes). When MAJOR is incremented, MINOR and PATCH must be reset to `0` (e.g., `1.4.2` → `2.0.0`).
*   **MINOR (Y):** Increment when you **add functionality** in a backward-compatible manner. When MINOR is incremented, PATCH must be reset to `0` (e.g., `1.4.2` → `1.5.0`).
*   **PATCH (Z):** Increment when you make backward-compatible **bug fixes** without adding new features or breaking existing APIs (e.g., `1.4.2` → `1.4.3`).

> **Note:** Major version zero (`0.x.x`) is for initial development. Anything MAY change at any time. The public API should not be considered stable.

### 1.1. Additional Labels (Pre-release & Build Metadata)
SemVer allows appending labels to define the lifecycle of a release more precisely:
*   **Pre-release:** Denoted by a hyphen `-` immediately following the PATCH version. These versions have a lower precedence than the associated normal version and are used for drafts or testing phases.
    *   *Examples:* `1.0.0-alpha`, `1.0.0-beta.1`, `1.0.0-rc.1` (Release Candidate).
    *   *Precedence:* `1.0.0-alpha` < `1.0.0-beta` < `1.0.0-rc.1` < `1.0.0`.
*   **Build Metadata:** Denoted by a plus sign `+` at the very end. Used to store commit hashes, build IDs, or timestamps. This metadata **does not** affect version precedence.
    *   *Examples:* `1.0.0-beta.1+exp.sha.5114f85`, `1.2.3+20260601`.

---

## 2. Step-by-Step: Writing Release Notes

When preparing a new release, follow these steps:

### Step 1: Categorization
List all merged tickets/PRs. Group them into clear categories (following Keep a Changelog standards):
*   `Added`: For new features.
*   `Changed`: For changes in existing functionality.
*   `Deprecated`: For once-stable features removed in upcoming releases.
*   `Removed`: For deprecated features removed in this release.
*   `Fixed`: For any bug fixes.
*   `Security`: To invite users to upgrade in case of vulnerabilities.

### Step 2: Determine the Version
*   If there are any breaking changes or removed APIs → **Increment MAJOR**.
*   If there are no breaking changes, but new features (`Added`) or APIs are introduced → **Increment MINOR**.
*   If the list only contains `Fixed` or `Security` updates → **Increment PATCH**.

### Step 3: Draft the Release Note
Use Markdown. Always specify the **[Version] - Release Date (YYYY-MM-DD)**. Write concise and clear descriptions targeting end-users or API integrators. Avoid blindly copy-pasting cryptic git commit messages.

---

## 3. Concrete Examples

Below are 3 scenarios for creating release notes based on project changes.

### Example 1: Patch Release (Bug Fixes)
*Current version is `1.2.3`. The team just fixed a server crash caused by empty payloads and patched a token security vulnerability.*
→ **Decision:** Only bug fixes and security patches, increment PATCH to `1.2.4`.

### Example 2: Minor Release (New Backward-Compatible Features)
*Current version is `1.2.4`. The team added a new CLI subcommand (`ai-skills export`) and support for extra providers without modifying existing options.*
→ **Decision:** New functionality without breaking backward compatibility, increment MINOR to `1.3.0` (reset PATCH to 0).

### Example 3: Major Release (Breaking Changes)
*Current version is `1.3.0`. The team restructured the configuration schema, removed deprecated API endpoints, and replaced the authentication handshake.*
→ **Decision:** Incompatible API and configuration changes, increment MAJOR to `2.0.0` (reset MINOR and PATCH to 0).

---

## 4. Best Practices: Leveraging Conventional Commits
To ensure accurate version bumping and enable **automation (CI/CD)**, the team should adopt the [Conventional Commits](https://www.conventionalcommits.org/) specification:
*   Commits starting with `fix: ...` → Automatically resolve to a **PATCH**.
*   Commits starting with `feat: ...` → Automatically resolve to a **MINOR**.
*   Commits containing `BREAKING CHANGE:` in the footer, or an exclamation mark `!` (e.g., `feat!: ...`) → Automatically resolve to a **MAJOR**.

By doing so, determining the version (Step 2 above) is no longer subjective and can be fully automated using tools (like Semantic-release or Standard-version).
