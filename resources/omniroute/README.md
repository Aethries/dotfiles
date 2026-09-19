# OmniRoute Local AI Gateway Configuration

This directory manages the configuration templates and bundles for **OmniRoute**, the local multi-provider AI gateway.

---

## Architecture Overview

OmniRoute coexists with **9Router** in a dual-gateway architecture:

| Gateway | Port | Role / Focus |
| :--- | :---: | :--- |
| **9Router** | `20128` | Google Antigravity & Multi-OAuth pool, MITM interception, web dashboard |
| **OmniRoute** | `20129` | OpenAI-compatible unified proxy, multi-provider routing, custom models, skills |

---

## Key Files & Structure

* `resources/ai/gateway.env`: Single source of truth for ports (`20128`, `20129`), loopback host (`127.0.0.1`), and pinned versions.
* `resources/systemd/user/omniroute.service`: Declarative systemd user service binding OmniRoute strictly to `127.0.0.1:20129`.
* `scripts/init-omniroute.sh`: Automated installer, pinned package manager (`omniroute@3.8.50`), loopback port configuration, key desync protection, and service bootstrapper.
* `scripts/sync-omniroute.sh`: Synchronizes authoritative OmniRoute state (SQLite database, providers, accounts, and `.env`) via encrypted `vault.sh`.
* `resources/omniroute/.gitignore`: Excludes `bundle.json`, `*.json`, `*.sqlite*`, and `*.env` to guarantee sensitive credentials are never committed.
* `tests/ai/omniroute_test.sh`: Dynamic integration, security, and port isolation test suite wired directly to `scripts/check.sh`.
* `~/.omniroute/`:
  * `.env`: Contains `PORT=20129`, `HOST=127.0.0.1`, `OMNIROUTE_SERVER_HOST=127.0.0.1`, `API_HOST=127.0.0.1`, `LIVE_WS_HOST=127.0.0.1`, and `STORAGE_ENCRYPTION_KEY`.
  * `storage.sqlite`: Local encrypted database containing all GUI customizations, accounts, and provider configurations (authoritative store synced safely via `vault backup`).

---

## State Synchronization & Single Source of Truth

OmniRoute state follows a strict security architecture:
1. **Authoritative State (`vault.sh`)**: All credentials, provider accounts, encrypted SQLite records, and master encryption keys live in `~/.omniroute/` and are encrypted into `secrets.vault` using `vault backup`. During backup, the system pauses the service and checkpoints the SQLite WAL to ensure atomic, non-corrupted snapshots.
2. **Synchronize CLI (`sync-omniroute`)**: `sync-omniroute export` and `sync-omniroute import` invoke `vault.sh` to safely backup and restore complete configuration state without plaintext bundle leakage.

---

## Daily Workflow & CLI Commands

### 1. Initialize or Reinstall
```bash
init-omniroute
# Or if resetting an orphaned database with a new encryption key:
init-omniroute --force
```
This guarantees Node.js LTS via `fnm`, pins `omniroute@3.8.50`, configures loopback bindings, protects against key desync, and starts the systemd service.

### 2. Service Management
```bash
omni status     # or systemctl --user status omniroute
omni restart    # or systemctl --user restart omniroute
omni stop       # or systemctl --user stop omniroute
omni logs       # or journalctl --user -u omniroute -f
```

### 3. Sync Settings & Providers
```bash
# Sync entire database, provider accounts, and tokens into encrypted vault (authoritative)
sync-omniroute export   # or: vault backup

# Restore database and encryption keys on a fresh system
sync-omniroute import   # or: vault restore
```

### 4. Diagnostics & Testing
```bash
doctor                    # Verifies service status, 127.0.0.1 loopback binding, and coexistence
dotfiles-check            # Runs full repo verification including tests/ai/omniroute_test.sh
```
